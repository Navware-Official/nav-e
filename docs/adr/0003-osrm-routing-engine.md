# ADR-0003: Choose OSRM as the Routing Engine

## Status

**Accepted**

Date: 2025-12-16

## Context

A navigation application's core functionality depends on calculating efficient routes between locations. The routing engine must:

- **Calculate optimal routes** using road network data
- **Support multiple routing profiles** (car, bike, pedestrian)
- **Handle waypoints** for multi-stop routes
- **Provide turn-by-turn instructions** for navigation
- **Be fast enough** for real-time route calculation
- **Be reliable** with high availability
- **Be cost-effective** for a growing user base
- **Support route alternatives** for user choice
- **Handle route recalculation** when users deviate
- **Respect road restrictions** (one-way streets, turn restrictions, etc.)

We need to decide between self-hosted open-source solutions, commercial APIs, or building our own routing engine.

## Decision

We adopt **OSRM (Open Source Routing Machine)** as our primary routing engine, initially using the public demo instance (`https://router.project-osrm.org`) with plans to self-host for production.

### Implementation Approach

- Use OSRM's HTTP API for route calculation
- Implement `OsrmRouteService` adapter in infrastructure layer
- Support car routing profile initially, with bike/pedestrian planned
- Parse OSRM's route geometry (polyline encoding)
- Convert OSRM maneuvers to our domain `Instruction` value objects
- Implement route recalculation for off-route scenarios

### Hexagonal Architecture Integration

OSRM is implemented as an **adapter** behind the `RouteService` port, allowing us to:
- Swap routing engines without changing domain logic
- Use mock implementations for testing
- Add multiple routing engines (fallback or comparison)
- Migrate to self-hosted OSRM or alternative services

## Consequences

### Positive

- **Free and Open Source**: No API costs, full control over deployment
- **High Performance**: OSRM is written in C++ and highly optimized; can calculate routes in milliseconds
- **Based on OpenStreetMap**: Uses high-quality, community-maintained map data
- **Mature and Battle-Tested**: Used by many production applications (e.g., Mapbox directions)
- **Multiple Routing Profiles**: Supports car, bike, and pedestrian routing
- **Self-Hosting Capable**: Can deploy our own instance for production reliability and privacy
- **Active Development**: Well-maintained with regular updates
- **Good Documentation**: Clear API documentation and examples
- **Scalability**: Can handle thousands of requests per second with proper hardware
- **Offline Capable**: Can be deployed on-device or in private networks
- **No Vendor Lock-In**: Open source with permissive license

### Negative

- **Self-Hosting Complexity**: Running production OSRM requires server infrastructure, monitoring, and maintenance
- **Data Updates**: OSM data needs periodic updates; must manage data pipeline
- **Initial Setup**: Preprocessing OSM data for OSRM takes significant time and disk space
- **Limited Traffic Support**: OSRM doesn't include real-time traffic data (must be added separately)
- **No Official SLA**: Public instance is demo-only; self-hosted has no guaranteed uptime
- **Server Costs**: Self-hosting requires compute resources (though cheaper than commercial APIs at scale)
- **Feature Limitations**: Fewer features than commercial APIs (e.g., no places search, no traffic-aware routing out of the box)

### Neutral

- **API Response Format**: Must parse OSRM-specific response format, but adapter pattern isolates this
- **Polyline Encoding**: OSRM uses polyline encoding for geometry; need decoder library
- **Regional Data**: Can process and deploy specific regions to reduce resource requirements
- **Alternative Algorithms**: OSRM supports multiple algorithms (contraction hierarchies, multi-level Dijkstra)

## Alternatives Considered

### Alternative 1: Google Maps Directions API

**Description:** Use Google's commercial routing API

**Pros:**
- Best-in-class routing quality
- Integrated real-time traffic
- High reliability with SLA
- Global coverage
- Regular data updates
- No infrastructure to manage
- Rich feature set (waypoint optimization, departure time routing)

**Cons:**
- **Cost**: $5 per 1,000 requests; becomes expensive at scale (10,000 daily users × 10 routes = $500/day = $15,000/month)
- Vendor lock-in
- Requires internet connectivity
- Subject to pricing changes
- API rate limits
- Privacy concerns (Google tracks usage)
- Terms of service restrictions

