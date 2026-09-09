import 'package:dio/dio.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorage storage;
  bool _isRefreshing = false;

  AuthInterceptor({required this.dio, required this.storage});

  static const String hardcodedV2Token = 'S0p0rteLafarmed2026\$App';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    final isV2 = options.path.contains('/v2/') || options.path.contains('v2');
    final isPublicAuthEndpoint = options.path.contains('/UsuarioV2/Login') ||
        options.path.contains('/UsuarioV2/Registrar') ||
        options.path.contains('/UsuarioV2/RefreshToken') ||
        options.path.contains('/UsuarioV2/RecuperarClave');

    if (isPublicAuthEndpoint) {
      options.headers['Authorization'] = 'Bearer $hardcodedV2Token';
    } else if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else if (isV2) {
      // Fallback para consultas públicas como Categorias o Buscar Trabajos sin sesión
      options.headers['Authorization'] = 'Bearer $hardcodedV2Token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken == null) {
          await storage.clearTokens();
          handler.next(err);
          return;
        }

        final response = await dio.post(
          '/api/v2/UsuarioV2/RefreshToken',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final authData = data['datos'] ?? data['data'] ?? data;
          final newAccessToken = (authData['token'] ??
              authData['Token'] ??
              authData['accessToken'] ??
              authData['AccessToken'])?.toString();
          final newRefreshToken = (authData['refreshToken'] ??
              authData['RefreshToken'])?.toString() ?? refreshToken;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await storage.saveAccessToken(newAccessToken);
            await storage.saveRefreshToken(newRefreshToken);

            // Retry original request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(opts);
            handler.resolve(retryResponse);
            return;
          }
        }
        await storage.clearTokens();
        handler.next(err);
      } catch (e) {
        await storage.clearTokens();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
