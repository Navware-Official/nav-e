//! Message preparation: build serialized proto messages from JSON or parameters.
//! Used by nav_core and FFI to prepare BLE payloads (route, map region, control, etc.).

use anyhow::{bail, Context, Result};
use nav_ir::{Route, WaypointKind};
use prost::Message;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::proto;
use crate::{chunk_message, create_header, FrameAssembler};

/// Build a RouteBlob from a Nav-IR Route. Uses first segment's geometry and flattens waypoints.
/// Returns an error if the route fails validation.
pub fn nav_ir_route_to_route_blob(
    route: &Route,
    header: proto::Header,
) -> Result<proto::RouteBlob> {
    route
        .validate()
        .map_err(|e| anyhow::anyhow!("Nav-IR validation failed: {}", e))?;
    let route_id_bytes = route.id.0.as_bytes().to_vec();

    let mut index = 0u32;
    let proto_waypoints: Vec<proto::Waypoint> = route
        .segments
        .iter()
        .flat_map(|seg| &seg.waypoints)
        .map(|wp| {
            let default_name = match &wp.kind {
                WaypointKind::Start => "Start".to_string(),
                WaypointKind::Stop => "Stop".to_string(),
                WaypointKind::Via => format!("Via {}", index),
                _ => format!("Waypoint {}", index),
            };
            let name = wp.name.as_deref().unwrap_or(&default_name).to_string();
            index += 1;
            proto::Waypoint {
                lat: wp.coordinate.latitude,
                lon: wp.coordinate.longitude,
                name,
                index: index - 1,
            }
        })
        .collect();

    let encoded_polyline = route
        .segments
        .first()
        .map(|seg| seg.geometry.polyline.0.clone())
        .unwrap_or_default();

    let mut hasher = Sha256::new();
    hasher.update(encoded_polyline.as_bytes());
    let checksum = hasher.finalize().to_vec();

    let metadata = Some(proto::Metadata {
        zoom_hint: 0,
        preferred_zoom: 0,
        total_points: 0,
        route_name: route.metadata.name.clone(),
        created_at_ms: route.metadata.created_at.timestamp_millis() as u64,
    });

    let total_distance = route
        .metadata
        .total_distance_m
        .map(|m| m as u32)
        .unwrap_or(0);
    let total_duration = route
        .metadata
        .estimated_duration_s
        .map(|s| s as u32)
        .unwrap_or(0);
    let legs: Vec<proto::RouteLeg> = if route.segments.is_empty() {
        vec![]
    } else if route.segments.len() == 1 {
        vec![proto::RouteLeg {
            distance_m: total_distance,
            duration_s: total_duration,
            summary: String::new(),
            steps: vec![],
        }]
    } else {
        route
            .segments
            .iter()
            .map(|_| proto::RouteLeg {
                distance_m: total_distance / route.segments.len() as u32,
                duration_s: total_duration / route.segments.len() as u32,
                summary: String::new(),
                steps: vec![],
            })
            .collect()
    };

    Ok(proto::RouteBlob {
        header: Some(header),
        route_id: route_id_bytes,
        waypoints: proto_waypoints,
        legs,
        polyline_data: Some(proto::route_blob::PolylineData::EncodedPolyline(
            encoded_polyline,
        )),
        metadata,
        compressed: false,
        checksum,
        signature: None,
    })
}

