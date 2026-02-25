# Normalizing OSRM output to Nav-IR

OSRM returns a route with geometry (polyline), legs/steps, and duration/distance. Map it to a single Nav-IR **Route** with one **segment** per OSRM route (typical case).

## Mapping

| OSRM concept        | Nav-IR |
|---------------------|--------|
| Route               | One `Route`; one `RouteSegment`. |
| Segment intent      | `Recalculatable` (engine can recalc). |
| Geometry source     | `SnappedToGraph`. |
| Overview geometry   | Decode to points; encode as Nav-IR `polyline` (e.g. Google polyline). |
| Input waypoints     | Map to `Waypoint` with kinds: first → `Start`, last → `Stop`, others → `Via`. |
| Distance / duration | `metadata.total_distance_m`, `metadata.estimated_duration_s`. |
| Steps (optional)    | Map to `Instruction` (coordinate, kind, distance_to_next_m, street_name). |

## Implementation

The nav-e OSRM adapter lives in `native/nav_core/src/infrastructure/osrm_adapter.rs`. It:

- Calls OSRM `route/v1/driving/{coords}` with `overview=full&geometries=polyline&steps=true`.
- Builds one `nav_ir::Route` with one `RouteSegment` (intent `Recalculatable`, geometry source `SnappedToGraph`).
- Fills waypoints from the request (Start, Via, Stop); polyline from OSRM geometry; metadata from route distance/duration.

Use that adapter as the reference for OSRM → Nav-IR normalization.
