class ApiConstants {
  // Auth & Users V2
  static const String login = '/api/v2/UsuarioV2/Login';
  static const String register = '/api/v2/UsuarioV2/Registrar';
  static const String contexto = '/api/v2/UsuarioV2/Contexto';
  static const String refreshToken = '/api/v2/UsuarioV2/RefreshToken';
  static const String logout = '/api/v2/UsuarioV2/Logout';
  static const String changePassword = '/api/v2/UsuarioV2/CambiarPassword';

  // Users & Profiles V2
  static const String userProfile = '/api/v2/PersonaV2/Perfil';
  static const String userById = '/api/v2/PersonaV2'; // + /{id}
  static const String workerProfile = '/api/v2/PersonaV2/Perfil';
  static const String deleteAccount = '/api/v2/UsuarioV2/Account';

  // Categories V2
  static const String categories = '/api/v2/CategoriaV2';

  // Jobs V2
  static const String jobs = '/api/v2/TrabajoV2';
  static const String jobsSearch = '/api/v2/TrabajoV2/Buscar';
  static const String jobsMine = '/api/v2/TrabajoV2/MisPublicaciones';
  static const String jobsCreate = '/api/v2/TrabajoV2/Crear';
  static const String jobsNearby = '/api/v2/TrabajoV2/Buscar';

  // Applications V2
  static const String applications = '/api/v2/TrabajoV2/Postular';
  static const String applicationsMine = '/api/v2/TrabajoV2/MisPostulaciones';
  static const String applicationsByJob =
      '/api/v2/TrabajoV2'; // + /{jobId}/Postulaciones

  // Contracts V2
  static const String contracts = '/api/v2/ContratoV2';

  // Chat V2
  static const String chats = '/api/v2/ChatV2/Conversaciones';
  static const String chatMessages =
      '/api/v2/ChatV2'; // + /{conversacionId}/Mensajes
  static const String chatSend = '/api/v2/ChatV2/Enviar';
  static const String chatCreate = '/api/v2/ChatV2/Conversacion';

  // Notifications V2
  static const String notifications = '/api/v2/NotificacionV2';
  static const String notificationsUnreadCount =
      '/api/v2/NotificacionV2/UnreadCount';
  static const String notificationsReadAll = '/api/v2/NotificacionV2/LeerTodas';

  // Reviews V2
  static const String reviews = '/api/v2/ResenaV2';
  static const String reviewsByUser = '/api/v2/ResenaV2/Usuario';

  // Favorites V2
  static const String favorites = '/api/v2/FavoritoV2/MisFavoritos';
  static const String favoriteToggle = '/api/v2/FavoritoV2/Toggle';

  // Settings & Verifications V2
  static const String settingsNotifications = '/api/v2/NotificacionV2';
  static const String settingsBlockedUsers = '/api/v2/UsuarioV2/Blocked';
  static const String verifications = '/api/v2/PersonaV2/Verificaciones';
}
