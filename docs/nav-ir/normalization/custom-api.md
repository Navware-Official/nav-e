# Normalizing a custom API or engine to Nav-IR

To support your own routing engine or custom API, produce a Nav-IR **Route** (e.g. as `nav_ir::Route` in Rust or equivalent JSON). The same schema and pipeline (Nav-IR → RouteBlob → device) then apply.

## Choosing intent and geometry source

- **Live routing engine (like OSRM):** Use `SegmentIntent::Recalculatable` and `GeometrySource::SnappedToGraph` (or `Recalculated` if you recalc on the fly). One segment per route is typical.
- **Precomputed or imported route:** Use `SegmentIntent::FixedGeometry` and `GeometrySource::ImportedExact` (or `Recalculated` if you generated it). Set `GeometryConfidence::High` when the geometry is authoritative.
- **Advisory/suggested track:** Use `SegmentIntent::AdvisoryTrack` and an appropriate geometry source.

## What to fill

1. **Route** – `schema_version: 1`, new `id`, `metadata` (name, timestamps, optional total distance/duration), `segments`, `policies` (defaults are fine).
2. **Segment(s)** – At least one. Per segment: `intent`, `geometry` (polyline, source, confidence, bounding_box), `waypoints` (at least Start and Stop), optional `instructions`, `constraints` (defaults ok).
3. **Waypoints** – Ordered; coordinate + kind (Start, Stop, Via, etc.); optional `radius_m`.
4. **Geometry** – Encode your shape as a polyline string (e.g. Google polyline); compute bounding box from points.

## References

- [Schema](../schema.md) – Field-level types and invariants.
- [Examples](../examples/) – `minimal.json`, `osrm_like.json`, `gpx_like.json` for patterns.

Once your engine outputs a valid Nav-IR Route, nav_core can store it in a session and send it to the device via the existing Nav-IR → RouteBlob path.
