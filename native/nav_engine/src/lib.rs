mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

mod geocode;
mod types;
mod osrm;
mod route;
mod api;

pub use geocode::FrbGeocodingResult;
pub use types::FrbRoute;

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

// Return raw JSON string (existing helper)
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> anyhow::Result<String> {
    // Temporary inline implementation for codegen probing: return empty
    // result. This avoids delegating into other modules which may affect
    // codegen discovery.
    let _ = query;
    let _ = limit;
    Ok("[]".to_string())
}

// Small diagnostic function to verify FRB codegen picks up exported
// functions. Returns a simple string.
#[frb]
pub fn ping() -> anyhow::Result<String> {
    Ok("pong".to_string())
}

// Minimal test export to verify codegen detection.
#[frb]
pub fn test_export_inc(x: i32) -> anyhow::Result<i32> {
    Ok(x + 1)
}

// Typed result: FRB will generate typed Dart classes for FrbGeocodingResult
#[frb]
pub fn geocode_search_typed(
    query: String,
    limit: Option<u32>,
) -> anyhow::Result<Vec<FrbGeocodingResult>> {
    let _ = query;
    let _ = limit;
    Ok(Vec::new())
}

// ---------------------------------------------------------------------------
// Hardcoded route stub for development / simulation
// - Returns a CBOR-encoded `FrbRoute` blob so the Dart side can decode and
//   display a polyline/summary without a real routing backend.
// - Uses `serde_cbor` for compact binary encoding.
// ---------------------------------------------------------------------------

#[frb]
pub fn nav_compute_route(
    start_lat: f64,
    start_lon: f64,
    end_lat: f64,
    end_lon: f64,
    options: Option<String>,
) -> anyhow::Result<String> {
    // Inline a simple hardcoded route JSON for codegen probing. This avoids
    // any async or module delegation which may interfere with discovery.
    let _ = options;
    let waypoints = vec![
        vec![start_lat, start_lon],
        vec![end_lat, end_lon],
    ];
    let s = format!(
        r#"{{"id":"probe-route","polyline":"","distance_m":100.0,"duration_s":60.0,"name":"Probe route","waypoints":{wp}}}"#,
        wp = serde_json::to_string(&waypoints)?
    );
    Ok(s)
}

// A deliberately-simple FRB wrapper with a distinct name to test codegen
// discovery. If the generator picks this up but not `nav_compute_route`, it
// indicates the issue is likely around name/signature parsing or module
// traversal rather than the Makefile invocation.
#[frb]
pub fn nav_compute_route_simple(
    start_lat: f64,
    start_lon: f64,
    end_lat: f64,
    end_lon: f64,
) -> anyhow::Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    let route = rt.block_on(async move {
        route::compute_route_async(start_lat, start_lon, end_lat, end_lon, None).await
    })?;

    Ok(serde_json::to_string(&route)?)
}

// Super-simple FRB test function: no options, returns a fixed string. This
// helps verify if the codegen picks up tiny, trivial top-level `#[frb]`
// functions (useful for narrowing the root cause).
#[frb]
pub fn nav_test() -> anyhow::Result<String> {
    Ok("nav-test-ok".to_string())
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
