class AppConfig {
  static const String appName = 'LaboraYa';
  static const String appSlogan = 'Encuentra trabajo cerca de ti';
  static const String applicationId = 'com.laboraya.app';
  static const String defaultLocale = 'es';
  static const String defaultCountry = 'PE';
  static const String defaultCurrency = 'PEN';
  static const String currencySymbol = 'S/';
  static const String defaultTimezone = 'America/Lima';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Map
  static const double defaultLatitude = -12.0464;
  static const double defaultLongitude = -77.0428;
  static const double defaultZoom = 14.0;
  static const double defaultSearchRadiusKm = 10.0;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
  static const int maxPhotosPerJob = 10;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Rate Limiting
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Cache
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