**Why rejected:** Cost would be prohibitive as user base grows; want to maintain control over infrastructure and user privacy

### Alternative 2: Mapbox Directions API

**Description:** Use Mapbox's commercial routing API (based on OSRM and Valhalla)

**Pros:**
- Built on open source (OSRM/Valhalla)
- Good performance
- Integrated with Mapbox maps
- More affordable than Google
- Traffic-aware routing
- Modern API design

**Cons:**
- **Cost**: $0.40-$4 per 1,000 requests depending on plan; still expensive at scale
- Vendor lock-in
- Requires internet connectivity
- Terms of service restrictions
- Not as cost-effective as self-hosting for large volumes

**Why rejected:** Still has ongoing costs; prefer self-hosting for cost control and data sovereignty

### Alternative 3: Valhalla

**Description:** Open-source routing engine from Mapbox (now independent)

**Pros:**
- Open source like OSRM
- Advanced features (time-distance matrices, isochrones)
- Multiple routing profiles
- Good documentation
- Self-hostable

**Cons:**
- More complex to set up than OSRM
- Higher resource requirements
- Smaller community than OSRM
- More recent project (less battle-tested)
- C++ codebase with different architecture

**Why rejected:** OSRM is simpler to deploy and has larger community; Valhalla's extra features not needed initially; can consider for future migration if needed

### Alternative 4: GraphHopper

**Description:** Open-source Java-based routing engine

**Pros:**
- Open source
- Written in Java (easier for some developers)
- Good performance
- Active development
- Commercial support available

**Cons:**
- JVM resource overhead
- Not as fast as OSRM
- Smaller community
- Less documentation than OSRM
- Commercial license for some features

**Why rejected:** OSRM's C++ implementation is faster; larger community and better documentation

### Alternative 5: Build Custom Routing Engine

**Description:** Implement our own routing algorithms (Dijkstra, A*, Contraction Hierarchies)

**Pros:**
- Complete control
- Custom features
- No external dependencies
- Learning opportunity

**Cons:**
- **Massive Development Effort**: Would take months/years to match OSRM quality
- Requires deep expertise in graph algorithms and optimization
- Ongoing maintenance burden
- Must build data preprocessing pipeline
- Unlikely to match OSRM performance
- Diverts resources from core app features

**Why rejected:** Not core to our business; OSRM solves this problem excellently; building routing engine from scratch would delay product launch by months

## Implementation

- **Implemented in:** feature/navigation-routing branch
- **Affected components:**
  - `native/nav_engine/src/infrastructure/osrm_adapter.rs` - OSRM HTTP client and adapter
  - `native/nav_engine/src/domain/ports.rs` - `RouteService` port interface
  - Configuration for OSRM endpoint URL (currently `https://router.project-osrm.org`)
- **Migration path:** 
  1. Phase 1 (Current): Use public OSRM demo instance for development/testing
  2. Phase 2 (Production): Deploy self-hosted OSRM instance with Europe/North America data
  3. Phase 3 (Future): Add CDN/load balancing for routing service, integrate traffic data

## References

- [OSRM Project Website](http://project-osrm.org/)
- [OSRM HTTP API Documentation](https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md)
- [OSRM on GitHub](https://github.com/Project-OSRM/osrm-backend)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [Polyline Encoding Algorithm](https://developers.google.com/maps/documentation/utilities/polylinealgorithm)
- [Comparison of Routing Engines](https://wiki.openstreetmap.org/wiki/Routing/online_routers)

---

## Notes

For production deployment, we will need to:
- Set up OSRM server infrastructure (Docker/Kubernetes)
- Download and preprocess OpenStreetMap data for our target regions
- Implement monitoring and alerting for routing service
- Set up automated OSM data updates (weekly/monthly)
- Consider adding fallback routing services for reliability
- Implement rate limiting on our OSRM instance

The public OSRM demo instance (`router.project-osrm.org`) explicitly states it's for demonstration only and should not be used in production applications.
