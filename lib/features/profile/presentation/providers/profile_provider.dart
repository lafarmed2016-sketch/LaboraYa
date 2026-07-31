import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';

class UserProfile {
  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String role;
  final String userType;
  final String? city;
  final String? bio;
  final bool emailVerified;
  final bool phoneVerified;
  final double? workerRating;
  final int? workerReviews;
  final int? completedJobs;
  final bool isVerified;
  final double? hourlyRate;

  UserProfile({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.role = 'USER',
    this.userType = 'BOTH',
    this.city,
    this.bio,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.workerRating,
    this.workerReviews,
    this.completedJobs,
    this.isVerified = false,
    this.hourlyRate,
  });

  String get fullName => '$firstName $lastName'.trim();
  double get rating => workerRating ?? 0.0;
  int get reviews => workerReviews ?? 0;
}

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final storage = ref.read(secureStorageProvider);
    final response = await apiClient.get(ApiConstants.userProfile);
    final data = response.data;
    if (data == null) return null;

    final isSuccess = data['codigoRespuesta'] == '0' || data['success'] == true;
    final u = data['datos'] ?? data['data'] ?? data;

    if (isSuccess ||
        u['id'] != null ||
        u['usuarioId'] != null ||
        u['nombres'] != null) {
      final names = (u['nombres'] ?? u['firstName'] ?? '').toString();
      final lastnames = (u['apellidos'] ?? u['lastName'] ?? '').toString();
      final localAvatarPath = await storage.getLocalAvatarPath();

      return UserProfile(
        id: (u['usuarioId'] ?? u['id'] ?? '1').toString(),
        email: (u['correo'] ?? u['email'] ?? '').toString(),
        phone: (u['telefono'] ?? u['phone'])?.toString(),
        firstName: names.isNotEmpty ? names : 'Usuario',
        lastName: lastnames,
        avatar: localAvatarPath ?? u['fotoUrl'] ?? u['avatar'],
        role: (u['role'] ?? 'USER').toString(),
        userType: (u['tipoUsuario'] ?? u['userType'] ?? 'BOTH')
            .toString()
            .toUpperCase(),
        city: (u['distrito'] ?? u['provincia'] ?? u['departamento'] ?? u['ciudad'] ?? u['city'])?.toString(),
        bio: (u['descripcion'] ?? u['bio'] ?? u['workerDescription'])
            ?.toString(),
        isVerified: u['esVerificado'] == true || u['emailVerified'] == true,
        workerRating: (u['rating'] ?? u['workerRating']) != null
            ? (u['rating'] ?? u['workerRating']).toDouble()
            : null,
        workerReviews: u['resenasCount'] ?? u['workerReviews'],
        completedJobs: u['trabajosCompletadosCount'] ?? u['completedJobs'],
        hourlyRate: u['precioHora'] != null
            ? (u['precioHora']).toDouble()
            : null,
      );
    }
  } catch (_) {}
  return null;
});
