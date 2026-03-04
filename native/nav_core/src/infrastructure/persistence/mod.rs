// Persistence adapters: database, base repository, in-memory store.
pub mod base_repository;
pub mod database;
pub mod in_memory_repo;

pub use base_repository::*;
pub use database::*;
pub use in_memory_repo::*;
