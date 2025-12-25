# ADR-0004: Use Nominatim/OpenStreetMap for Geocoding

## Status

**Accepted**

Date: 2025-12-16

## Context

A navigation app requires **geocoding** (converting addresses to coordinates) and **reverse geocoding** (converting coordinates to addresses) for:

- **Search**: Users enter addresses like "123 Main St, Boston" to navigate
- **Place Names**: Display human-readable location names instead of just coordinates
- **Waypoint Input**: Allow entering destinations by name/address
- **Location Sharing**: Share current location as address, not just lat/lon
- **Points of Interest**: Search for businesses, landmarks, etc.

The geocoding service must:

- Support global coverage or at least target markets
- Provide accurate address matching
- Handle fuzzy/partial address input
- Be fast enough for real-time search suggestions
- Be cost-effective at scale
- Respect user privacy
- Work with our OpenStreetMap-based routing

## Decision

We adopt **Nominatim** (the official OpenStreetMap geocoding service) using the public instance at `https://nominatim.openstreetmap.org` for development, with plans to self-host or use Photon for production.

### Implementation Approach

- Implement `NominatimGeocodingService` adapter (aliased as `PhotonGeocodingService` in code)
- Support forward geocoding (address → coordinates)
- Support reverse geocoding (coordinates → address)
- Handle structured and unstructured address queries
- Parse Nominatim's JSON response format
- Rate limit requests to respect Nominatim usage policy (1 req/sec for public instance)

### Hexagonal Architecture Integration

Nominatim is implemented as an **adapter** behind the `GeocodingService` port, enabling:
- Easy migration to Photon, Pelias, or commercial services
- Mock implementations for testing
- Multiple geocoding backends (fallback or comparison)

## Consequences

### Positive

- **Free and Open Source**: No API costs, full source code access
- **Based on OpenStreetMap**: Same data source as our routing (consistent results)
- **Global Coverage**: Worldwide address data from OSM community
- **Self-Hosting Capable**: Can deploy our own Nominatim instance for production
- **Privacy-Friendly**: No tracking or data collection when self-hosted
- **No Vendor Lock-In**: Open source with ODbL license
- **Active Development**: Well-maintained by OSM community
- **Structured Addresses**: Returns detailed address components (street, city, country, etc.)
- **Bounding Box Support**: Can limit searches to specific regions
- **Accept-Language**: Supports multiple languages for address results

### Negative

- **Public Instance Limitations**: Strict rate limiting (1 req/sec) on nominatim.openstreetmap.org
- **Self-Hosting Complexity**: Running Nominatim requires significant resources (100GB+ for full planet database)
- **Search Quality**: Not as sophisticated as commercial services (Google Places, Mapbox)
- **Slower Than Alternatives**: Nominatim can be slower than specialized geocoders like Photon
- **OSM Data Quality**: Address completeness varies by region (better in Europe than some other areas)
- **No Autocomplete**: Nominatim doesn't provide real-time search suggestions (need Photon for that)
- **Resource Intensive**: Full-planet Nominatim requires 16GB+ RAM and fast storage

### Neutral

- **Alternative: Photon**: Can migrate to Photon (Elasticsearch-based OSM geocoder) for faster searches and autocomplete
- **Regional Extracts**: Can deploy region-specific instances to reduce resource requirements
- **Update Frequency**: OSM data freshness depends on update schedule we choose
- **Fuzzy Matching**: Handles typos reasonably but not as well as ML-powered services

## Alternatives Considered

### Alternative 1: Google Places API / Geocoding API

**Description:** Use Google's commercial geocoding and place search APIs

**Pros:**
- Best-in-class search quality
- Extensive place database
- Autocomplete with rich metadata
- High availability with SLA
- Fast response times
- No infrastructure to manage
- Great fuzzy matching and typo tolerance

**Cons:**
- **Cost**: $5 per 1,000 requests for geocoding; $2.83-$17 per 1,000 for autocomplete
- Expensive at scale (10,000 users × 20 searches/day = 200K requests/day = $1,000/day = $30,000/month)
- Vendor lock-in
- Privacy concerns (Google tracks searches)
- Requires internet connectivity
- Terms of service restrictions (must use with Google Maps)

**Why rejected:** Cost prohibitive at scale; TOS requires using Google Maps; privacy concerns

### Alternative 2: Mapbox Geocoding API

**Description:** Use Mapbox's commercial geocoding service

