import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/features/authentication/presentation/pages/login_page.dart';
import 'package:laboraya_app/features/authentication/presentation/pages/register_page.dart';
import 'package:laboraya_app/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:laboraya_app/features/home/presentation/pages/home_page.dart';
import 'package:laboraya_app/features/home/presentation/pages/main_shell.dart';
import 'package:laboraya_app/features/jobs/presentation/pages/job_detail_page.dart';
import 'package:laboraya_app/features/jobs/presentation/pages/create_job_page.dart';
import 'package:laboraya_app/features/jobs/presentation/pages/search_jobs_page.dart';
import 'package:laboraya_app/features/chat/presentation/pages/conversations_page.dart';
import 'package:laboraya_app/features/chat/presentation/pages/chat_page.dart';
import 'package:laboraya_app/features/profile/presentation/pages/profile_page.dart';
import 'package:laboraya_app/features/profile/presentation/pages/my_jobs_page.dart';
import 'package:laboraya_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:laboraya_app/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:laboraya_app/features/onboarding/presentation/pages/splash_page.dart';
import 'package:laboraya_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:laboraya_app/features/reviews/presentation/pages/my_reviews_page.dart';
import 'package:laboraya_app/features/verification/presentation/pages/verification_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/settings_page.dart';
import 'package:laboraya_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:laboraya_app/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:laboraya_app/features/applications/presentation/pages/my_applications_page.dart';
import 'package:laboraya_app/features/applications/presentation/pages/received_applications_page.dart';
import 'package:laboraya_app/features/applications/presentation/pages/apply_page.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/support/presentation/pages/help_center_page.dart';
import 'package:laboraya_app/features/support/presentation/pages/terms_page.dart';
import 'package:laboraya_app/features/support/presentation/pages/privacy_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/change_password_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/blocked_users_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/about_page.dart';
import 'package:laboraya_app/features/settings/presentation/pages/payment_methods_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/search', builder: (_, __) => const SearchJobsPage()),
          GoRoute(
            path: '/messages',
            builder: (_, __) => const ConversationsPage(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/jobs/create', builder: (_, __) => const CreateJobPage()),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) =>
            JobDetailPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/apply',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          final jobs = ProviderScope.containerOf(
            context,
          ).read(jobsProvider).jobs;
          final job = jobs.where((j) => j.id == jobId).firstOrNull;
          if (job == null)
            return const Scaffold(
              body: Center(child: Text('Trabajo no encontrado')),
            );
          return ApplyPage(job: job);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) =>
            ChatPage(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(path: '/my-jobs', builder: (_, __) => const MyJobsPage()),
      GoRoute(
        path: '/my-applications',
        builder: (_, __) => const MyApplicationsPage(),
      ),
      GoRoute(
        path: '/received-applications',
        builder: (_, __) => const ReceivedApplicationsPage(),
      ),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesPage()),
      GoRoute(path: '/my-reviews', builder: (_, __) => const MyReviewsPage()),
      GoRoute(
        path: '/verification',
        builder: (_, __) => const VerificationPage(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const CompleteProfilePage(),
      ),
      GoRoute(path: '/help-center', builder: (_, __) => const HelpCenterPage()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsPage()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPage()),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (_, __) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (_, __) => const BlockedUsersPage(),
      ),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(
        path: '/payment-methods',
        builder: (_, __) => const PaymentMethodsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Página no encontrada'))),
  );
});
