import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of [IMapSourceRepository] that manages map sources.
/// Loads map sources from assets/config/map_sources.json.
/// Uses SharedPreferences to persist the currently selected map source.
class MapSourceRepositoryImpl implements IMapSourceRepository {
  static const _configPath = 'assets/config/map_sources.json';
  static const _prefsKey = 'selected_map_source_id';

  List<MapSource> _registry = [];
  Object _currentId = 'osm';
  bool _initialized = false;

  MapSourceRepositoryImpl() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      // Load map sources from JSON
      final jsonString = await rootBundle.loadString(_configPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      _registry = jsonList.map((json) => MapSource.fromJson(json)).toList();

      // Load saved current ID
      await _loadCurrentId();

      _initialized = true;
    } catch (e) {
      // Fallback to default OSM if loading fails
      _registry = [
        const MapSource(
          id: 'osm',
          name: 'OpenStreetMap',
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          maxZoom: 19,
          headers: {'User-Agent': 'nav-e/1.0 (info@navware.org)'},
          attribution: '© OpenStreetMap contributors',
        ),
      ];
      _initialized = true;
    }
  }

  Future<void> _loadCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKey);
    if (savedId != null && _registry.any((s) => s.id == savedId)) {
      _currentId = savedId;
    }
  }

  Future<void> _saveCurrentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }

  @override
  Future<MapSource> getCurrent() async {
    await _initialize();
    return _registry.firstWhere((s) => s.id == _currentId);
  }

  @override
  Future<List<MapSource>> getAll() async {
    await _initialize();
    return _registry;
  }

  @override
  Future<void> setCurrent(String id) async {
    await _initialize();
    if (_registry.any((s) => s.id == id)) {
      _currentId = id;
      await _saveCurrentId(id);
    }
  }
}
