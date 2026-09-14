class GoogleRoutesConfig {
  const GoogleRoutesConfig._();

  static const String apiKey = String.fromEnvironment('GOOGLE_ROUTES_API_KEY');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
