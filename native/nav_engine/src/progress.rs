use nav_ir::Coordinate;

use crate::derive_instructions::haversine_distance;

/// Sum of haversine distances from `from_vertex` to the end of the polyline.
pub fn remaining_distance(vertices: &[Coordinate], from_vertex: usize) -> f64 {
    let start = from_vertex.min(vertices.len().saturating_sub(1));
    (start..vertices.len().saturating_sub(1))
        .map(|i| haversine_distance(vertices[i], vertices[i + 1]))
        .sum()
}

/// Estimate ETA in seconds from remaining distance.
///
/// Priority:
/// 1. Known GPS speed (`speed_mps`)
/// 2. Scale route `estimated_duration_s` proportionally by remaining fraction
/// 3. Assume 40 km/h (~11.111 m/s)
pub fn estimate_eta(
    remaining_m: f64,
    speed_mps: Option<f64>,
    route_duration_s: Option<u64>,
    total_distance_m: f64,
) -> u64 {
    if remaining_m <= 0.0 {
        return 0;
    }
    if let Some(speed) = speed_mps {
        if speed > 0.1 {
            return (remaining_m / speed).round() as u64;
        }
    }
    if let Some(dur) = route_duration_s {
        if total_distance_m > 0.0 {
            return (dur as f64 * remaining_m / total_distance_m).round() as u64;
        }
    }
    // Default: 40 km/h = 11.111 m/s
    (remaining_m / 11.111).round() as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    fn c(lat: f64, lon: f64) -> Coordinate {
        Coordinate::new(lat, lon)
    }

    #[test]
    fn remaining_distance_full_route() {
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0), c(2.0, 0.0)];
        let total = remaining_distance(&vertices, 0);
        assert!(total > 200_000.0, "expected > 200 km, got {}m", total);
    }

    #[test]
    fn remaining_distance_at_end_is_zero() {
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0)];
        let rem = remaining_distance(&vertices, 1);
        assert_eq!(rem, 0.0);
    }

    #[test]
    fn eta_from_speed() {
        let eta = estimate_eta(10_000.0, Some(10.0), None, 20_000.0);
        assert_eq!(eta, 1000);
    }

    #[test]
    fn eta_from_route_duration() {
        // 5000m remaining of 10000m total, 2000s route duration → 1000s ETA
        let eta = estimate_eta(5_000.0, None, Some(2000), 10_000.0);
        assert_eq!(eta, 1000);
    }

    #[test]
    fn eta_defaults_to_40kmh() {
        // 11111m at 11.111 m/s ≈ 1000s
        let eta = estimate_eta(11_111.0, None, None, 0.0);
        assert!((eta as i64 - 1000).abs() < 5);
    }

    #[test]
    fn eta_zero_when_arrived() {
        let eta = estimate_eta(0.0, Some(5.0), Some(100), 1000.0);
        assert_eq!(eta, 0);
    }
}
