import 'package:dio/dio.dart';
import 'package:laboraya_app/core/errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(
          message: 'La conexión ha tardado demasiado',
        );
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        _handleBadResponse(err);
      default:
        break;
    }
    handler.next(err);
  }

  void _handleBadResponse(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    String message = 'Error del servidor';
    String? code;
    Map<String, String>? fieldErrors;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;
      code = data['code'] as String?;

      if (data['errors'] is List) {
        fieldErrors = {};
        for (final error in data['errors'] as List) {
          if (error is Map<String, dynamic>) {
            final field = error['field'] as String?;
            final msg = error['message'] as String?;
            if (field != null && msg != null) {
              fieldErrors[field] = msg;
            }
          }
        }
      }
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(message: message, fieldErrors: fieldErrors);
      case 401:
        throw AuthException(message: message, code: code);
      case 403:
        throw AuthException(
          message: 'No tienes permisos para esta acción',
          code: 'FORBIDDEN',
        );
      case 404:
        throw ServerException(
          message: 'Recurso no encontrado',
          statusCode: 404,
          code: code,
        );
      case 422:
        throw ValidationException(message: message, fieldErrors: fieldErrors);
      case 429:
        throw const ServerException(
          message: 'Demasiadas solicitudes. Intenta más tarde',
          statusCode: 429,
          code: 'RATE_LIMITED',
        );
      case 500:
      case 502:
      case 503:
        throw ServerException(
          message: 'Error interno del servidor',
          statusCode: statusCode,
          code: code,
        );
      default:
        throw ServerException(
          message: message,
          statusCode: statusCode,
          code: code,
        );
    }
  }
}
