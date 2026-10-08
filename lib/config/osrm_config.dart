class OsrmConfig {
  const OsrmConfig._();

  /// Public demonstration server. Replace with managed infrastructure before production.
  static final Uri endpoint = Uri(
    scheme: 'https',
    host: 'router.project-osrm.org',
  );
  // FOSSGIS's documented separate graphs; verified with the public Berlin sample.
  static final Uri walkingEndpoint = Uri.parse(
    'https://routing.openstreetmap.de/routed-foot',
  );
  static final Uri cyclingEndpoint = Uri.parse(
    'https://routing.openstreetmap.de/routed-bike',
  );
}
