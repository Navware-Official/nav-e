//! Smoke tests for the FFI API — the same surface Flutter uses.
//! Run with: `cargo test -p nav_e_ffi`
//!
//! These tests use a temporary database and call nav_e_ffi (not nav_engine
//! directly), so you verify the exact entry points the app uses.
//! Note: APP_CONTEXT is global (OnceLock), so we use a single test that
//! runs all checks after one init.

use nav_e_ffi::{
    delete_device, delete_saved_place, get_all_devices, get_all_saved_places, get_device_by_id,
    get_saved_place_by_id, initialize_database, save_device, save_place,
};

fn test_db_path() -> (tempfile::TempDir, String) {
    let dir = tempfile::tempdir().expect("temp dir");
    let path = dir.path().join("test.db");
    let path_str = path.to_string_lossy().to_string();
    (dir, path_str)
}

#[test]
fn api_smoke_saved_places_and_devices() {
    let (_guard, db_path) = test_db_path();
    initialize_database(db_path).expect("init");

    // --- Saved places ---
    let empty: String = get_all_saved_places().expect("get all");
    assert!(empty == "[]" || empty.trim() == "[]");

    let place_id = save_place(
        "Home".to_string(),
        Some("123 Main St".to_string()),
        52.52,
        13.405,
        Some("test".to_string()),
        None,
        None,
    )
    .expect("save_place");
    assert!(place_id > 0);

    let one: String = get_all_saved_places().expect("get all");
    assert!(one.contains("Home") && one.contains("123 Main St"));
    assert!(get_saved_place_by_id(place_id)
        .expect("get by id")
        .contains("Home"));

    delete_saved_place(place_id).expect("delete");
    assert!(get_all_saved_places().expect("get all").trim() == "[]");

    // --- Devices ---
    let empty_dev: String = get_all_devices().expect("get all");
    assert!(empty_dev == "[]" || empty_dev.trim() == "[]");

    let device_json = r#"{"name":"Test Device","remote_id":"ble-abc","device_type":"wear_os_watch","connection_type":"ble","paired":false}"#.to_string();
    let device_id = save_device(device_json).expect("save_device");
    assert!(device_id > 0);
    assert!(get_all_devices().expect("get all").contains("Test Device"));
    assert!(get_device_by_id(device_id)
        .expect("get by id")
        .contains("Test Device"));

    delete_device(device_id).expect("delete");
    assert!(get_all_devices().expect("get all").trim() == "[]");
}
