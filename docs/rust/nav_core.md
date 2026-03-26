# nav_core

Core navigation engine: domain, application (CQRS), infrastructure adapters, and API surface for nav_e_ffi.

## Layout

- **`src/domain/`** – Entities, value objects, ports, events (no external deps).
- **`src/application/`** – Commands, queries, handlers (CQRS).
- **`src/infrastructure/`** – Adapters grouped by type:
  - **persistence/** – database, base_repository, in_memory_repo
  - **routing/** – osrm_adapter
  - **geocoding/** – geocoding_adapter
  - **device/** – nav_ir_to_proto, protobuf_adapter
- **`src/api/`** – Feature API used by nav_e_ffi:
  - **context.rs** – AppContext, initialize_database, get_context
  - **dto.rs**, **helpers.rs** – shared types and helpers
  - **device/** – device_comm, devices
  - **places/** – saved_places, saved_routes, trips
  - **navigation/** – navigation (session), routes (calculate_route)
  - **geocoding.rs**, **offline_regions.rs**
- **`src/migrations/`** – SQLite migrations.

## Adding code

- **New API** – Add or extend modules under `src/api/` (by feature), then expose in nav_e_ffi.
- **New adapter** – Add under the appropriate `src/infrastructure/` subfolder and re-export from the parent `mod.rs`.
