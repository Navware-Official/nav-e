# Nav-IR documentation

Nav-IR documentation has moved to a dedicated section.

**See: [Nav-IR (docs/nav-ir/)](../nav-ir/README.md)**

There you will find:

- **What it is** and how to implement (producing and consuming Nav-IR)
- **Concepts** – route, segment, waypoint, instruction, geometry model
- **Schema** – field-level definitions and invariants
- **Versioning** – compatibility rules
- **Normalization** – mapping from [OSRM](../nav-ir/normalization/osrm.md), [GPX](../nav-ir/normalization/gpx.md), and [custom APIs](../nav-ir/normalization/custom-api.md)
- **Examples** – [minimal](../nav-ir/examples/minimal.json), [OSRM-like](../nav-ir/examples/osrm_like.json), [GPX-like](../nav-ir/examples/gpx_like.json) JSON

## Role in the stack (summary)

1. **Route calculation (OSRM)** – The OSRM adapter in nav_core builds a `nav_ir::Route` (single segment, Recalculatable, SnappedToGraph).
2. **Session** – `NavigationSession` in nav_core holds a `nav_ir::Route`.
3. **Device send** – Nav-IR → RouteBlob in `nav_core/src/infrastructure/nav_ir_to_proto.rs`; `prepare_route_message` (JSON → Nav-IR → RouteBlob).
4. **DTO / FFI** – Route DTOs for Flutter from `nav_ir::Route` via `route_to_dto` in `api/dto.rs`.

## Testing

- **Unit tests:** `cargo test -p nav_ir`; `cargo test -p nav_core` (Nav-IR → RouteBlob and DTOs).
- **Manual / E2E:** Call `prepare_route_message` with valid route JSON from the app or FFI tests.

See [Device Communication – Testing Nav-IR](../guides/device-communication.md#testing-nav-ir).
