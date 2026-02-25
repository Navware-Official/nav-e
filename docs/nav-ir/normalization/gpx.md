# Normalizing GPX to Nav-IR

GPX tracks and routes can be imported as fixed geometry. Map them to a Nav-IR **Route** with one or more **segments** and `FixedGeometry` + `ImportedExact` + high confidence.

## Mapping

| GPX concept     | Nav-IR |
|-----------------|--------|
| `<trk>` / `<rte>` | One `Route`. One `RouteSegment` per track, or one per `<rtept>` segment, or one for the whole track (your choice). |
| Segment intent  | `FixedGeometry`. |
| Geometry source | `ImportedExact`. |
| Confidence      | `High` (file is source of truth). |
| Trackpoints / route points | Build polyline from ordered points; encode as Nav-IR `polyline`. Optionally treat first/last as waypoints. |
| `<name>`, `<desc>` (trk/rte) | `metadata.name`, `metadata.description`. |
| `<wpt>` (standalone) | Optional waypoints (e.g. Via or Poi) if you associate them with the route. |

## Guidelines

- **One segment:** Simplest is one segment for the whole track/route; all points → one polyline; first point → Start waypoint, last → Stop waypoint.
- **Multiple segments:** Use one segment per `<trkseg>` if you want to preserve segment boundaries (e.g. for multi-day or mode changes).
- **No turn instructions:** GPX does not provide turn-by-turn steps; leave `instructions` empty or derive them separately if needed.
