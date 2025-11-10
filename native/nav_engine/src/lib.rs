mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

mod geocode;

pub use geocode::{FrbGeocodingResult};

use flutter_rust_bridge::frb;

// Return raw JSON string (existing helper)
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> anyhow::Result<String> {
    // Delegate to async runtime
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async move { geocode::search_raw_json(&query, limit).await })
}

// Typed result: FRB will generate typed Dart classes for FrbGeocodingResult
#[frb]
pub fn geocode_search_typed(
    query: String,
    limit: Option<u32>,
) -> anyhow::Result<Vec<FrbGeocodingResult>> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async move { geocode::search_typed(&query, limit).await })
}
