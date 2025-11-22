use anyhow::Result;
use flutter_rust_bridge::frb;

/// Minimal test API placed in a dedicated module to verify codegen
/// discovery across multiple files.
#[frb]
pub fn hello_world() -> Result<String> {
    Ok("hello from rust".to_string())
}
