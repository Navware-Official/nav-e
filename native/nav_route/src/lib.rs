// nav_route — HTTP service implementations for nav_core's RouteService and GeocodingService ports.
//
// nav_e_ffi creates these types and injects them into nav_core via initialize_database,
// keeping reqwest out of nav_core itself.

#[cfg(feature = "osrm")]
pub mod osrm;
#[cfg(feature = "osrm")]
pub use osrm::OsrmRouteService;

#[cfg(feature = "nominatim")]
pub mod geocoding;
#[cfg(feature = "nominatim")]
pub use geocoding::{NominatimGeocodingService, PhotonGeocodingService};

#[cfg(feature = "google_routes")]
pub mod google_routes;
#[cfg(feature = "google_routes")]
pub use google_routes::GoogleRoutesService;

#[cfg(feature = "valhalla")]
pub mod valhalla;
#[cfg(feature = "valhalla")]
pub use valhalla::ValhallaRouteService;

#[cfg(feature = "multi")]
pub mod multi;
#[cfg(feature = "multi")]
pub use multi::MultiRouteService;
