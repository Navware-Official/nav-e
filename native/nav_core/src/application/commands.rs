// Commands - Write operations
use crate::domain::value_objects::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Start a new navigation session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StartNavigationCommand {
    pub waypoints: Vec<Position>,
    pub current_position: Position,
    pub device_id: Option<String>,
}

/// Update current position during navigation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdatePositionCommand {
    pub session_id: Uuid,
    pub position: Position,
}

/// Pause active navigation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PauseNavigationCommand {
    pub session_id: Uuid,
}

/// Resume paused navigation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResumeNavigationCommand {
    pub session_id: Uuid,
}

/// Stop/complete navigation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StopNavigationCommand {
    pub session_id: Uuid,
    pub completed: bool, // true = completed, false = cancelled
}
