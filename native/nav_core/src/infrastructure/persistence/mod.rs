// Persistence adapters: database, base repository, in-memory store.
pub mod base_repository;
pub mod database;
#[cfg(test)]
pub mod in_memory_repo;
pub mod sqlite_navigation_repo;

pub use sqlite_navigation_repo::SqliteNavigationRepository;
