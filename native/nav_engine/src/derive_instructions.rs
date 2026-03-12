use nav_ir::{Coordinate, GeometryRefKind, Instruction, InstructionKind};

use crate::types::{DerivedInstruction, DerivedInstructionKind};

const MIN_TURN_DEGREES: f64 = 25.0;
const MIN_INSTRUCTION_DISTANCE_M: f64 = 30.0;

/// Haversine distance in meters between two coordinates.
pub fn haversine_distance(a: Coordinate, b: Coordinate) -> f64 {
    const R: f64 = 6_371_000.0;
    let lat1 = a.latitude.to_radians();
    let lat2 = b.latitude.to_radians();
    let dlat = (b.latitude - a.latitude).to_radians();
    let dlon = (b.longitude - a.longitude).to_radians();
    let h =
        (dlat / 2.0).sin().powi(2) + lat1.cos() * lat2.cos() * (dlon / 2.0).sin().powi(2);
    R * 2.0 * h.sqrt().atan2((1.0 - h).sqrt())
}

/// Forward bearing from `from` to `to` in degrees.
pub fn bearing(from: Coordinate, to: Coordinate) -> f64 {
    let lat1 = from.latitude.to_radians();
    let lat2 = to.latitude.to_radians();
    let dlon = (to.longitude - from.longitude).to_radians();
    let y = dlon.sin() * lat2.cos();
    let x = lat1.cos() * lat2.sin() - lat1.sin() * lat2.cos() * dlon.cos();
    y.atan2(x).to_degrees()
}

/// Normalise a bearing delta to [-180, 180].
fn normalize_delta(delta: f64) -> f64 {
    let d = delta % 360.0;
    if d > 180.0 {
        d - 360.0
    } else if d < -180.0 {
        d + 360.0
    } else {
        d
    }
}

fn kind_from_delta(delta: f64) -> DerivedInstructionKind {
    match delta {
        d if d > 120.0 => DerivedInstructionKind::SharpRight,
        d if d >= 45.0 => DerivedInstructionKind::TurnRight,
        d if d >= MIN_TURN_DEGREES => DerivedInstructionKind::SlightRight,
        d if d > -MIN_TURN_DEGREES => DerivedInstructionKind::Continue,
        d if d > -45.0 => DerivedInstructionKind::SlightLeft,
        d if d > -120.0 => DerivedInstructionKind::TurnLeft,
        _ => DerivedInstructionKind::SharpLeft,
    }
}

fn nav_ir_kind_to_derived(kind: InstructionKind) -> DerivedInstructionKind {
    match kind {
        InstructionKind::TurnLeft => DerivedInstructionKind::TurnLeft,
        InstructionKind::TurnRight => DerivedInstructionKind::TurnRight,
        InstructionKind::Continue => DerivedInstructionKind::Continue,
        InstructionKind::Arrive => DerivedInstructionKind::Arrive,
        InstructionKind::Depart => DerivedInstructionKind::Depart,
        InstructionKind::Merge | InstructionKind::Roundabout => DerivedInstructionKind::Continue,
    }
}

fn turn_severity(kind: DerivedInstructionKind) -> u8 {
    match kind {
        DerivedInstructionKind::SharpLeft | DerivedInstructionKind::SharpRight => 4,
        DerivedInstructionKind::TurnLeft | DerivedInstructionKind::TurnRight => 3,
        DerivedInstructionKind::SlightLeft | DerivedInstructionKind::SlightRight => 2,
        DerivedInstructionKind::Continue => 1,
        DerivedInstructionKind::Depart | DerivedInstructionKind::Arrive => 5,
    }
}

/// Derive turn instructions from polyline vertices.
///
/// Pre-existing `nav_ir::Instruction` items matched by vertex index are used directly;
/// any remaining vertices with |bearing delta| ≥ 25° generate a `DerivedInstruction`.
/// Always prepends `Depart` and appends `Arrive`.
pub fn derive_instructions(
    vertices: &[Coordinate],
    existing: &[Instruction],
) -> Vec<DerivedInstruction> {
    if vertices.is_empty() {
        return vec![];
    }

    // Build lookup: vertex_index → existing instruction (geometry_ref only)
    let mut existing_at: std::collections::HashMap<usize, &Instruction> =
        std::collections::HashMap::new();
    for inst in existing {
        if let Some(ref gr) = inst.geometry_ref {
            if gr.kind == GeometryRefKind::VertexIndex {
                if let Some(vi) = gr.vertex_index {
                    existing_at.insert(vi as usize, inst);
                }
            }
        }
    }

    let n = vertices.len();
    let mut raw: Vec<DerivedInstruction> = Vec::new();

    // Depart at vertex 0
    raw.push(DerivedInstruction {
        kind: DerivedInstructionKind::Depart,
        vertex_index: 0,
        distance_to_next_m: 0.0,
        street_name: None,
    });

    // Interior vertices
    for i in 1..n.saturating_sub(1) {
        if let Some(inst) = existing_at.get(&i) {
            raw.push(DerivedInstruction {
                kind: nav_ir_kind_to_derived(inst.kind),
                vertex_index: i,
                distance_to_next_m: 0.0,
                street_name: inst.street_name.clone(),
            });
            continue;
        }

        let b1 = bearing(vertices[i - 1], vertices[i]);
        let b2 = bearing(vertices[i], vertices[i + 1]);
        let delta = normalize_delta(b2 - b1);

        if delta.abs() < MIN_TURN_DEGREES {
            continue;
        }

        raw.push(DerivedInstruction {
            kind: kind_from_delta(delta),
            vertex_index: i,
            distance_to_next_m: 0.0,
            street_name: None,
        });
    }

    // Arrive at last vertex
    raw.push(DerivedInstruction {
        kind: DerivedInstructionKind::Arrive,
        vertex_index: n.saturating_sub(1),
        distance_to_next_m: 0.0,
        street_name: None,
    });

    fill_and_filter(raw, vertices)
}

