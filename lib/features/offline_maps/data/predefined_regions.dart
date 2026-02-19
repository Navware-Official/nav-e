/// Bbox result for region selection (list or map).
class SelectedRegionBbox {
  const SelectedRegionBbox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
  final double north;
  final double south;
  final double east;
  final double west;
}

/// A predefined region with name and bounding box.
class PredefinedRegion {
  const PredefinedRegion({
    required this.name,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
  final String name;
  final double north;
  final double south;
  final double east;
  final double west;

  SelectedRegionBbox get bbox =>
      SelectedRegionBbox(north: north, south: south, east: east, west: west);
}

/// Predefined regions the user can pick from when adding an offline map.
const List<PredefinedRegion> predefinedRegions = [
  PredefinedRegion(
    name: 'Netherlands',
    north: 53.7,
    south: 50.7,
    east: 7.2,
    west: 3.3,
  ),
  PredefinedRegion(
    name: 'Belgium',
    north: 51.6,
    south: 49.5,
    east: 6.4,
    west: 2.5,
  ),
  PredefinedRegion(
    name: 'Berlin',
    north: 52.7,
    south: 52.3,
    east: 13.9,
    west: 13.1,
  ),
  PredefinedRegion(
    name: 'Bavaria',
    north: 50.5,
    south: 47.2,
    east: 13.8,
    west: 8.9,
  ),
  PredefinedRegion(
    name: 'Rhine-Ruhr',
    north: 52.0,
    south: 50.8,
    east: 8.2,
    west: 6.1,
  ),
  PredefinedRegion(
    name: 'Île-de-France',
    north: 49.2,
    south: 48.1,
    east: 3.6,
    west: 1.4,
  ),
  PredefinedRegion(
    name: 'Switzerland',
    north: 47.8,
    south: 45.8,
    east: 10.5,
    west: 5.9,
  ),
  PredefinedRegion(
    name: 'Austria',
    north: 49.0,
    south: 46.4,
    east: 17.2,
    west: 9.5,
  ),
];
