# nav_route

HTTP routing and geocoding service implementations for `nav_core` ports.

This crate is the adapter layer between `nav_core`'s port interfaces and external HTTP services (OSRM for routing, Nominatim for geocoding). It isolates all HTTP client dependencies so that `nav_core` itself remains free of network concerns.

## Architecture

`nav_route` sits in the infrastructure layer of the hexagonal architecture:

```
nav_e_ffi
  └── nav_route          ← this crate (HTTP adapters)
        ├── OsrmRouteService       implements nav_core::RouteService
        └── NominatimGeocodingService  implements nav_core::GeocodingService
  └── nav_core           ← port interfaces + domain logic
  └── nav_ir             ← canonical route format (NavIrRoute)
```

`nav_e_ffi` constructs the services, wraps them in `Arc<T>`, and injects them into `nav_core` via `initialize_database()`. Neither `nav_core` nor `nav_ir` depend on `reqwest` directly.

## Features

| Feature | Default | Description |
|---|---|---|
| `osrm` | ✓ | OSRM routing via `OsrmRouteService` |
| `nominatim` | ✓ | Nominatim geocoding via `NominatimGeocodingService` |

Both features are enabled by default. Disable them individually if you only need one service or are substituting your own implementation.

```toml
# Both services (default)
nav_route = { path = "../nav_route" }

# Routing only
nav_route = { path = "../nav_route", default-features = false, features = ["osrm"] }
```

## Services

### `OsrmRouteService`

Implements `nav_core::RouteService` using the [OSRM](http://project-osrm.org/) HTTP API.

```rust
use nav_route::OsrmRouteService;

let service = OsrmRouteService::new(
    "https://router.project-osrm.org".to_string(),
);
```

**Constructor**

```rust
pub fn new(base_url: String) -> Self
```

Creates a service pointed at the given OSRM base URL. A default `reqwest::Client` is constructed internally with a 10-second request timeout.

**Trait methods (via `nav_core::RouteService`)**

```rust
async fn calculate_route(
    &self,
    waypoints: Vec<nav_core::Position>,
) -> anyhow::Result<NavIrRoute>

async fn recalculate_from_position(
    &self,
    route: &NavIrRoute,
    current_position: nav_core::Position,
) -> anyhow::Result<NavIrRoute>
```

**HTTP details**

- Endpoint: `GET {base_url}/route/v1/driving/{lon,lat;lon,lat;...}`
- Query parameters: `overview=full&geometries=polyline`
- Response is passed directly to `nav_ir::normalize_osrm()` which converts it to a `NavIrRoute`

---

### `NominatimGeocodingService`

Implements `nav_core::GeocodingService` using the [Nominatim](https://nominatim.org/) (OpenStreetMap) geocoding API.

```rust
use nav_route::NominatimGeocodingService;

let service = NominatimGeocodingService::new(
    "https://nominatim.openstreetmap.org".to_string(),
);
```

A type alias `PhotonGeocodingService` is also exported for backward compatibility — it is the same type.

**Constructor**

```rust
pub fn new(base_url: String) -> Self
```

Creates a service pointed at the given Nominatim base URL. A `reqwest::Client` is built with the user-agent `"NavE Navigation App/1.0"` as required by the Nominatim usage policy.

**Trait methods (via `nav_core::GeocodingService`)**

```rust
async fn geocode(
    &self,
    address: &str,
    limit: Option<u32>,
) -> anyhow::Result<Vec<GeocodingSearchResult>>

async fn reverse_geocode(
    &self,
    position: Position,
) -> anyhow::Result<String>
```

**HTTP details**

- Forward geocode: `GET {base_url}/search?q={encoded_query}&format=json&limit={n}&addressdetails=1`
  - Default limit: 10 results when `None` is passed
  - Address query is URL-encoded with `urlencoding::encode()`
- Reverse geocode: `GET {base_url}/reverse?lat={lat}&lon={lon}&format=json`
  - Returns a human-readable address string
  - Fallback: returns `"{lat:.6}, {lon:.6}"` if address parsing fails

## Initialization (in `nav_e_ffi`)

```rust
use std::sync::Arc;

let route_service = Arc::new(nav_route::OsrmRouteService::new(
    "https://router.project-osrm.org".to_string(),
));
let geocoding_service = Arc::new(nav_route::NominatimGeocodingService::new(
    "https://nominatim.openstreetmap.org".to_string(),
));

nav_core::api::initialize_database(db_path, route_service, geocoding_service).await?;
```

Both `Arc<OsrmRouteService>` and `Arc<NominatimGeocodingService>` satisfy the `Send + Sync` bounds required by `nav_core`'s port traits.

## Error Handling

All public methods return `anyhow::Result<T>`. Errors include context messages for diagnosis:

| Service | Error | Cause |
|---|---|---|
| OSRM | `"Failed to send OSRM request"` | Network / connectivity |
| OSRM | `"OSRM returned error status: {body}"` | Non-2xx HTTP response |
| OSRM | `"Failed to read OSRM response body"` | Response body unreadable |
| OSRM | `"OSRM normalization failed: {e}"` | `nav_ir::normalize_osrm()` rejected the response |
| Nominatim | `"Failed to send geocoding request"` | Network / connectivity |
| Nominatim | `"Failed to parse geocoding response"` | JSON deserialization failed |

## Dependencies

```toml
nav_core    = { path = "../nav_core" }
nav_ir      = { path = "../nav_ir" }
anyhow      = "1"
async-trait = "0.1"
serde_json  = "1"

# Optional (feature-gated)
reqwest     = { version = "0.12", features = ["json", "gzip", "rustls-tls"] }
urlencoding = "2"
```

`reqwest` is built with `rustls-tls` (no native TLS dependency) and gzip response decompression enabled.

## Crate layout

```
native/nav_route/
├── Cargo.toml
└── src/
    ├── lib.rs              # Public re-exports
    ├── osrm/
    │   └── mod.rs          # OsrmRouteService
    └── geocoding/
        └── mod.rs          # NominatimGeocodingService
```
