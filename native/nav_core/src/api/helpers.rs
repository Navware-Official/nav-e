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
/// use nav_core::api::query_json;
/// use anyhow::Result;
/// # fn run() -> Result<()> {
/// let _json = query_json(|| Ok::<_, anyhow::Error>(vec!["place1".to_string()]))?;
/// # Ok(())
/// # }
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
/// use nav_core::api::command_with_id;
/// use anyhow::Result;
/// # fn run() -> Result<()> {
/// let _id = command_with_id(|| Ok(1i64))?;
/// # Ok(())
/// # }
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
/// use nav_core::api::command;
/// use anyhow::Result;
/// # fn run() -> Result<()> {
/// command(|| Ok(()))?;
/// # Ok(())
/// # }
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
/// use nav_core::api::query_json_async;
/// use anyhow::Result;
/// # fn run() -> Result<()> {
/// let _json = query_json_async(|| async { Ok::<_, anyhow::Error>(vec!["route".to_string()]) })?;
/// # Ok(())
/// # }
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
/// use nav_core::api::command_async;
/// use anyhow::Result;
/// # fn run() -> Result<()> {
/// command_async(|| async { Ok(()) })?;
/// # Ok(())
/// # }
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
