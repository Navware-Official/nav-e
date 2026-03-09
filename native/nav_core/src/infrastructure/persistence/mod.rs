// Persistence adapters: database, base repository, in-memory store.
pub mod base_repository;
pub mod database;
#[cfg(test)]
pub mod in_memory_repo;
