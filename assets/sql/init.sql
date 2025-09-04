CREATE TABLE IF NOT EXISTS devices (
  id INTEGER PRIMARY KEY,
  name TEXT,
  model TEXT,
  remote_id TEXT
);

CREATE TABLE IF NOT EXISTS search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  address TEXT NOT NULL,
  lat REAL,
  lng REAL,
  timestamp INTEGER
);

CREATE TABLE places_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT UNIQUE
);

CREATE TABLE saved_places (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER,               -- FK to places_types (Home, Work, etc.)
  source TEXT NOT NULL,          -- "osm", "google", "custom"
  remote_id TEXT,                -- provider’s place_id / osm_id / etc.
  name TEXT NOT NULL,
  address TEXT,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (type_id) REFERENCES places_types(id)
);

CREATE TABLE saved_places_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  FOREIGN KEY (place_id) REFERENCES saved_places(id) ON DELETE CASCADE
);
