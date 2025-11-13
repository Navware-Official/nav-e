mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

mod geocode;

pub use geocode::{FrbGeocodingResult};

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

// Return raw JSON string (existing helper)
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> anyhow::Result<String> {
    // Delegate to async runtime
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async move { geocode::search_raw_json(&query, limit).await })
}

// Typed result: FRB will generate typed Dart classes for FrbGeocodingResult
#[frb]
pub fn geocode_search_typed(
    query: String,
    limit: Option<u32>,
) -> anyhow::Result<Vec<FrbGeocodingResult>> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async move { geocode::search_typed(&query, limit).await })
}

// ---------------------------------------------------------------------------
// Hardcoded route stub for development / simulation
// - Returns a CBOR-encoded `FrbRoute` blob so the Dart side can decode and
//   display a polyline/summary without a real routing backend.
// - Uses `serde_cbor` for compact binary encoding.
// ---------------------------------------------------------------------------

#[derive(Debug, Serialize, Deserialize)]
pub struct FrbRoute {
    pub id: String,
    /// Encoded polyline (polyline6 or polyline5 string). For the stub we use
    /// a precomputed encoded polyline string.
    pub polyline: String,
    pub distance_m: f64,
    pub duration_s: f64,
    /// Human-friendly route name
    pub name: String,
    /// A small preview of waypoints as [lat, lon] pairs for quick display or
    /// testing.
    pub waypoints: Vec<[f64; 2]>,
}

/// Compute a route between two coordinates and return a CBOR byte buffer
/// containing an `FrbRoute`. This is a development stub that returns a
/// hardcoded route blob so the Flutter UI can be exercised without a real
/// routing engine.
#[frb]
pub fn nav_compute_route(
    _start_lat: f64,
    _start_lon: f64,
    _end_lat: f64,
    _end_lon: f64,
    _options: Option<String>,
) -> anyhow::Result<String> {
    // Try to fetch a route from a public routing API (OSRM) as a fallback
    // when a native routing engine isn't available. If the network call
    // fails we fall back to the local hardcoded stub so the UI still works.
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    let res = rt.block_on(async move {
        // Build OSRM request: note OSRM expects lon,lat pairs
        let start = format!("{},{}", _start_lon, _start_lat);
        let end = format!("{},{}", _end_lon, _end_lat);
        let url = format!("https://router.project-osrm.org/route/v1/driving/{};{}?overview=full&geometries=geojson&steps=false&alternatives=false", start, end);

        match reqwest::get(&url).await {
            Ok(resp) => match resp.json::<serde_json::Value>().await {
                Ok(json) => {
                    // Parse OSRM response and convert to FrbRoute shape
                    if json.get("code").and_then(|v| v.as_str()) != Some("Ok") {
                        return Err(anyhow::anyhow!("OSRM returned error: {:?}", json));
                    }

                    let routes = json.get("routes").and_then(|r| r.as_array()).cloned().unwrap_or_default();
                    if routes.is_empty() {
                        return Err(anyhow::anyhow!("No routes from OSRM"));
                    }

                    let first = &routes[0];
                    let distance = first.get("distance").and_then(|d| d.as_f64()).unwrap_or(0.0);
                    let duration = first.get("duration").and_then(|d| d.as_f64()).unwrap_or(0.0);

                    // geometry.coordinates is an array of [lon, lat]
                    let mut waypoints: Vec<[f64; 2]> = Vec::new();
                    if let Some(geometry) = first.get("geometry") {
                        if let Some(coords) = geometry.get("coordinates").and_then(|c| c.as_array()) {
                            for c in coords {
                                if let Some(arr) = c.as_array() {
                                    if arr.len() >= 2 {
                                        if let (Some(lon), Some(lat)) = (arr[0].as_f64(), arr[1].as_f64()) {
                                            waypoints.push([lat, lon]);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    let route = FrbRoute {
                        id: format!("osrm-{}", chrono::Utc::now().timestamp_millis()),
                        polyline: String::new(),
                        distance_m: distance,
                        duration_s: duration,
                        name: "OSRM route".to_string(),
                        waypoints,
                    };

                    let s = serde_json::to_string(&route)?;
                    Ok(s)
                }
                Err(e) => Err(anyhow::anyhow!("Failed to parse OSRM JSON: {}", e)),
            },
            Err(e) => Err(anyhow::anyhow!("OSRM request failed: {}", e)),
        }
    });

    match res {
        Ok(s) => Ok(s),
        Err(err) => {
            // Log the error and fall back to the local stub route so UI remains usable.
            eprintln!("nav_compute_route: OSRM fallback failed: {:?}", err);

            let route = FrbRoute {
                id: "stub-1".to_string(),
                polyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@".to_string(),
                distance_m: 1234.5,
                duration_s: 456.0,
                name: "Sample route (stub)".to_string(),
                waypoints: vec![
                    [52.5206, 13.3862],
                    [52.5219, 13.3934],
                    [52.5235, 13.4001],
                ],
            };

            let s = serde_json::to_string(&route)?;
            Ok(s)
        }
    }
}



/// Ingest samples (GPS/IMU) for a running route. Accepts CBOR bytes for the
/// GPS and IMU payloads. Returns 0 on success, non-zero on error.
#[frb]
pub fn nav_ingest_samples(
    route_id: i32,
    gps_cbor: Option<Vec<u8>>,
    imu_cbor: Option<Vec<u8>>,
) -> anyhow::Result<i32> {
    // TODO: feed bytes into the route state machine. For now, no-op.
    let _ = route_id;
    let _ = gps_cbor;
    let _ = imu_cbor;
    Ok(0)
}

/// Get the next Cue for the route as a CBOR/JSON byte buffer.
#[frb]
pub fn nav_next_cue(route_id: i32) -> anyhow::Result<Vec<u8>> {
    let _ = route_id;
    // TODO: serialize next Cue into CBOR and return bytes.
    Ok(Vec::new())
}

/// Reset/stop the route state machine for `route_id`.
#[frb]
pub fn nav_reset(route_id: i32) -> anyhow::Result<i32> {
    let _ = route_id;
    // TODO: perform reset logic.
    Ok(0)
}

/// Free a buffer previously returned by the native side.
///
/// NOTE: when using `Vec<u8>` via FRB this is usually unnecessary because the
/// buffer is copied into Dart as `Uint8List` or moved; this function is provided
/// as a semantic no-op to match the checklist's ownership API.
#[frb]
pub fn nav_buf_free(_buf: Vec<u8>) -> anyhow::Result<i32> {
    // Consuming the Vec drops it here. Return 0 for success.
    Ok(0)
}
