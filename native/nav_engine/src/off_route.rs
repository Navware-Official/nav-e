use nav_ir::Coordinate;

use crate::derive_instructions::haversine_distance;

/// Off-route threshold in meters.
pub const OFF_ROUTE_THRESHOLD_M: f64 = 50.0;

/// Returns `(distance_m, nearest_vertex_index, snapped_coordinate)` from `pos` to the polyline.
///
/// `snapped_coordinate` is the actual projected point on the closest segment (not a vertex),
/// giving smooth positional snapping rather than jumping between vertex endpoints.
/// `nearest_vertex_index` is still the closest vertex index, used for step advancement logic.
pub fn distance_to_polyline(
    pos: Coordinate,
    vertices: &[Coordinate],
) -> (f64, usize, Coordinate) {
    match vertices.len() {
        0 => return (f64::MAX, 0, pos),
        1 => return (haversine_distance(pos, vertices[0]), 0, vertices[0]),
        _ => {}
    }

    let mut min_dist = f64::MAX;
    let mut nearest_vertex = 0;
    let mut snapped_point = vertices[0];

    for i in 0..vertices.len() - 1 {
        let (dist, t, nearest) = point_to_segment_distance(pos, vertices[i], vertices[i + 1]);
        if dist < min_dist {
            min_dist = dist;
            nearest_vertex = if t < 0.5 { i } else { i + 1 };
            snapped_point = nearest;
        }
    }

    (min_dist, nearest_vertex, snapped_point)
}

/// Returns `(distance_m, t, nearest_coord)` where `t ∈ [0, 1]` is the projection parameter
/// along segment `a→b` and `nearest_coord` is the actual projected point on the segment.
///
/// Uses an approximate Cartesian projection — accurate enough for short navigation segments.
fn point_to_segment_distance(
    pos: Coordinate,
    a: Coordinate,
    b: Coordinate,
) -> (f64, f64, Coordinate) {
    let dx = b.latitude - a.latitude;
    let dy = b.longitude - a.longitude;
    let len_sq = dx * dx + dy * dy;
    let t = if len_sq < 1e-20 {
        0.0
    } else {
        ((pos.latitude - a.latitude) * dx + (pos.longitude - a.longitude) * dy) / len_sq
    };
    let t = t.clamp(0.0, 1.0);
    let nearest = Coordinate::new(a.latitude + t * dx, a.longitude + t * dy);
    (haversine_distance(pos, nearest), t, nearest)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn c(lat: f64, lon: f64) -> Coordinate {
        Coordinate::new(lat, lon)
    }

    #[test]
    fn point_on_polyline_has_zero_distance() {
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0), c(2.0, 0.0)];
        let (dist, _, _) = distance_to_polyline(c(1.0, 0.0), &vertices);
        assert!(dist < 1.0, "distance should be near zero, got {}", dist);
    }

    #[test]
    fn off_route_detection_threshold() {
        // A point ~67 m off a north-going polyline at the equator
        // 1 degree lon ≈ 111 km → 0.0006 deg ≈ 66.7 m
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0)];
        let (dist, _, _) = distance_to_polyline(c(0.5, 0.0006), &vertices);
        assert!(
            dist > OFF_ROUTE_THRESHOLD_M,
            "expected off-route, dist={:.1}m",
            dist
        );
    }

    #[test]
    fn on_route_within_threshold() {
        // A point ~22 m off — on-route
        // 0.0002 deg lon ≈ 22.3 m at equator
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0)];
        let (dist, _, _) = distance_to_polyline(c(0.5, 0.0002), &vertices);
        assert!(
            dist < OFF_ROUTE_THRESHOLD_M,
            "expected on-route, dist={:.1}m",
            dist
        );
    }

    #[test]
    fn nearest_vertex_advances_along_route() {
        let vertices = vec![c(0.0, 0.0), c(1.0, 0.0), c(2.0, 0.0)];
        let (_, v0, _) = distance_to_polyline(c(0.1, 0.0), &vertices);
        let (_, v1, _) = distance_to_polyline(c(1.5, 0.0), &vertices);
        assert!(v1 >= v0, "vertex index should advance along route");
    }
}
