use std::sync::RwLock;

#[derive(Clone, Default)]
pub struct NavDspConfig {
    pub base_url: String,
    pub token: Option<String>,
    pub geocoding_enabled: bool,
}

static CONFIG: RwLock<NavDspConfig> = RwLock::new(NavDspConfig {
    base_url: String::new(),
    token: None,
    geocoding_enabled: false,
});

pub fn set_config(base_url: String, token: Option<String>, geocoding_enabled: bool) {
    let mut guard = CONFIG.write().unwrap();
    guard.base_url = base_url;
    guard.token = token;
    guard.geocoding_enabled = geocoding_enabled;
}

pub fn get_config() -> NavDspConfig {
    CONFIG.read().unwrap().clone()
}
