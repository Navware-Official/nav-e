//! API Playground — HTTP server to try nav_engine endpoints (Storybook-style).
//! Calls through nav_e_ffi so you exercise the same API surface Flutter uses.
//!
//! Run: `cargo run -p api_playground`
//! Then open http://127.0.0.1:3030 in a browser.

use axum::{
    extract::Path,
    response::{Html, IntoResponse},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};

#[derive(Clone)]
struct AppState {
    _db_guard: Arc<tempfile::TempDir>,
}

#[derive(Deserialize)]
struct GeocodeRequest {
    query: String,
    #[serde(default)]
    limit: Option<u32>,
}

#[derive(Deserialize)]
struct ReverseGeocodeRequest {
    lat: f64,
    lon: f64,
}

#[derive(Deserialize)]
struct RouteRequest {
    waypoints: Vec<[f64; 2]>,
}

#[derive(Deserialize)]
struct NavStartRequest {
    waypoints: Vec<[f64; 2]>,
    current_position: [f64; 2],
}

#[derive(Deserialize)]
struct NavUpdateRequest {
    session_id: String,
    lat: f64,
    lon: f64,
}

#[derive(Deserialize)]
struct NavStopRequest {
    session_id: String,
}

#[derive(Deserialize)]
struct SavePlaceRequest {
    name: String,
    address: Option<String>,
    lat: f64,
    lon: f64,
    source: Option<String>,
    type_id: Option<i64>,
    remote_id: Option<String>,
}

#[derive(Serialize)]
struct ApiResponse<T> {
    ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    data: Option<T>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn ok<T: Serialize>(data: T) -> ApiResponse<T> {
    ApiResponse {
        ok: true,
        data: Some(data),
        error: None,
    }
}

fn err<T>(msg: String) -> ApiResponse<T> {
    ApiResponse {
        ok: false,
        data: None,
        error: Some(msg),
    }
}

async fn run_blocking<F, R>(f: F) -> R
where
    F: FnOnce() -> R + Send + 'static,
    R: Send + 'static,
{
    tokio::task::spawn_blocking(f)
        .await
        .expect("blocking task failed")
}

async fn index() -> Html<&'static str> {
    Html(include_str!("playground.html"))
}

