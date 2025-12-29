/// API helper functions to reduce boilerplate in FFI boundary
///
/// These helpers provide consistent error handling and serialization
/// patterns across all API functions.
use anyhow::Result;
use serde::Serialize;

/// Helper for synchronous repository queries that return JSON
///
/// # Example
/// ```rust
///
/// pub fn get_all_places() -> Result<String> {
///     query_json(|| get_context().places_repo.get_all())
/// }
/// ```
pub fn query_json<T, F>(operation: F) -> Result<String>
where
    T: Serialize,
    F: FnOnce() -> Result<T>,
{
    let result = operation()?;
    Ok(serde_json::to_string(&result)?)
}

/// Helper for synchronous repository commands that return an ID
///
/// # Example
/// ```rust
///
/// pub fn save_place(name: String, lat: f64, lon: f64) -> Result<i64> {
///     command_with_id(|| {
///         let place = SavedPlace { name, lat, lon, /* ... */ };
///         get_context().places_repo.insert(place)
///     })
/// }
/// ```
pub fn command_with_id<F>(operation: F) -> Result<i64>
where
    F: FnOnce() -> Result<i64>,
{
    operation()
}

/// Helper for synchronous repository commands that return nothing
///
/// # Example
/// ```rust
///
/// pub fn delete_place(id: i64) -> Result<()> {
///     command(|| get_context().places_repo.delete(id))
/// }
/// ```
pub fn command<F>(operation: F) -> Result<()>
where
    F: FnOnce() -> Result<()>,
{
    operation()
}

/// Helper for asynchronous operations that return JSON
///
/// Handles tokio runtime creation and async operation execution.
///
/// # Example
/// ```rust
///
/// pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
///     query_json_async(|| async {
///         let positions = waypoints_to_positions(waypoints)?;
///         let route = get_context().route_service.calculate_route(positions).await?;
///         Ok(route)
///     })
/// }
/// ```
pub fn query_json_async<T, F, Fut>(operation: F) -> Result<String>
where
    T: Serialize,
    F: FnOnce() -> Fut,
    Fut: std::future::Future<Output = Result<T>>,
{
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    let result = rt.block_on(operation())?;
    Ok(serde_json::to_string(&result)?)
}

/// Helper for asynchronous operations that return nothing
///
/// # Example
/// ```rust
///
/// pub fn start_background_sync() -> Result<()> {
///     command_async(|| async {
///         get_context().sync_service.start().await
///     })
/// }
/// ```
pub fn command_async<F, Fut>(operation: F) -> Result<()>
where
    F: FnOnce() -> Fut,
    Fut: std::future::Future<Output = Result<()>>,
{
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(operation())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::Deserialize;

    #[derive(Debug, Serialize, Deserialize, PartialEq)]
    struct TestData {
        id: i64,
        name: String,
    }

    #[test]
    fn test_query_json_success() {
        let result = query_json(|| {
            Ok(TestData {
                id: 1,
                name: "Test".to_string(),
            })
        });

        assert!(result.is_ok());
        let json = result.unwrap();
        let parsed: TestData = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed.id, 1);
        assert_eq!(parsed.name, "Test");
    }

    #[test]
    fn test_query_json_error() {
        let result: Result<String> =
            query_json(|| Err::<TestData, _>(anyhow::anyhow!("Test error")));

        assert!(result.is_err());
        assert_eq!(result.unwrap_err().to_string(), "Test error");
    }

    #[test]
    fn test_command_with_id_success() {
        let result = command_with_id(|| Ok(42));
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 42);
    }

    #[test]
    fn test_command_success() {
        let result = command(|| Ok(()));
        assert!(result.is_ok());
    }

    #[test]
    fn test_query_json_async_success() {
        let result = query_json_async(|| async {
            Ok(TestData {
                id: 2,
                name: "Async Test".to_string(),
            })
        });

        assert!(result.is_ok());
        let json = result.unwrap();
        let parsed: TestData = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed.id, 2);
        assert_eq!(parsed.name, "Async Test");
    }
}
