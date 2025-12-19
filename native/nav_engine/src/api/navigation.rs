/// Navigation session APIs
use anyhow::Result;
use std::sync::Arc;

use super::{dto::*, helpers::*};
use crate::application::{
    commands::*,
    handlers::*,
    queries::*,
    traits::{CommandHandler, QueryHandler},
};
use crate::domain::{
    entities::*,
    ports::{ControlCommand, DeviceCommunicationPort},
    value_objects::*,
};
use async_trait::async_trait;

// Mock device communication for now
pub struct MockDeviceComm;
#[async_trait]
impl DeviceCommunicationPort for MockDeviceComm {
    async fn send_route_summary(
        &self,
        _device_id: String,
        _session: &NavigationSession,
    ) -> Result<()> {
        Ok(())
    }
    async fn send_route_blob(&self, _device_id: String, _route: &Route) -> Result<()> {
        Ok(())
    }
    async fn send_position_update(&self, _device_id: String, _position: Position) -> Result<()> {
        Ok(())
    }
    async fn send_traffic_alert(&self, _device_id: String, _event: &TrafficEvent) -> Result<()> {
        Ok(())
    }
    async fn send_control_command(
        &self,
        _device_id: String,
        _command: ControlCommand,
    ) -> Result<()> {
        Ok(())
    }
}

/// Start a new navigation session

pub fn start_navigation_session(
    waypoints: Vec<(f64, f64)>,
    current_position: (f64, f64),
) -> Result<String> {
    query_json_async(|| async {
        let ctx = super::get_context();

        let waypoint_positions: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon).map_err(|e| anyhow::anyhow!(e)))
            .collect();

        let current_pos = Position::new(current_position.0, current_position.1)
            .map_err(|e| anyhow::anyhow!(e))?;

        let device_comm = Arc::new(MockDeviceComm);

        let handler = StartNavigationHandler::new(
            ctx.route_service.clone(),
            ctx.navigation_repo.clone(),
            device_comm,
        );

        let command = StartNavigationCommand {
            waypoints: waypoint_positions?,
            current_position: current_pos,
            device_id: None,
        };

        let session = handler.handle(command).await?;
        Ok(navigation_session_to_dto(session))
    })
}

/// Update current position during navigation

pub fn update_navigation_position(session_id: String, latitude: f64, longitude: f64) -> Result<()> {
    command_async(|| async {
        let ctx = super::get_context();
        let handler =
            UpdatePositionHandler::new(ctx.navigation_repo.clone(), Arc::new(MockDeviceComm));

        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;

        let command = UpdatePositionCommand {
            session_id: session_uuid,
            position,
        };

        handler.handle(command).await
    })
}

/// Get the currently active navigation session

pub fn get_active_session() -> Result<Option<String>> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = super::get_context();
        let handler = GetActiveSessionHandler::new(ctx.navigation_repo.clone());

        let session = handler.handle(GetActiveSessionQuery {}).await?;
        Ok(session.map(|s| serde_json::to_string(&navigation_session_to_dto(s)).unwrap()))
    })
}

/// Pause active navigation

pub fn pause_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let ctx = super::get_context();
        let handler = PauseNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = PauseNavigationCommand {
            session_id: session_uuid,
        };

        handler.handle(command).await
    })
}

/// Resume paused navigation

pub fn resume_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let ctx = super::get_context();
        let handler = ResumeNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = ResumeNavigationCommand {
            session_id: session_uuid,
        };

        handler.handle(command).await
    })
}

/// Stop and complete navigation session

pub fn stop_navigation(session_id: String) -> Result<()> {
    command_async(|| async {
        let ctx = super::get_context();
        let handler = StopNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = StopNavigationCommand {
            session_id: session_uuid,
            completed: true,
        };

        handler.handle(command).await
    })
}
