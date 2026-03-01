# Normalizing GPX to Nav-IR

GPX tracks and routes can be imported as fixed geometry. Map them to a Nav-IR **Route** with one or more **segments** and `FixedGeometry` + `ImportedExact` + high confidence.

## Mapping

| GPX concept     | Nav-IR |
|-----------------|--------|
| `<trk>` / `<rte>` | One `Route`. One `RouteSegment` for the whole track/route; all points → one polyline. |
| Segment intent  | `FixedGeometry`. |
| Geometry source | `ImportedExact`. |
| Confidence      | `High` (file is source of truth). |
| Trackpoints / `<rtept>` | Polyline from ordered points; first → Start waypoint, last → Stop waypoint, others → Via. |
| `<name>`, `<desc>` (trk/rte) | `metadata.name`, `metadata.description`. |
| `<cmt>` (trk/rte) | `metadata.source.extras.comment`. |
| Root `creator` attribute | `metadata.source.creator`. |
| `<type>` (trk/rte) | `metadata.source.extras.type`. |
| Distance | Sum of haversine distances between consecutive points → `metadata.total_distance_m`. |
| Duration | Estimated from distance (~15 km/h) → `metadata.estimated_duration_s`. |
| `<rtept>` / track point `<name>`, `<desc>` | Segment waypoint `name`, `description`. |
| `<wpt>` (standalone) | Not merged into route; route uses only track/route points. |

## Guidelines

- **One segment:** Simplest is one segment for the whole track/route; all points → one polyline; first point → Start waypoint, last → Stop waypoint.
- **Multiple segments:** Use one segment per `<trkseg>` if you want to preserve segment boundaries (e.g. for multi-day or mode changes).
- **No turn instructions:** GPX does not provide turn-by-turn steps; leave `instructions` empty or derive them separately if needed.
