import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

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
  final String? dni;
  final bool emailVerified;
  final bool phoneVerified;
  final double? workerRating;
  final int? workerReviews;
  final int? completedJobs;
  final bool isVerified;
  final double? hourlyRate;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.dni,
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
    this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  double get rating => workerRating ?? 0.0;
  int get reviews => workerReviews ?? 0;
  String get memberSinceYear => (createdAt ?? DateTime.now()).year.toString();
}

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    final response = await apiClient.get(ApiConstants.userProfile);
    final data = response.data;
    if (data == null) return _buildLocalProfile(storage);

    if (data is Map && data['codigoRespuesta'] != null && data['codigoRespuesta'] != '0' && data['codigoRespuesta'] != 0) {
      // Error de autenticación o usuario inexistente — intentar perfil local
      return _buildLocalProfile(storage);
    }

    final u = data is Map ? (data['datos'] ?? data['data'] ?? data) : null;
    if (u == null || (u is Map && u.isEmpty)) return _buildLocalProfile(storage);

    final id = (u['usuarioId'] ?? u['id'])?.toString();
    final names = (u['nombres'] ?? u['firstName'] ?? '').toString().trim();
    final lastnames = (u['apellidos'] ?? u['lastName'] ?? '').toString().trim();
    final savedUsername = await storage.getUsername();

    String displayName = names;
    if (displayName.isEmpty) {
      displayName = (savedUsername != null && savedUsername.isNotEmpty)
          ? savedUsername
          : (u['usuario'] ?? u['username'] ?? '').toString().trim();
    }

    // Si no hay ningún dato de identidad válido, intentar perfil local
    if (id == null || id.isEmpty || (displayName.isEmpty && (u['correo'] == null || u['correo'].toString().isEmpty))) {
      return _buildLocalProfile(storage);
    }

    final rawAvatar = u['imagenPerfilUrl'] ??
        u['ImagenPerfilUrl'] ??
        u['fotoUrl'] ??
        u['FotoUrl'] ??
        u['avatar'] ??
        u['Avatar'];

    final rawDate = u['fechaCreacion'] ?? u['FechaCreacion'] ?? u['fechaRegistro'] ?? u['FechaRegistro'] ?? u['createdAt'] ?? u['CreatedAt'];
    final createdAtDate = rawDate != null ? DateTime.tryParse(rawDate.toString()) : null;

    return UserProfile(
      id: id,
      email: (u['correo'] ?? u['email'] ?? '').toString(),
      phone: (u['telefono'] ?? u['phone'])?.toString(),
      firstName: displayName.isNotEmpty ? displayName : 'Usuario',
      lastName: lastnames,
      avatar: rawAvatar != null && rawAvatar.toString().trim().isNotEmpty
          ? JobEntity.formatUrl(rawAvatar.toString())
          : null,
      dni: (u['documentoIdentidad'] ?? u['dni'])?.toString(),
      role: (u['role'] ?? 'USER').toString(),
      userType: (u['tipoUsuario'] ?? u['userType'] ?? 'BOTH')
          .toString()
          .toUpperCase(),
      city: (u['distrito'] ?? u['provincia'] ?? u['departamento'] ?? u['ciudad'] ?? u['city'])?.toString(),
      bio: (u['descripcion'] ?? u['bio'] ?? u['workerDescription'])?.toString(),
      isVerified: u['esVerificado'] == true || u['emailVerified'] == true,
      workerRating: ((u['rating'] ?? u['workerRating']) as num?)?.toDouble(),
      workerReviews: u['resenasCount'] ?? u['workerReviews'],
      completedJobs: u['trabajosCompletadosCount'] ?? u['completedJobs'],
      hourlyRate: (u['precioHora'] as num?)?.toDouble(),
      createdAt: createdAtDate,
    );
  } catch (_) {
    // En caso de error de red/API, intentar construir perfil desde datos locales
    try {
      final storage = ref.read(secureStorageProvider);
      return _buildLocalProfile(storage);
    } catch (_) {
      return null;
    }
  }
});

/// Construye un UserProfile mínimo desde datos guardados localmente.
/// Esto cubre el caso de Google Sign In cuando el backend no reconoce el token Firebase.
Future<UserProfile?> _buildLocalProfile(SecureStorage storage) async {
  final userId = await storage.getUserId();
  final username = await storage.getUsername();

  // Si no hay userId local, el usuario realmente no está autenticado
  if (userId == null || userId.isEmpty) return null;

  final parts = (username ?? 'Usuario Google').trim().split(' ');
  final firstName = parts.isNotEmpty ? parts.first : 'Usuario';
  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

  return UserProfile(
    id: userId,
    email: '',
    firstName: firstName.isNotEmpty ? firstName : 'Usuario',
    lastName: lastName,
  );
}
