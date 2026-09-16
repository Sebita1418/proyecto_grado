class OsrmConfig {
  const OsrmConfig._();

  /// Public demonstration server. Replace with managed infrastructure before production.
  static final Uri endpoint = Uri(
    scheme: 'https',
    host: 'router.project-osrm.org',
  );
}
