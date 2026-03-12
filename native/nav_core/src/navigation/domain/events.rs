// Domain Events — typed enum published to the broadcast event bus.
use crate::shared::value_objects::Position;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// All navigation events emitted by application handlers.
///
/// Subscribers receive this via `nav_core::subscribe_navigation_events()`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NavigationEvent {
    Started {
        session_id: Uuid,
        route_id: Uuid,
    },
    PositionUpdated {
        session_id: Uuid,
        position: Position,
    },
    WaypointReached {
        session_id: Uuid,
        index: usize,
    },
    Completed {
        session_id: Uuid,
        distance_m: f64,
    },
    Cancelled {
        session_id: Uuid,
    },
    OffRoute {
        session_id: Uuid,
    },
}
