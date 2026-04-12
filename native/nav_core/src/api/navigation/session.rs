/// Navigation session APIs
use anyhow::{Context, Result};

use crate::api::{dto::*, helpers::*};
use crate::app::container::get_container;
use crate::navigation::application::{commands::*, queries::*};
use crate::shared::value_objects::*;

/// Start a new navigation session
pub fn start_navigation_session(
    waypoints: Vec<(f64, f64)>,
    current_position: (f64, f64),
) -> Result<NavigationSessionDto> {
    query_async(|| async {
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

/// Update current position during navigation. Returns navigation state.
pub fn update_navigation_position(
    session_id: String,
    latitude: f64,
    longitude: f64,
) -> Result<NavigationStateDto> {
    query_async(|| async {
        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;

        let command = UpdatePositionCommand {
            session_id: session_uuid,
            position,
        };

        let nav_state = get_container().navigation.update_position(command).await?;
        Ok(navigation_state_to_dto(nav_state))
    })
}

/// Get the latest navigation state for a session without updating position.
pub fn get_navigation_state(session_id: String) -> Result<Option<NavigationStateDto>> {
    block_on(async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let session = get_container()
            .navigation
            .get_active(crate::navigation::application::queries::GetActiveSessionQuery {})
            .await?;
        match session {
            Some(s) if s.id == session_uuid => {
                let coord = nav_ir::Coordinate::new(
                    s.current_position.latitude,
                    s.current_position.longitude,
                );
                let mut engine = nav_engine::NavigationEngine::new_with_state(
                    s.route,
                    s.current_step_index,
                    s.distance_traveled_m,
                );
                let nav_state = engine.update_position(coord, None);
                Ok(Some(navigation_state_to_dto(nav_state)))
            }
            _ => Ok(None),
        }
    })
}

/// Get the currently active navigation session
pub fn get_active_session() -> Result<Option<String>> {
    block_on(async {
        let session = get_container()
            .navigation
            .get_active(GetActiveSessionQuery {})
            .await?;
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
            .pause(PauseNavigationCommand {
                session_id: session_uuid,
            })
            .await
    })
}

/// Resume paused navigation
pub fn resume_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        get_container()
            .navigation
            .resume(ResumeNavigationCommand {
                session_id: session_uuid,
            })
            .await
    })
}

/// Get all route steps (turn-by-turn instructions) for a session.
pub fn get_route_steps(session_id: String) -> Result<Vec<DerivedInstructionDto>> {
    block_on(async {
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let session = get_container()
            .navigation
            .load_session(session_uuid)
            .await?
            .context("Session not found")?;
        let engine = nav_engine::NavigationEngine::new_with_state(
            session.route,
            session.current_step_index,
            session.distance_traveled_m,
        );
        let steps: Vec<DerivedInstructionDto> = engine
            .instructions()
            .iter()
            .cloned()
            .map(instruction_to_dto)
            .collect();
        Ok(steps)
    })
}

/// Get aggregated stats across all non-cancelled navigation sessions.
pub fn get_session_stats() -> Result<SessionStatsDto> {
    block_on(async {
        let stats = get_container().navigation.get_session_stats().await?;
        Ok(SessionStatsDto {
            total_distance_m: stats.total_distance_m,
            total_duration_seconds: stats.total_duration_seconds,
            session_count: stats.session_count,
        })
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
