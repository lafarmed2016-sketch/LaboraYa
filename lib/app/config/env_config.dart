enum Environment { development, staging, production }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String wsBaseUrl;
  final String googleMapsApiKey;
  final String sentryDsn;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.googleMapsApiKey,
    this.sentryDsn = '',
  });

  static const development = EnvConfig(
    environment: Environment.development,
    apiBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    wsBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    googleMapsApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );

  static const staging = EnvConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    wsBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    googleMapsApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );

  static const production = EnvConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    wsBaseUrl: 'https://aplicacioneslafarmed.com:9191',
    googleMapsApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
}
