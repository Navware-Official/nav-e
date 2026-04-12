//! MultiRouteService — runtime-switchable routing engine dispatcher.
//!
//! Implements nav_core's `RouteService` port. Holds a registry of named engines and an
//! `std::sync::RwLock<String>` active-engine key. On every `calculate_route` call it reads
//! the current key, clones the `Arc` to the selected engine (releasing the lock), then
//! delegates — no lock held across `.await` points.
//!
//! Constructed once by `nav_e_ffi::initialize_database` and stored in a `OnceLock` so that
//! `set_routing_engine` can update the active key without touching `AppContainer`.

use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nav_ir::Route as NavIrRoute;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

pub struct MultiRouteService {
    engines: HashMap<String, Arc<dyn nav_core::RouteService>>,
    active: RwLock<String>,
}

impl MultiRouteService {
    /// Create a dispatcher with `default` as the initially active engine.
    ///
    /// Panics if `default` is not a key in `engines`.
    pub fn new(default: String, engines: HashMap<String, Arc<dyn nav_core::RouteService>>) -> Self {
        assert!(
            engines.contains_key(&default),
            "MultiRouteService: default engine '{}' not found in engines map",
            default
        );
        Self {
            engines,
            active: RwLock::new(default),
        }
    }

    /// Switch the active engine by name. Returns an error if `name` is not registered.
    pub fn set_engine(&self, name: &str) -> Result<()> {
        if !self.engines.contains_key(name) {
            return Err(anyhow!("Unknown routing engine: '{}'", name));
        }
        *self.active.write().unwrap() = name.to_string();
        Ok(())
    }

    fn active_engine(&self) -> Result<Arc<dyn nav_core::RouteService>> {
        let name = self.active.read().unwrap();
        self.engines
            .get(name.as_str())
            .cloned()
            .ok_or_else(|| anyhow!("Active routing engine '{}' not found", *name))
    }
}

#[async_trait]
impl nav_core::RouteService for MultiRouteService {
    async fn calculate_route(&self, waypoints: Vec<nav_core::Position>) -> Result<NavIrRoute> {
        self.active_engine()?.calculate_route(waypoints).await
    }

    async fn recalculate_from_position(
        &self,
        route: &NavIrRoute,
        current_position: nav_core::Position,
    ) -> Result<NavIrRoute> {
        self.active_engine()?
            .recalculate_from_position(route, current_position)
            .await
    }
}
