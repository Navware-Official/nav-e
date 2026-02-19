# nav-e API Playground

A **Storybook-style** local server to test nav_engine Rust endpoints without running the Flutter app. It calls through **nav_e_ffi** (the same package Flutter uses), so you exercise the exact API surface the app uses.

## Run

```bash
# From repo root
cargo run -p api_playground

# Or from native/
cd native && cargo run -p api_playground
```

Then open **http://127.0.0.1:3030** in your browser.

## What it does

- Uses a **temporary database** (no setup; data is lost when you stop the server).
- Exposes the same API surface as the FFI (geocoding, routes, navigation, saved places, devices) over HTTP.
- Single HTML page with sections for each endpoint: fill inputs, click **Run**, see JSON result.

## Endpoints (HTTP → nav_e_ffi)

| Section        | Method | Path                    | Body / params                    |
|----------------|--------|-------------------------|-----------------------------------|
| Geocode        | POST   | `/api/geocode`          | `{ "query", "limit"? }`           |
| Reverse geocode| POST   | `/api/reverse_geocode`   | `{ "lat", "lon" }`                |
| Route          | POST   | `/api/route`            | `{ "waypoints": [[lat,lon],...] }`|
| Nav start      | POST   | `/api/navigation/start` | `{ "waypoints", "current_position" }` |
| Nav active     | GET    | `/api/navigation/active`| —                                 |
| Nav update     | POST   | `/api/navigation/update`| `{ "session_id", "lat", "lon" }`  |
| Nav stop       | POST   | `/api/navigation/stop`   | `{ "session_id" }`                |
| Saved places   | GET    | `/api/saved_places`      | —                                 |
| Saved place    | POST   | `/api/saved_places`      | `{ "name", "address?", "lat", "lon" }` |
| Saved place    | GET/DELETE | `/api/saved_places/:id` | —                              |
| Devices        | GET    | `/api/devices`          | —                                 |
| Device         | POST   | `/api/devices`          | JSON device object                |

## Rust-only tests (no server)

To test the FFI API from the command line without the playground:

```bash
cargo test -p nav_e_ffi
```

See `nav_e_ffi/tests/api_smoke_test.rs` for examples.
