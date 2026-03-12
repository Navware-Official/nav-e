use nav_ir::{Coordinate, OffRouteBehavior};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DerivedInstructionKind {
    Depart,
    SharpLeft,
    TurnLeft,
    SlightLeft,
    Continue,
    SlightRight,
    TurnRight,
    SharpRight,
    Arrive,
}

impl DerivedInstructionKind {
    pub fn as_str(self) -> &'static str {
        match self {
            DerivedInstructionKind::Depart => "depart",
            DerivedInstructionKind::SharpLeft => "sharp_left",
            DerivedInstructionKind::TurnLeft => "turn_left",
            DerivedInstructionKind::SlightLeft => "slight_left",
            DerivedInstructionKind::Continue => "continue",
            DerivedInstructionKind::SlightRight => "slight_right",
            DerivedInstructionKind::TurnRight => "turn_right",
            DerivedInstructionKind::SharpRight => "sharp_right",
            DerivedInstructionKind::Arrive => "arrive",
        }
    }
}

#[derive(Debug, Clone)]
pub struct DerivedInstruction {
    pub kind: DerivedInstructionKind,
    /// Index into the decoded polyline vertices where this instruction triggers.
    pub vertex_index: usize,
    /// Distance along route from this instruction to the next one.
    pub distance_to_next_m: f64,
    pub street_name: Option<String>,
}

#[derive(Debug, Clone)]
pub struct OffRouteStatus {
    pub is_off_route: bool,
    pub distance_from_route_m: f64,
    pub behavior: OffRouteBehavior,
}

#[derive(Debug, Clone)]
pub enum ConstraintAlert {
    SpeedLimit { max_kmh: u32 },
    AvoidHighway,
    AvoidToll,
}

#[derive(Debug, Clone)]
pub struct NavigationState {
    pub current_step: usize,
    pub current_instruction: DerivedInstruction,
    pub next_instruction: Option<DerivedInstruction>,
    /// Distance along the route from current position to the next instruction.
    pub distance_to_next_m: f64,
    /// Total remaining distance to destination.
    pub distance_remaining_m: f64,
    pub eta_seconds: u64,
    pub off_route: OffRouteStatus,
    pub constraint_alerts: Vec<ConstraintAlert>,
    /// GPS position snapped onto the polyline.
    pub snapped_position: Coordinate,
}