async fn api_geocode(Json(req): Json<GeocodeRequest>) -> impl IntoResponse {
    match run_blocking(move || nav_e_ffi::geocode_search(req.query, req.limit)).await {
        Ok(s) => {
            let parsed: Result<serde_json::Value, _> = serde_json::from_str(&s);
            Json(match parsed {
                Ok(v) => ok(v),
                Err(_) => ok(serde_json::json!({ "raw": s })),
            })
        }
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_reverse_geocode(Json(req): Json<ReverseGeocodeRequest>) -> impl IntoResponse {
    match run_blocking(move || nav_e_ffi::reverse_geocode(req.lat, req.lon)).await {
        Ok(s) => Json(ok(serde_json::json!({ "address": s }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_route(Json(req): Json<RouteRequest>) -> impl IntoResponse {
    let waypoints: Vec<(f64, f64)> = req.waypoints.into_iter().map(|[a, b]| (a, b)).collect();
    match run_blocking(move || nav_e_ffi::calculate_route(waypoints)).await {
        Ok(s) => {
            let parsed: Result<serde_json::Value, _> = serde_json::from_str(&s);
            Json(match parsed {
                Ok(v) => ok(v),
                Err(_) => ok(serde_json::json!({ "raw": s })),
            })
        }
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_nav_start(Json(req): Json<NavStartRequest>) -> impl IntoResponse {
    let waypoints: Vec<(f64, f64)> = req.waypoints.into_iter().map(|[a, b]| (a, b)).collect();
    let [lat, lon] = req.current_position;
    match run_blocking(move || nav_e_ffi::start_navigation_session(waypoints, (lat, lon))).await {
        Ok(s) => Json(ok(serde_json::json!({ "session_json": s }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_nav_active() -> impl IntoResponse {
    match run_blocking(nav_e_ffi::get_active_session).await {
        Ok(opt) => Json(ok(serde_json::json!({ "active_session": opt }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_nav_update(Json(req): Json<NavUpdateRequest>) -> impl IntoResponse {
    let session_id = req.session_id;
    let lat = req.lat;
    let lon = req.lon;
    match run_blocking(move || nav_e_ffi::update_navigation_position(session_id, lat, lon)).await {
        Ok(()) => Json(ok(serde_json::json!({ "updated": true }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_nav_stop(Json(req): Json<NavStopRequest>) -> impl IntoResponse {
    let session_id = req.session_id;
    match run_blocking(move || nav_e_ffi::stop_navigation(session_id)).await {
        Ok(()) => Json(ok(serde_json::json!({ "stopped": true }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_saved_places_list() -> impl IntoResponse {
    match run_blocking(nav_e_ffi::get_all_saved_places).await {
        Ok(s) => {
            let v: serde_json::Value = serde_json::from_str(&s).unwrap_or(serde_json::json!(s));
            Json(ok(v))
        }
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_saved_place_get(Path(id): Path<i64>) -> impl IntoResponse {
    match run_blocking(move || nav_e_ffi::get_saved_place_by_id(id)).await {
        Ok(s) => {
            let v: serde_json::Value = serde_json::from_str(&s).unwrap_or(serde_json::json!(s));
            Json(ok(v))
        }
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_saved_place_create(Json(req): Json<SavePlaceRequest>) -> impl IntoResponse {
    let SavePlaceRequest {
        name,
        address,
        lat,
        lon,
        source,
        type_id,
        remote_id,
    } = req;
    match run_blocking(move || {
        nav_e_ffi::save_place(name, address, lat, lon, source, type_id, remote_id)
    })
    .await {
        Ok(id) => Json(ok(serde_json::json!({ "id": id }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_saved_place_delete(Path(id): Path<i64>) -> impl IntoResponse {
    match run_blocking(move || nav_e_ffi::delete_saved_place(id)).await {
        Ok(()) => Json(ok(serde_json::json!({ "deleted": id }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_devices_list() -> impl IntoResponse {
    match run_blocking(nav_e_ffi::get_all_devices).await {
        Ok(s) => {
            let v: serde_json::Value = serde_json::from_str(&s).unwrap_or(serde_json::json!(s));
            Json(ok(v))
        }
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

async fn api_device_create(Json(req): Json<serde_json::Value>) -> impl IntoResponse {
    let body = serde_json::to_string(&req).unwrap_or_else(|_| "{}".to_string());
    match run_blocking(move || nav_e_ffi::save_device(body)).await {
        Ok(id) => Json(ok(serde_json::json!({ "id": id }))),
        Err(e) => Json(err::<serde_json::Value>(e.to_string())),
    }
}

#[tokio::main]
async fn main() {
    let dir = tempfile::tempdir().expect("temp dir");
    let db_path = dir.path().join("playground.db");
    let path_str = db_path.to_string_lossy().to_string();
    nav_e_ffi::initialize_database(path_str).expect("init db");

    let state = AppState {
        _db_guard: Arc::new(dir),
    };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(index))
        .route("/api/geocode", post(api_geocode))
        .route("/api/reverse_geocode", post(api_reverse_geocode))
        .route("/api/route", post(api_route))
        .route("/api/navigation/start", post(api_nav_start))
        .route("/api/navigation/active", get(api_nav_active))
        .route("/api/navigation/update", post(api_nav_update))
        .route("/api/navigation/stop", post(api_nav_stop))
        .route("/api/saved_places", get(api_saved_places_list).post(api_saved_place_create))
        .route("/api/saved_places/:id", get(api_saved_place_get).delete(api_saved_place_delete))
        .route("/api/devices", get(api_devices_list).post(api_device_create))
        .layer(cors)
        .with_state(state);

    let addr = std::net::SocketAddr::from(([127, 0, 0, 1], 3030));
    println!("nav-e API Playground: http://{}/", addr);
    axum::serve(
        tokio::net::TcpListener::bind(addr).await.expect("bind"),
        app,
    )
    .await
    .expect("serve");
}