/// Prepare a route message for sending to a device.
/// Parses route JSON (waypoints, polyline, distance_m, duration_s) into Nav-IR, then RouteBlob, then serialized bytes.
pub fn prepare_route_message(route_json: String) -> Result<Vec<u8>> {
    let route_value: serde_json::Value =
        serde_json::from_str(&route_json).context("Failed to parse route JSON")?;

    let waypoints_arr = route_value["waypoints"]
        .as_array()
        .ok_or_else(|| anyhow::anyhow!("Route missing waypoints array"))?;
    let waypoints: Vec<(f64, f64)> = waypoints_arr
        .iter()
        .filter_map(|wp| {
            let arr = wp.as_array()?;
            let lat = arr.first()?.as_f64()?;
            let lon = arr.get(1)?.as_f64()?;
            Some((lat, lon))
        })
        .collect();

    let encoded_polyline = if let Some(arr) = route_value["polyline"].as_array() {
        let coords: Vec<_> = arr
            .iter()
            .filter_map(|v| {
                let pair = v.as_array()?;
                let lat = pair.first()?.as_f64()?;
                let lon = pair.get(1)?.as_f64()?;
                Some((lat, lon))
            })
            .collect();
        let coords_geo: Vec<geo_types::Coord<f64>> = coords
            .iter()
            .map(|(lat, lon)| geo_types::Coord { x: *lon, y: *lat })
            .collect();
        polyline::encode_coordinates(coords_geo, 5).unwrap_or_default()
    } else {
        route_value["polyline"].as_str().unwrap_or("").to_string()
    };

    let distance_m = route_value["distance_m"].as_f64().unwrap_or(0.0);
    let duration_s = route_value["duration_s"].as_f64().unwrap_or(0.0) as u64;

    let nav_ir_route = nav_ir::normalize_custom(
        &waypoints,
        &encoded_polyline,
        Some(distance_m),
        Some(duration_s),
    )
    .map_err(|e| anyhow::anyhow!("Route normalization failed: {}", e))?;

    let header = create_header(1);
    let route_blob = nav_ir_route_to_route_blob(&nav_ir_route, header)?;

    let message = proto::Message {
        payload: Some(proto::message::Payload::RouteBlob(route_blob)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Failed to encode protobuf message")?;
    Ok(buf)
}

/// Chunk a protobuf message into BLE frames. Returns a vector of serialized frame bytes.
pub fn chunk_message_for_ble(
    message_bytes: Vec<u8>,
    route_id: String,
    mtu: u32,
) -> Result<Vec<Vec<u8>>> {
    let message =
        proto::Message::decode(&message_bytes[..]).context("Failed to decode protobuf message")?;
    let route_uuid = Uuid::parse_str(&route_id).context("Invalid route UUID")?;
    let frames = chunk_message(&message, &route_uuid, 1, mtu as usize)
        .map_err(|e| anyhow::anyhow!("{}", e))?;
    let mut frame_bytes = Vec::new();
    for frame in frames {
        let mut buf = Vec::new();
        frame.encode(&mut buf).context("Failed to encode frame")?;
        frame_bytes.push(buf);
    }
    Ok(frame_bytes)
}

/// Build a MapRegionMetadata message and return serialized bytes.
pub fn prepare_map_region_metadata_message(
    region_json: String,
    total_tiles: u32,
) -> Result<Vec<u8>> {
    let region: serde_json::Value =
        serde_json::from_str(&region_json).context("Parse region JSON")?;
    let region_id = region["id"].as_str().unwrap_or("").to_string();
    let name = region["name"].as_str().unwrap_or("").to_string();
    let north = region["north"].as_f64().unwrap_or(0.0);
    let south = region["south"].as_f64().unwrap_or(0.0);
    let east = region["east"].as_f64().unwrap_or(0.0);
    let west = region["west"].as_f64().unwrap_or(0.0);
    let min_zoom = region["min_zoom"].as_i64().unwrap_or(0) as u32;
    let max_zoom = region["max_zoom"].as_i64().unwrap_or(0) as u32;

    let metadata = proto::MapRegionMetadata {
        region_id,
        name,
        north,
        south,
        east,
        west,
        min_zoom,
        max_zoom,
        total_tiles,
    };

    let message = proto::Message {
        payload: Some(proto::message::Payload::MapRegionMetadata(metadata)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode MapRegionMetadata message")?;
    Ok(buf)
}

/// Build a MapStyle message and return serialized bytes.
pub fn prepare_map_style_message(map_source_id: String) -> Result<Vec<u8>> {
    let map_style = proto::MapStyle { map_source_id };
    let message = proto::Message {
        payload: Some(proto::message::Payload::MapStyle(map_style)),
    };
    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode MapStyle message")?;
    Ok(buf)
}

/// Build a TileChunk message and return serialized bytes.
pub fn prepare_tile_chunk_message(
    region_id: String,
    z: i32,
    x: i32,
    y: i32,
    data: Vec<u8>,
) -> Result<Vec<u8>> {
    let chunk = proto::TileChunk {
        region_id,
        z,
        x,
        y,
        data,
    };
    let message = proto::Message {
        payload: Some(proto::message::Payload::TileChunk(chunk)),
    };
    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode TileChunk message")?;
    Ok(buf)
}

/// Reassemble BLE frames into a complete message and return serialized message bytes.
pub fn reassemble_frames(frame_bytes: Vec<Vec<u8>>) -> Result<Vec<u8>> {
    let mut reassembler = FrameAssembler::new();
    for bytes in frame_bytes {
        let frame = proto::Frame::decode(&bytes[..]).context("Failed to decode frame")?;
        reassembler
            .add_frame(frame)
            .map_err(|e| anyhow::anyhow!("{}", e))?;
    }
    if !reassembler.is_complete() {
        bail!(
            "Not all frames received. Missing: {:?}",
            reassembler.missing_sequences()
        );
    }
    let message_bytes = reassembler
        .assemble()
        .map_err(|e| anyhow::anyhow!("{}", e))?;
    let message = proto::Message::decode(&message_bytes[..])
        .context("Failed to decode reassembled message")?;
    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Failed to encode reassembled message")?;
    Ok(buf)
}

/// Create a control command message (ACK, NACK, START_NAV, etc.) and return serialized bytes.
pub fn create_control_message(
    route_id: String,
    command_type: String,
    status_code: u32,
    message: String,
) -> Result<Vec<u8>> {
    let control_type = match command_type.to_uppercase().as_str() {
        "ACK" => proto::ControlType::Ack,
        "NACK" => proto::ControlType::Nack,
        "START_NAV" => proto::ControlType::StartNav,
        "STOP_NAV" => proto::ControlType::StopNav,
        "PAUSE_NAV" => proto::ControlType::PauseNav,
        "RESUME_NAV" => proto::ControlType::ResumeNav,
        "HEARTBEAT" => proto::ControlType::Heartbeat,
        _ => bail!("Invalid control type: {}", command_type),
    };

    let header = create_header(1);
    let route_uuid =
        Uuid::parse_str(&route_id).context("Invalid route UUID for control message")?;
    let control = proto::Control {
        header: Some(header),
        r#type: control_type as i32,
        route_id: route_uuid.as_bytes().to_vec(),
        status_code,
        message_text: message,
        seq_no: 0,
    };

    let msg = proto::Message {
        payload: Some(proto::message::Payload::Control(control)),
    };
    let mut buf = Vec::new();
    msg.encode(&mut buf)
        .context("Failed to encode control message")?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use nav_ir::{
        BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, RouteGeometry,
        RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentIntent, Waypoint,
        WaypointId, WaypointKind,
    };

    #[test]
    fn nav_ir_to_route_blob_roundtrip() {
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: nav_ir::RouteId::new(),
            metadata: RouteMetadata {
                name: "Test".into(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(1000.0),
                estimated_duration_s: Some(120),
                tags: vec![],
                source: None,
            },
            segments: vec![RouteSegment {
                id: nav_ir::SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline("_p~iF~ps|U".into()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 40.0,
                        min_lon: -74.0,
                        max_lat: 41.0,
                        max_lon: -73.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(40.71, -74.01),
                        kind: WaypointKind::Start,
                        radius_m: None,
                        name: None,
                        description: None,
                        role: None,
                        category: None,
                        geometry_ref: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(40.76, -73.99),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                        name: None,
                        description: None,
                        role: None,
                        category: None,
                        geometry_ref: None,
                    },
                ],
                legs: vec![],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };

        let header = create_header(1);
        let blob = nav_ir_route_to_route_blob(&route, header).unwrap();

        assert_eq!(blob.route_id.len(), 16);
        assert_eq!(blob.waypoints.len(), 2);
        assert_eq!(blob.waypoints[0].lat, 40.71);
        assert_eq!(blob.waypoints[0].lon, -74.01);
        assert_eq!(blob.waypoints[1].lat, 40.76);
        assert_eq!(blob.waypoints[1].lon, -73.99);
        assert!(matches!(
            &blob.polyline_data,
            Some(proto::route_blob::PolylineData::EncodedPolyline(s)) if s == "_p~iF~ps|U"
        ));
        assert!(!blob.checksum.is_empty());
    }
}
