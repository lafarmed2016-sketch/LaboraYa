class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ServerException({required this.message, this.statusCode, this.code});
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Sin conexión a internet'});
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Error de caché local'});
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({required this.message, this.code});
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({required this.message, this.fieldErrors});
}
