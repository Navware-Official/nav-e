use nav_ir::{Coordinate, Route};
use polyline::decode_polyline;

use crate::derive_instructions::{derive_instructions, haversine_distance};
use crate::off_route::{distance_to_polyline, OFF_ROUTE_THRESHOLD_M};
use crate::progress::{estimate_eta, remaining_distance};
use crate::types::{
    ConstraintAlert, DerivedInstruction, DerivedInstructionKind, NavigationState, OffRouteStatus,
};

/// Runtime turn-by-turn navigation engine.
///
/// Created from a `nav_ir::Route`. Call `update_position()` on each GPS fix
/// to get a fresh `NavigationState`.
pub struct NavigationEngine {
    route: Route,
    polyline_vertices: Vec<Coordinate>,
    instructions: Vec<DerivedInstruction>,
    total_distance_m: f64,
    current_step: usize,
    distance_traveled_m: f64,
}

impl NavigationEngine {
    /// Build a fresh engine from a route (starting at step 0).
    pub fn new(route: Route) -> Self {
        Self::new_with_state(route, 0, 0.0)
    }

    /// Build an engine and restore prior step / distance state (for session resume).
    pub fn new_with_state(route: Route, current_step: usize, distance_traveled_m: f64) -> Self {
        let polyline_vertices = decode_route_vertices(&route);
        let existing = route
            .segments
            .first()
            .map(|s| s.instructions.as_slice())
            .unwrap_or(&[]);
        let instructions = derive_instructions(&polyline_vertices, existing);
        let total_distance_m = route.metadata.total_distance_m.unwrap_or_else(|| {
            (0..polyline_vertices.len().saturating_sub(1))
                .map(|i| haversine_distance(polyline_vertices[i], polyline_vertices[i + 1]))
                .sum()
        });
        let clamped_step = current_step.min(instructions.len().saturating_sub(1));
        Self {
            route,
            polyline_vertices,
            instructions,
            total_distance_m,
            current_step: clamped_step,
            distance_traveled_m,
        }
    }

    /// Process a GPS position fix and return the current navigation state.
    ///
    /// `speed_mps`: optional GPS speed for ETA calculation.
    pub fn update_position(&mut self, pos: Coordinate, speed_mps: Option<f64>) -> NavigationState {
        if self.polyline_vertices.is_empty() {
            return self.fallback_state(pos);
        }

        let (dist_from_route, nearest_vertex, snapped) =
            distance_to_polyline(pos, &self.polyline_vertices);

        // Advance step: keep advancing while the next instruction's vertex is behind us
        while self.current_step + 1 < self.instructions.len()
            && nearest_vertex >= self.instructions[self.current_step + 1].vertex_index
        {
            self.current_step += 1;
        }

        let remaining_m = remaining_distance(&self.polyline_vertices, nearest_vertex);
        self.distance_traveled_m = (self.total_distance_m - remaining_m).max(0.0);

        let eta = estimate_eta(
            remaining_m,
            speed_mps,
            self.route.metadata.estimated_duration_s,
            self.total_distance_m,
        );

        let current_instruction = self
            .instructions
            .get(self.current_step)
            .cloned()
            .unwrap_or_else(|| arrive_stub(self.polyline_vertices.len().saturating_sub(1)));

        let next_instruction = self.instructions.get(self.current_step + 1).cloned();

        let distance_to_next_m =
            distance_to_next(&self.polyline_vertices, nearest_vertex, &next_instruction, remaining_m);

        NavigationState {
            current_step: self.current_step,
            current_instruction,
            next_instruction,
            distance_to_next_m,
            distance_remaining_m: remaining_m,
            eta_seconds: eta,
            off_route: OffRouteStatus {
                is_off_route: dist_from_route > OFF_ROUTE_THRESHOLD_M,
                distance_from_route_m: dist_from_route,
                behavior: self.route.policies.off_route_behavior,
            },
            constraint_alerts: build_alerts(&self.route),
            snapped_position: snapped,
        }
    }

    pub fn current_step(&self) -> usize {
        self.current_step
    }

    pub fn distance_traveled_m(&self) -> f64 {
        self.distance_traveled_m
    }

    /// Return all derived instructions for this route (for turn-feed display).
    pub fn instructions(&self) -> &[DerivedInstruction] {
        &self.instructions
    }

    fn fallback_state(&self, pos: Coordinate) -> NavigationState {
        NavigationState {
            current_step: 0,
            current_instruction: arrive_stub(0),
            next_instruction: None,
            distance_to_next_m: 0.0,
            distance_remaining_m: 0.0,
            eta_seconds: 0,
            off_route: OffRouteStatus {
                is_off_route: false,
                distance_from_route_m: 0.0,
                behavior: self.route.policies.off_route_behavior,
            },
            constraint_alerts: vec![],
            snapped_position: pos,
        }
    }
}

fn decode_route_vertices(route: &Route) -> Vec<Coordinate> {
    route
        .segments
        .first()
        .and_then(|seg| decode_polyline(&seg.geometry.polyline.0, 5).ok())
        .map(|line| line.coords().map(|c| Coordinate::new(c.y, c.x)).collect())
        .unwrap_or_default()
}

