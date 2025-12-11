// In-memory repository implementation for development/testing
use crate::domain::{entities::NavigationSession, ports::NavigationRepository};
use anyhow::Result;
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;


pub struct InMemoryNavigationRepository {
    sessions: Arc<RwLock<HashMap<Uuid, NavigationSession>>>,
}

impl InMemoryNavigationRepository {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

impl Default for InMemoryNavigationRepository {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl NavigationRepository for InMemoryNavigationRepository {
    async fn save_session(&self, session: &NavigationSession) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.insert(session.id, session.clone());
        Ok(())
    }

    async fn load_session(&self, id: Uuid) -> Result<Option<NavigationSession>> {
        let sessions = self.sessions.read().await;
        Ok(sessions.get(&id).cloned())
    }

    async fn load_active_session(&self) -> Result<Option<NavigationSession>> {
        let sessions = self.sessions.read().await;
        Ok(sessions
            .values()
            .find(|s| s.status == crate::domain::entities::NavigationStatus::Active)
            .cloned())
    }

    async fn delete_session(&self, id: Uuid) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.remove(&id);
        Ok(())
    }
}
