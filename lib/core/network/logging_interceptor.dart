import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger logger;

  LoggingInterceptor({required this.logger});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final safeData = _hidePassword(options.data);
    final safeHeaders = _sanitizeHeaders(options.headers);

    logger.i(
      '''
========== PETICIÓN DIO ==========
Método: ${options.method}
Base URL: ${options.baseUrl}
Path: ${options.path}
URL completa: ${options.uri}
Datos: $safeData
Headers: $safeHeaders
==================================
''',
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    logger.i(
      '''
========== RESPUESTA DIO ==========
Status: ${response.statusCode}
URL: ${response.requestOptions.uri}
runtimeType: ${response.data.runtimeType}
Respuesta: ${response.data}
===================================
''',
    );

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final safeData = _hidePassword(err.requestOptions.data);
    final safeHeaders = _sanitizeHeaders(err.requestOptions.headers);

    logger.e(
      '''
========== ERROR DIO ==========
Tipo: ${err.type}
Mensaje: ${err.message}
Error interno: ${err.error}
URL completa: ${err.requestOptions.uri}
Base URL: ${err.requestOptions.baseUrl}
Path: ${err.requestOptions.path}
Método: ${err.requestOptions.method}
Datos enviados: $safeData
Headers enviados: $safeHeaders
Status code: ${err.response?.statusCode}
Status message: ${err.response?.statusMessage}
Respuesta API: ${err.response?.data}
================================
''',
    );

    handler.next(err);
  }

  dynamic _hidePassword(dynamic data) {
    if (data is Map) {
      final safeData = Map<dynamic, dynamic>.from(data);

      for (final key in safeData.keys.toList()) {
        final normalizedKey = key.toString().toLowerCase();

        if (normalizedKey.contains('contrasena') ||
            normalizedKey.contains('contraseña') ||
            normalizedKey.contains('password')) {
          safeData[key] = '********';
        }
      }

      return safeData;
    }

    return data;
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final safeHeaders = Map<String, dynamic>.from(headers);
    
    if (safeHeaders.containsKey('Authorization')) {
      final auth = safeHeaders['Authorization']?.toString() ?? '';
      if (auth.length > 15) {
        safeHeaders['Authorization'] = '${auth.substring(0, 15)}... (redacted)';
      } else {
        safeHeaders['Authorization'] = '******** (redacted)';
      }
    }
    
    if (safeHeaders.containsKey('authorization')) {
      final auth = safeHeaders['authorization']?.toString() ?? '';
      if (auth.length > 15) {
        safeHeaders['authorization'] = '${auth.substring(0, 15)}... (redacted)';
      } else {
        safeHeaders['authorization'] = '******** (redacted)';
      }
    }
    
    return safeHeaders;
  }
}
