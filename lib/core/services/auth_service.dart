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
  Future<bool> loginWithGoogleAccount({
    required String email,
    required String googleId,
    required String displayName,
  });
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
        final mensaje = data['mensaje']?.toString().trim();
        throw Exception(
          (mensaje != null && mensaje.isNotEmpty)
              ? mensaje
              : 'Usuario o contraseña incorrectos.',
        );
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
      // El backend puede devolver el ID con distintos nombres
      final userId = (
        authData['id'] ??
        authData['Id'] ??
        authData['usuarioId'] ??
        authData['UsuarioId'] ??
        authData['userId'] ??
        authData['UserId']
      )?.toString();
      final username = (
        authData['usuario'] ??
        authData['Usuario'] ??
        authData['username'] ??
        authData['Username'] ??
        authData['correo'] ??
        authData['Correo']
      )?.toString();

      if (token == null || token.trim().isEmpty) {
        throw Exception('El servidor validó el usuario, pero no devolvió un token.');
      }

      await storage.saveAccessToken(token);

      if (userId != null && userId.isNotEmpty && userId != '0') {
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
  Future<bool> loginWithGoogleAccount({
    required String email,
    required String googleId,
    required String displayName,
  }) async {
    final names = displayName.trim().split(' ');
    final firstName = names.isNotEmpty ? names.first : 'Usuario';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Google';

    try {
      // Intentar login primero (usuario ya existe)
      return await login(email: email, password: googleId);
    } catch (_) {
      // Usuario nuevo: registrar (esto también crea el registro en personas)
      return await register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: '999999999',
        password: googleId,
        userType: 'Cliente',
      );
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
            }

            // Crear el registro en tabla personas inmediatamente después del registro
            // Esto es necesario porque el endpoint /Registrar solo crea en tabla usuarios
            try {
              await apiClient.put(
                ApiConstants.userProfile,
                data: {
                  'Nombres': firstName.trim(),
                  'Apellidos': lastName.trim(),
                  'Correo': email.trim(),
                  'Telefono': phone.trim(),
                  'Distrito': '',
                  'Descripcion': '',
                  'PrecioHora': 0,
                  'firstName': firstName.trim(),
                  'lastName': lastName.trim(),
                  'email': email.trim(),
                  'phone': phone.trim(),
                },
              );
            } catch (e) {
              // No interrumpir el flujo si falla — el usuario puede completar su perfil después
              print('Personas record creation failed (non-critical): $e');
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

  Future<void> changePasswordWithCurrent({
    required String current,
    required String newPassword,
  }) async {
    await apiClient.post(
      ApiConstants.changePassword,
      data: {
        'ContrasenaActual': current,
        'NuevaClave': newPassword,
        'currentPassword': current,
        'newPassword': newPassword,
      },
    );
  }
}
