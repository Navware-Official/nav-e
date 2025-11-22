use anyhow::Result;

use crate::types::FrbRoute;

/// Compute a route by trying the OSRM remote service first, and falling back
/// to a local hardcoded stub on any failure. The function is async so callers
/// can await it inside a tokio runtime.
pub async fn compute_route_async(
    start_lat: f64,
    start_lon: f64,
    end_lat: f64,
    end_lon: f64,
    _options: Option<String>,
) -> Result<FrbRoute> {
    // If start and end are effectively identical, avoid calling the remote
    // router: OSRM will often return degenerate results (same waypoint twice)
    // which is not useful for the UI. Return a local stub instead so the
    // application remains interactive during development.
    let eps = 1e-6_f64;
    if (start_lat - end_lat).abs() < eps && (start_lon - end_lon).abs() < eps {
        eprintln!("compute_route_async: start and end are identical, returning stub route");
        return Ok(stub_route());
    }

    match crate::osrm::fetch_osrm_route(start_lat, start_lon, end_lat, end_lon).await {
        Ok(r) => Ok(r),
        Err(e) => {
            // Log and return a local stub so the UI remains usable during
            // development or when network is unavailable.
            eprintln!("compute_route_async: OSRM fetch failed: {:?}", e);
            Ok(stub_route())
        }
    }
}

fn stub_route() -> FrbRoute {
    FrbRoute {
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
    }
}
