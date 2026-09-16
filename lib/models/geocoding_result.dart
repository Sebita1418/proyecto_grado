class GeocodingResult {
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
}
