import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final apiClient = ref.read(apiClientProvider);
  return RealAuthService(storage: storage, apiClient: apiClient);
});

abstract class AuthService {
  Future<bool> login({required String email, required String password});
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String userType,
  });
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<void> forgotPassword(String email);
  Future<bool> refreshToken();
  Future<void> changePassword(String newPassword);
}

class RealAuthService implements AuthService {
  final SecureStorage storage;
  final ApiClient apiClient;

  RealAuthService({required this.storage, required this.apiClient});

  @override
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.login,
        data: {
          'Usuario': email.trim(),
          'Contrasena': password,
        },
      );

      final dynamic rawData = response.data;

      print('STATUS LOGIN: ${response.statusCode}');
      print('TIPO RESPUESTA LOGIN: ${rawData.runtimeType}');
      print('RESPUESTA LOGIN: "$rawData"');

      if (rawData == null ||
          (rawData is String && rawData.trim().isEmpty)) {
        throw Exception(
          'El servidor respondió vacío. No se pudo validar el usuario.',
        );
      }

      if (rawData is! Map) {
        throw Exception(
          'El servidor devolvió un formato inesperado: '
          '${rawData.runtimeType}',
        );
      }

      final data = Map<String, dynamic>.from(rawData);

      final codigo = data['codigoRespuesta']?.toString();

      if (codigo != '0') {
        final mensaje = data['mensaje'] ?? 'Usuario o contraseña incorrectos.';
        throw Exception(mensaje.toString());
      }

      final dynamic rawAuthData = data['datos'] ?? data['data'] ?? data;

      if (rawAuthData == null || rawAuthData is! Map) {
        throw Exception('El servidor no devolvió los datos del usuario.');
      }

      final authData = Map<String, dynamic>.from(rawAuthData);

      if (authData['estado'] != true) {
        throw Exception('El usuario no está activo.');
      }

      final token = authData['tokenLogeo']?.toString();
      final userId = authData['id']?.toString();
      final username = authData['usuario']?.toString();

      if (token == null || token.trim().isEmpty) {
        throw Exception('El servidor validó el usuario, pero no devolvió un token.');
      }

      await storage.saveAccessToken(token);
      // Solo guardar en RefreshToken si también se necesita como fallback
      // await storage.saveRefreshToken(token); 
      
      if (userId != null && userId.isNotEmpty) {
        await storage.saveUserId(userId);
      }
      if (username != null && username.isNotEmpty) {
        await storage.saveUsername(username);
      }

      return true;
    } on DioException {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.register,
        data: {
          'Usuario': email.trim(),
          'Contrasena': password,
          'Nombres': firstName.trim(),
          'Apellidos': lastName.trim(),
          'Correo': email.trim(),
          'Telefono': phone.trim(),
          'TipoUsuario': userType,
        },
      );

      final statusCode = response.statusCode ?? 0;
      final dynamic rawData = response.data;

      print('STATUS REGISTRO: $statusCode');
      print('TIPO RESPUESTA: ${rawData.runtimeType}');
      print('RESPUESTA REGISTRO: "$rawData"');

      // La API respondió correctamente, pero sin contenido.
      if (statusCode >= 200 && statusCode < 300) {
        if (rawData == null || (rawData is String && rawData.trim().isEmpty)) {
          throw Exception('La API respondió vacía. No se pudo confirmar la creación de la cuenta.');
        }

        if (rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          final codigo = data['codigoRespuesta']?.toString();

          if (codigo == '0') {
            // Auto login after successful registration
            try {
              await login(email: email, password: password);
            } catch (e) {
              print('Auto-login failed after registration: $e');
              // We still return true because registration succeeded, 
              // but you could also throw here if you want to fail the whole process.
            }
            return true;
          } else {
            final mensaje = data['mensaje'] ?? 'No se pudo crear la cuenta.';
            throw Exception(mensaje.toString());
          }
        }
      }

      throw Exception(
        'No se pudo crear la cuenta. Código HTTP: $statusCode',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al registrar usuario: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshTokenValue = await storage.getRefreshToken();
      if (refreshTokenValue != null) {
        await apiClient.post(
          ApiConstants.logout,
          data: {'refreshToken': refreshTokenValue},
        );
      }
    } catch (_) {}
    await storage.clearAll();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await storage.hasToken();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await apiClient.post(
      ApiConstants.login
          .replaceAll('/Login', '/RecuperarClave')
          .replaceAll('/login', '/forgot-password'),
      data: {'Correo': email, 'email': email},
    );
  }

  @override
  Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = await storage.getRefreshToken();
      if (refreshTokenValue == null) return false;

      final response = await apiClient.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshTokenValue},
      );

      final data = response.data;
      final isSuccess =
          data['codigoRespuesta'] == '0' ||
          data['codigoRespuesta'] == 0 ||
          data['success'] == true;
      if (isSuccess) {
        final authData = data['datos'] ?? data['data'] ?? data;
        final token = (authData['token'] ?? authData['Token'] ?? authData['accessToken'])?.toString();
        if (token != null) {
          await storage.saveAccessToken(token);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await apiClient.post(
      ApiConstants.changePassword,
      data: {'newPassword': newPassword, 'NuevaClave': newPassword},
    );
  }
}
