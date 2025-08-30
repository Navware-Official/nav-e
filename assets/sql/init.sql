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

CREATE TABLE IF NOT EXISTS saved_places (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT, 
  address TEXT NOT NULL,
  lat REAL,
  lon REAL
);

CREATE TABLE IF NOT EXISTS saved_places_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id INTEGER,
  tag TEXT,
  FOREIGN KEY (place_id) REFERENCES saved_places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS places_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT UNIQUE
);

INSERT OR IGNORE INTO places_types (type) VALUES 
('Home'),
('Work'),
('Gym'),
('School'),
('Favorite'),
('Other');

INSERT INTO saved_places_tags (place_id, tag) VALUES
(1, 'Favorite'),
(1, 'Gym'),
(2, 'Work');