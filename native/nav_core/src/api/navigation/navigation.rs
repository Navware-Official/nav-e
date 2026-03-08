/// Navigation session APIs
use anyhow::Result;

use crate::api::{dto::*, helpers::*};
use crate::app::container::get_container;
use crate::navigation::application::{commands::*, queries::*};
use crate::shared::value_objects::*;

/// Start a new navigation session
pub fn start_navigation_session(
    waypoints: Vec<(f64, f64)>,
    current_position: (f64, f64),
) -> Result<String> {
    query_json_async(|| async {
        let waypoint_positions: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon).map_err(|e| anyhow::anyhow!(e)))
            .collect();

        let current_pos = Position::new(current_position.0, current_position.1)
            .map_err(|e| anyhow::anyhow!(e))?;

        let command = StartNavigationCommand {
            waypoints: waypoint_positions?,
            current_position: current_pos,
            device_id: None,
        };

        let session = get_container().navigation.start(command).await?;
        Ok(navigation_session_to_dto(&session))
    })
}

/// Update current position during navigation
pub fn update_navigation_position(session_id: String, latitude: f64, longitude: f64) -> Result<()> {
    command_async(|| async {
        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;

        let command = UpdatePositionCommand {
            session_id: session_uuid,
            position,
        };

        get_container().navigation.update_position(command).await
    })
}

/// Get the currently active navigation session
pub fn get_active_session() -> Result<Option<String>> {
    block_on(async {
        let session = get_container().navigation.get_active(GetActiveSessionQuery {}).await?;
        Ok(session
            .as_ref()
            .map(|s| serde_json::to_string(&navigation_session_to_dto(s)).unwrap()))
    })
}

/// Pause active navigation
pub fn pause_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        get_container()
            .navigation
            .pause(PauseNavigationCommand { session_id: session_uuid })
            .await
    })
}

/// Resume paused navigation
pub fn resume_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        get_container()
            .navigation
            .resume(ResumeNavigationCommand { session_id: session_uuid })
            .await
    })
}

/// Stop and complete navigation session
pub fn stop_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        get_container()
            .navigation
            .stop(StopNavigationCommand {
                session_id: session_uuid,
                completed: true,
            })
            .await
    })
}
