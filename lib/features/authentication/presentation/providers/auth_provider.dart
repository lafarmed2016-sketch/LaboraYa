import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';

// Estado simple de auth
class AuthState {
  final bool isAuthenticated;
  final String? userId;

  const AuthState({this.isAuthenticated = false, this.userId});
}

// Provider simple que solo lee el storage una vez
final authStateProvider = FutureProvider<AuthState>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final hasToken = await storage.hasToken();
  if (hasToken) {
    final userId = await storage.getUserId();
    return AuthState(isAuthenticated: true, userId: userId);
  }
  return const AuthState();
});
