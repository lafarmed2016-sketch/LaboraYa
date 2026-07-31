import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class VerificationItem {
  final String id;
  final String type;
  final String status; // PENDING, APPROVED, REJECTED
  final String? note;
  final DateTime createdAt;

  VerificationItem({
    required this.id,
    required this.type,
    required this.status,
    this.note,
    required this.createdAt,
  });
}

final verificationsProvider = FutureProvider<List<VerificationItem>>((
  ref,
) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.verifications);
    final data = response.data;
    if (data['success'] == true) {
      return (data['data'] as List)
          .map(
            (d) => VerificationItem(
              id: d['id'],
              type: d['type'],
              status: d['status'] ?? 'PENDING',
              note: d['note'],
              createdAt:
                  DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now(),
            ),
          )
          .toList();
    }
  } catch (_) {}
  return [];
});