**Pros:**
- High-quality results
- Fast autocomplete
- Integrated with Mapbox services
- Reasonable pricing ($0.50 per 1,000 requests)
- Good developer experience
- Session-based billing for autocomplete

**Cons:**
- Still has ongoing costs (cheaper than Google but adds up)
- Vendor lock-in
- Requires internet connectivity
- Not cost-effective compared to self-hosting at scale

**Why rejected:** Ongoing costs; prefer self-hosting for cost control and privacy

### Alternative 3: Photon

**Description:** Open-source geocoder built on Elasticsearch and OSM data

**Pros:**
- Open source and free
- Much faster than Nominatim (Elasticsearch-based)
- Real-time autocomplete/search-as-you-type
- Self-hostable
- Uses same OSM data as Nominatim
- Lower resource requirements than Nominatim
- Better user experience for search

**Cons:**
- Requires Elasticsearch infrastructure
- More complex to deploy than simple HTTP API
- Less mature than Nominatim
- Smaller community
- Fewer structured address components in responses

**Why rejected (for now):** Starting with Nominatim for simplicity; Photon is primary candidate for production migration when autocomplete becomes priority

### Alternative 4: Pelias

**Description:** Open-source geocoder from Mapzen (now maintained by community)

**Pros:**
- Open source
- Fast (Elasticsearch-based like Photon)
- Supports multiple data sources (OSM, Who's On First, OpenAddresses)
- Autocomplete support
- Self-hostable

**Cons:**
- Complex deployment (multiple services)
- High resource requirements
- Smaller community than Nominatim
- Less documentation
- Requires managing multiple data sources

**Why rejected:** More complexity than needed; Nominatim or Photon are simpler for our use case

### Alternative 5: HERE Geocoding API

**Description:** Commercial geocoding from HERE Technologies

**Pros:**
- High accuracy
- Good international coverage
- Reasonable pricing
- No Google TOS restrictions

**Cons:**
- Ongoing costs
- Vendor lock-in
- Requires internet connectivity
- Not as cost-effective as self-hosting

**Why rejected:** Prefer open-source solution with self-hosting option

## Implementation

- **Implemented in:** feature/navigation-routing branch
- **Affected components:**
  - `native/nav_engine/src/infrastructure/geocoding_adapter.rs` - Nominatim HTTP client
  - Service aliased as `PhotonGeocodingService` (naming suggests future Photon migration)
  - `native/nav_engine/src/domain/ports.rs` - `GeocodingService` port interface
  - Configuration for Nominatim endpoint URL (currently `https://nominatim.openstreetmap.org`)
- **Migration path:**
  1. Phase 1 (Current): Use public Nominatim for development/testing with rate limiting
  2. Phase 2 (Production): Deploy self-hosted Photon instance for faster autocomplete
  3. Phase 3 (Optional): Add Nominatim as fallback for detailed address lookups
  4. Phase 4 (Future): Consider adding commercial API as fallback for critical searches

## References

- [Nominatim Documentation](https://nominatim.org/release-docs/latest/)
- [Nominatim API Reference](https://nominatim.org/release-docs/latest/api/Overview/)
- [Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)
- [Photon Project](https://photon.komoot.io/)
- [Photon on GitHub](https://github.com/komoot/photon)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [Comparison of Geocoders](https://wiki.openstreetmap.org/wiki/Search_engines)

---

## Notes

### Production Deployment Considerations

For production, we should:

1. **Deploy Photon for Autocomplete**: 
   - Faster than Nominatim for real-time search
   - Better user experience
   - Elasticsearch provides powerful search capabilities
   - Docker deployment is straightforward

2. **Rate Limiting**: 
   - Implement aggressive rate limiting on public Nominatim until we self-host
   - Current code should respect 1 req/sec limit

3. **Caching Strategy**:
   - Cache geocoding results locally to reduce API calls
   - Cache reverse geocoding for frequently viewed locations
   - Use local database for common addresses/POIs

4. **Data Updates**:
   - Set up automated OSM data imports for self-hosted geocoder
   - Weekly or monthly updates depending on coverage area

5. **Fallback Strategy**:
   - Consider keeping commercial API as fallback for critical failures
   - Monitor success rates and add fallback if needed

### Code Architecture Note

The code currently uses the alias `PhotonGeocodingService` for the Nominatim implementation, suggesting the developers intended to use Photon from the start or plan to migrate. This is good naming since the adapter pattern makes the swap trivial.

### TODO Mentioned in Code

There's a TODO comment to "use our own Nominatim instance" - this should be prioritized before production launch to avoid rate limiting issues on the public instance.
