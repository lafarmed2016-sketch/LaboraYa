import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

// ── Blocked Users ──
class BlockedUserData {
  final String blockedUserId;
  final String firstName;
  final String lastName;
  final String? avatar;
  final DateTime createdAt;

  BlockedUserData({
    required this.blockedUserId,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.createdAt,
  });
  String get fullName => '$firstName $lastName';
}

final blockedUsersProvider = FutureProvider<List<BlockedUserData>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.settingsBlockedUsers);
    final data = response.data;
    if (data['success'] == true) {
      return (data['data'] as List)
          .map(
            (b) => BlockedUserData(
              blockedUserId: b['blockedUserId'],
              firstName: b['firstName'] ?? '',
              lastName: b['lastName'] ?? '',
              avatar: b['avatar'],
              createdAt:
                  DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now(),
            ),
          )
          .toList();
    }
  } catch (_) {}
  return [];
});

// ── Notification Settings ──
class NotifSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool newApplications;
  final bool newMessages;
  final bool reviews;

  NotifSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.newApplications = true,
    this.newMessages = true,
    this.reviews = true,
  });
}

final notifSettingsProvider = FutureProvider<NotifSettings>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.settingsNotifications);
    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      final s = data['data'];
      return NotifSettings(
        pushEnabled: s['pushEnabled'] ?? true,
        emailEnabled: s['emailEnabled'] ?? true,
        newApplications: s['newApplications'] ?? true,
        newMessages: s['newMessages'] ?? true,
        reviews: s['reviews'] ?? true,
      );
    }
  } catch (_) {}
  return NotifSettings();
});
