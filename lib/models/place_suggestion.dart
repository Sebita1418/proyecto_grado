class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String description;
  final double latitude;
  final double longitude;

  String get displayText => description.isEmpty ? name : '$name, $description';
}
