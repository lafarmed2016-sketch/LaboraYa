import 'package:flutter_riverpod/flutter_riverpod.dart';

final mockDataServiceProvider = Provider<MockDataService>(
  (ref) => MockDataService(),
);

class MockUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String city;
  final String profession;
  final String? avatar;
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final int activeJobs;
  final bool isVerified;
  final String memberSince;

  const MockUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.city = 'Lima',
    this.profession = 'Trabajador',
    this.avatar,
    this.rating = 0,
    this.totalReviews = 0,
    this.completedJobs = 0,
    this.activeJobs = 0,
    this.isVerified = false,
    this.memberSince = '2024',
  });

  String get fullName => '$firstName $lastName';
}

class MockConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  const MockConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class MockNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String? relatedId;

  const MockNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.relatedId,
  });
}

class MockReview {
  final String id;
  final String reviewerName;
  final String? reviewerAvatar;
  final double rating;
  final String comment;
  final String jobTitle;
  final String date;

  const MockReview({
    required this.id,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.jobTitle,
    required this.date,
  });
}

class MockDataService {
  // Current user
  final MockUser currentUser = const MockUser(
    id: 'user_current',
    firstName: 'Juan',
    lastName: 'Pérez',
    email: 'juan@correo.com',
    phone: '987654321',
    city: 'Lima',
    profession: 'Plomero',
    rating: 4.8,
    totalReviews: 32,
    completedJobs: 48,
    activeJobs: 3,
    isVerified: true,
    memberSince: '2022',
  );

  // Other users
  final List<MockUser> users = const [
    MockUser(
      id: 'user_1',
      firstName: 'María',
      lastName: 'García',
      email: 'maria@correo.com',
      profession: 'Empleadora',
      rating: 4.5,
      totalReviews: 12,
      isVerified: true,
      memberSince: '2023',
    ),
    MockUser(
      id: 'user_2',
      firstName: 'Carlos',
      lastName: 'López',
      email: 'carlos@correo.com',
      profession: 'Albañil',
      rating: 4.2,
      totalReviews: 8,
      memberSince: '2023',
    ),
    MockUser(
      id: 'user_3',
      firstName: 'Ana',
      lastName: 'Torres',
      email: 'ana@correo.com',
      profession: 'Empleadora',
      rating: 4.7,
      totalReviews: 15,
      isVerified: true,
      memberSince: '2022',
    ),
    MockUser(
      id: 'user_4',
      firstName: 'Luis',
      lastName: 'Fernández',
      email: 'luis@correo.com',
      profession: 'Electricista',
      rating: 4.9,
      totalReviews: 45,
      isVerified: true,
      memberSince: '2021',
    ),
    MockUser(
      id: 'user_5',
      firstName: 'Pedro',
      lastName: 'Sánchez',
      email: 'pedro@correo.com',
      profession: 'Pintor',
      rating: 4.3,
      totalReviews: 20,
      memberSince: '2023',
    ),
  ];

  // Conversations
  final List<MockConversation> conversations = const [
    MockConversation(
      id: 'conv_1',
      participantId: 'user_1',
      participantName: 'María García',
      lastMessage: 'Hola, ¿sigues disponible para el trabajo?',
      time: '10:30 a.m.',
      unreadCount: 2,
      isOnline: true,
    ),
    MockConversation(
      id: 'conv_2',
      participantId: 'user_2',
      participantName: 'Carlos López',
      lastMessage: 'Perfecto, puedo mañana a las 9...',
      time: '9:45 a.m.',
      isOnline: false,
    ),
    MockConversation(
      id: 'conv_3',
      participantId: 'user_3',
      participantName: 'Ana Torres',
      lastMessage: '¿Qué materiales se necesitan?',
      time: 'Ayer',
      isOnline: true,
    ),
    MockConversation(
      id: 'conv_4',
      participantId: 'user_4',
      participantName: 'Luis Fernández',
      lastMessage: 'Listo, muchas gracias',
      time: '2 días',
      isOnline: false,
    ),
    MockConversation(
      id: 'conv_5',
      participantId: 'user_5',
      participantName: 'Pedro Sánchez',
      lastMessage: 'Te enviaré mi ubicación',
      time: '3 días',
      isOnline: false,
    ),
  ];

  // Notifications
  final List<MockNotification> notifications = const [
    MockNotification(
      id: 'notif_1',
      type: 'application',
      title: 'Nueva postulación',
      body: 'Carlos López se postuló a "Reparación de fuga de agua"',
      time: 'Hace 5 min',
      relatedId: 'demo_1',
    ),
    MockNotification(
      id: 'notif_2',
      type: 'accepted',
      title: 'Postulación aceptada',
      body: 'Tu postulación para "Pintura de departamento" fue aceptada',
      time: 'Hace 1 hora',
      relatedId: 'demo_4',
    ),
    MockNotification(
      id: 'notif_3',
      type: 'message',
      title: 'Nuevo mensaje',
      body: 'María García te envió un mensaje',
      time: 'Hace 2 horas',
      relatedId: 'conv_1',
    ),
    MockNotification(
      id: 'notif_4',
      type: 'review',
      title: 'Nueva calificación',
      body: 'Recibiste una calificación de 5 estrellas',
      time: 'Ayer',
    ),
    MockNotification(
      id: 'notif_5',
      type: 'completed',
      title: 'Trabajo completado',
      body: '"Instalación de grifería" fue marcado como completado',
      time: 'Hace 2 días',
      relatedId: 'demo_3',
    ),
  ];

  // Reviews
  final List<MockReview> reviews = const [
    MockReview(
      id: 'rev_1',
      reviewerName: 'María García',
      rating: 5.0,
      comment: 'Excelente trabajo, muy profesional y puntual. Lo recomiendo.',
      jobTitle: 'Reparación de fuga',
      date: 'Hace 3 días',
    ),
    MockReview(
      id: 'rev_2',
      reviewerName: 'Carlos López',
      rating: 4.5,
      comment: 'Buen trabajo, cumplió con lo acordado.',
      jobTitle: 'Instalación de grifería',
      date: 'Hace 1 semana',
    ),
    MockReview(
      id: 'rev_3',
      reviewerName: 'Ana Torres',
      rating: 5.0,
      comment: 'Recomendado! Muy limpio y ordenado al trabajar.',
      jobTitle: 'Pintura de sala',
      date: 'Hace 2 semanas',
    ),
    MockReview(
      id: 'rev_4',
      reviewerName: 'Luis Fernández',
      rating: 4.0,
      comment: 'Cumplió pero llegó un poco tarde.',
      jobTitle: 'Reparación de tubería',
      date: 'Hace 1 mes',
    ),
    MockReview(
      id: 'rev_5',
      reviewerName: 'Pedro Sánchez',
      rating: 5.0,
      comment: 'Perfecto, muy buen servicio.',
      jobTitle: 'Mantenimiento de baño',
      date: 'Hace 1 mes',
    ),
  ];

  // Favorites (job IDs)
  List<String> favoriteJobIds = [];

  // Verifications
  final Map<String, bool> verifications = {
    'email': true,
    'phone': true,
    'identity': false,
    'selfie': false,
    'address': false,
  };

  void toggleFavorite(String jobId) {
    if (favoriteJobIds.contains(jobId)) {
      favoriteJobIds.remove(jobId);
    } else {
      favoriteJobIds.add(jobId);
    }
  }

  bool isFavorite(String jobId) => favoriteJobIds.contains(jobId);
}