fn build_alerts(route: &Route) -> Vec<ConstraintAlert> {
    let Some(seg) = route.segments.first() else {
        return vec![];
    };
    let mut alerts = Vec::new();
    if let Some(max) = seg.constraints.max_speed_kmh {
        alerts.push(ConstraintAlert::SpeedLimit { max_kmh: max });
    }
    if seg.constraints.avoid_highways {
        alerts.push(ConstraintAlert::AvoidHighway);
    }
    if seg.constraints.avoid_tolls {
        alerts.push(ConstraintAlert::AvoidToll);
    }
    alerts
}

fn arrive_stub(vertex_index: usize) -> DerivedInstruction {
    DerivedInstruction {
        kind: DerivedInstructionKind::Arrive,
        vertex_index,
        distance_to_next_m: 0.0,
        street_name: None,
    }
}

fn distance_to_next(
    vertices: &[Coordinate],
    from_vertex: usize,
    next: &Option<DerivedInstruction>,
    remaining_m: f64,
) -> f64 {
    let Some(next) = next else {
        return remaining_m;
    };
    if next.vertex_index <= from_vertex {
        return 0.0;
    }
    let rem_here = remaining_distance(vertices, from_vertex);
    let rem_at_next = remaining_distance(vertices, next.vertex_index);
    (rem_here - rem_at_next).max(0.0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use nav_ir::*;

    fn make_route_with_vertices(encoded_polyline: &str) -> Route {
        Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: "Test".into(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(1_000_000.0),
                estimated_duration_s: Some(36000),
                tags: vec![],
                source: None,
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(encoded_polyline.into()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 0.0,
                        min_lon: -5.0,
                        max_lat: 5.0,
                        max_lon: 5.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(0.0, 0.0),
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
                        coordinate: Coordinate::new(2.0, 2.0),
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
        }
    }

    /// Encode a sequence of (lat, lon) pairs to a polyline string.
    fn encode_points(pts: &[(f64, f64)]) -> String {
        let coords: Vec<geo_types::Coord> = pts
            .iter()
            .map(|(lat, lon)| geo_types::Coord { x: *lon, y: *lat })
            .collect();
        polyline::encode_coordinates(coords, 5).unwrap_or_default()
    }

    #[test]
    fn step_advancement_along_straight_route() {
        // Straight route: 0° → 1° → 2° north (no turns, just Depart + Arrive)
        let poly = encode_points(&[(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)]);
        let route = make_route_with_vertices(&poly);
        let mut engine = NavigationEngine::new(route);

        // Start at beginning
        let s0 = engine.update_position(Coordinate::new(0.0, 0.0), None);
        assert_eq!(s0.current_step, 0);
        assert!(s0.distance_remaining_m > 100_000.0);

        // Near the end
        let s1 = engine.update_position(Coordinate::new(2.0, 0.0), None);
        assert!(s1.distance_remaining_m < 1000.0);
    }

    #[test]
    fn off_route_flagged_when_far_from_polyline() {
        // North-going polyline; position is far east (≫ 50 m off)
        let poly = encode_points(&[(0.0, 0.0), (1.0, 0.0)]);
        let route = make_route_with_vertices(&poly);
        let mut engine = NavigationEngine::new(route);

        // 0.01 degrees east at equator ≈ 1.1 km off route
        let state = engine.update_position(Coordinate::new(0.5, 0.01), None);
        assert!(state.off_route.is_off_route, "expected off-route");
        assert!(state.off_route.distance_from_route_m > OFF_ROUTE_THRESHOLD_M);
    }

    #[test]
    fn on_route_not_flagged_when_close_to_polyline() {
        let poly = encode_points(&[(0.0, 0.0), (1.0, 0.0)]);
        let route = make_route_with_vertices(&poly);
        let mut engine = NavigationEngine::new(route);

        // Very close to the polyline
        let state = engine.update_position(Coordinate::new(0.5, 0.0001), None);
        assert!(!state.off_route.is_off_route, "should be on-route");
    }

    #[test]
    fn new_with_state_restores_step() {
        let poly = encode_points(&[(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)]);
        let route = make_route_with_vertices(&poly);
        let engine = NavigationEngine::new_with_state(route, 1, 111_000.0);
        assert_eq!(engine.current_step(), 1);
        assert!((engine.distance_traveled_m() - 111_000.0).abs() < 1.0);
    }

    #[test]
    fn right_turn_route_has_turn_instruction() {
        // North then east — right turn at vertex 1
        let poly = encode_points(&[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]);
        let route = make_route_with_vertices(&poly);
        let mut engine = NavigationEngine::new(route);
        // Start: should have a next_instruction (the turn)
        let state = engine.update_position(Coordinate::new(0.0, 0.0), None);
        assert!(
            state.next_instruction.is_some(),
            "expected a next instruction (turn)"
        );
        if let Some(ref next) = state.next_instruction {
            assert_eq!(next.kind, DerivedInstructionKind::TurnRight);
        }
    }
}
