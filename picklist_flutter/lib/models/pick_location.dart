class PickLocation {
  final String id;
  final String name;
  final int totalPicks;

  PickLocation({
    required this.id,
    required this.name,
    required this.totalPicks,
  });
}

// Dummy data for locations
final List<PickLocation> dummyLocations = [
  PickLocation(id: 'c3f', name: 'C3-Front', totalPicks: 15),
  PickLocation(id: 'c3b', name: 'C3-Back', totalPicks: 12),
  PickLocation(id: 'c3c', name: 'C3-Crocs', totalPicks: 8),
  PickLocation(id: 'c3s', name: 'C3-Shop', totalPicks: 10),
  PickLocation(id: 'c1', name: 'C1', totalPicks: 20),
];
