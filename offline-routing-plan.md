🏍 Offline Motorcycle Navigation Roadmap
Epic: Offline Motorcycle Navigation Engine & Minimal Vector Maps

Goal: Build a self-contained offline motorcycle routing system with minimal vector maps for the Netherlands, with hybrid/online support and a path to premium rich-data features.

Phase 0 — Research & Preparation

Objective: Understand requirements, OSM data, and tooling.

 Analyze Netherlands OSM extract for motorcycle-relevant roads

 Identify essential road types for routing: motorway, trunk, primary, secondary, tertiary, unclassified, residential

 Evaluate vector tile options for MapLibre (Tilemaker, Tegola)

 Decide Rust-based routing library approach (custom lightweight graph)

Phase 1 — Minimal Map Data & Graph Builder

Objective: Build offline-ready minimal vector tiles and basic routing graph.

 Download OSM Netherlands PBF

 Filter for essential motorcycle-accessible roads

 Build adjacency graph:

Nodes: ID, lat/lon, edge references

Edges: target, weight, optional flags

 Serialize graph into compact binary format

 Generate minimal vector tiles for MapLibre rendering

 Visualize in MapLibre Flutter app

Phase 2 — Core Offline Router (Rust)

Objective: Implement fast A*-based routing engine in Rust.

 Load serialized graph into memory

 Implement A* algorithm with straight-line heuristic

 Weight edges based on “fastest route” per road type

 Implement naive nearest-node snapping

 Return polyline to Flutter for display

Phase 3 — Flutter Integration

Objective: Connect Rust engine with Flutter frontend.

 Expose routing functions via flutter_rust_bridge

 Map start/end coordinates to nearest node

 Display route polyline in MapLibre

 Implement basic hybrid mode (online API fallback)

Phase 4 — Offline Region Management

Objective: Enable hybrid & fully offline mode for region-based usage.

 Design file structure for regions:

/regions/
  netherlands_basic/
    tiles.mbtiles
    graph.bin
  netherlands_premium/
    tiles.mbtiles
    graph.bin


 Implement offline tile caching strategy

 Enable loading/unloading regions dynamically

 Background prefetching of nearby tiles

Phase 5 — Motorcycle-Specific Features

Objective: Add motorcycle-focused optimizations.

 Validate road access rules (motorcycle=yes/no, oneway, roundabouts)

 Tune edge weights for motorcycles

 Support “fastest route” as default

 Future: scenic routes, curvy road preference, avoid highways toggle

Phase 6 — Premium Rich Data Layer (Paid Tier)

Objective: Create differentiable premium features.

 Enrich vector tiles with:

POIs

Landuse

Minor roads

Buildings & labels

 Enhance routing graph with:

Surface type penalties

Elevation & slope

Optional restrictions (avoid ferries, tolls)

 Manage entitlement and premium region access

 Enable incremental updates / delta downloads

Phase 7 — Optimization & Scaling

Objective: Improve performance, storage, and user experience.

 Compress graph binaries

 Geometry simplification for tiles

 Implement R-tree/KD-tree for fast nearest-node lookups

 Multi-threaded routing for faster queries

 Prepare for multi-region Netherlands / other countries

Phase 8 — QA, Testing, and Launch

Objective: Validate correctness and stability.

 Test routing correctness for motorcycles

 Validate offline navigation in hybrid scenarios

 Monitor tile and graph storage size

 Collect edge cases (roundabouts, small streets, highway merges)

 Prepare user onboarding and region download UI