/// Assign `distance_to_next_m` from vertex distances, then filter instructions
/// that are closer than `MIN_INSTRUCTION_DISTANCE_M` to each other (keep larger turn).
fn fill_and_filter(
    instructions: Vec<DerivedInstruction>,
    vertices: &[Coordinate],
) -> Vec<DerivedInstruction> {
    if instructions.len() <= 2 {
        return instructions;
    }

    // Build cumulative distance array
    let mut cum = vec![0.0f64; vertices.len()];
    for i in 1..vertices.len() {
        cum[i] = cum[i - 1] + haversine_distance(vertices[i - 1], vertices[i]);
    }

    // Fill distances
    let mut result = instructions;
    for i in 0..result.len() {
        let vi = result[i].vertex_index;
        let next_vi = if i + 1 < result.len() {
            result[i + 1].vertex_index
        } else {
            vi
        };
        result[i].distance_to_next_m = if next_vi > vi && next_vi < cum.len() {
            cum[next_vi] - cum[vi]
        } else {
            0.0
        };
    }

    // Filter too-close instructions (keep Depart/Arrive always)
    let mut filtered: Vec<DerivedInstruction> = Vec::with_capacity(result.len());
    let mut i = 0;
    while i < result.len() {
        let curr = &result[i];
        let is_boundary = matches!(
            curr.kind,
            DerivedInstructionKind::Depart | DerivedInstructionKind::Arrive
        );
        if !is_boundary
            && curr.distance_to_next_m < MIN_INSTRUCTION_DISTANCE_M
            && i + 1 < result.len()
        {
            let next = &result[i + 1];
            // Keep whichever has higher severity
            if turn_severity(curr.kind) >= turn_severity(next.kind) {
                filtered.push(curr.clone());
                i += 2;
            } else {
                i += 1;
            }
        } else {
            filtered.push(curr.clone());
            i += 1;
        }
    }
    filtered
}

#[cfg(test)]
mod tests {
    use super::*;

    fn coord(lat: f64, lon: f64) -> Coordinate {
        Coordinate::new(lat, lon)
    }

    #[test]
    fn straight_road_yields_only_depart_arrive() {
        // Three collinear points going north — no turn
        let vertices = vec![coord(0.0, 0.0), coord(1.0, 0.0), coord(2.0, 0.0)];
        let instructions = derive_instructions(&vertices, &[]);
        assert_eq!(instructions.len(), 2);
        assert_eq!(instructions[0].kind, DerivedInstructionKind::Depart);
        assert_eq!(instructions[1].kind, DerivedInstructionKind::Arrive);
    }

    #[test]
    fn right_turn_yields_depart_turn_right_arrive() {
        // North then east — 90° right turn at vertex 1
        let vertices = vec![coord(0.0, 0.0), coord(1.0, 0.0), coord(1.0, 1.0)];
        let instructions = derive_instructions(&vertices, &[]);
        assert_eq!(instructions.len(), 3);
        assert_eq!(instructions[0].kind, DerivedInstructionKind::Depart);
        assert_eq!(instructions[1].kind, DerivedInstructionKind::TurnRight);
        assert_eq!(instructions[1].vertex_index, 1);
        assert_eq!(instructions[2].kind, DerivedInstructionKind::Arrive);
    }

    #[test]
    fn left_turn_yields_turn_left() {
        // North then west — left turn at vertex 1
        let vertices = vec![coord(0.0, 0.0), coord(1.0, 0.0), coord(1.0, -1.0)];
        let instructions = derive_instructions(&vertices, &[]);
        let turn = instructions
            .iter()
            .find(|i| !matches!(i.kind, DerivedInstructionKind::Depart | DerivedInstructionKind::Arrive))
            .expect("should have a turn");
        assert!(matches!(
            turn.kind,
            DerivedInstructionKind::TurnLeft | DerivedInstructionKind::SharpLeft
        ));
    }

    #[test]
    fn distance_to_next_is_filled() {
        let vertices = vec![coord(0.0, 0.0), coord(1.0, 0.0), coord(1.0, 1.0)];
        let instructions = derive_instructions(&vertices, &[]);
        // Depart distance_to_next should be > 0
        assert!(instructions[0].distance_to_next_m > 0.0);
    }
}
