import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class ReviewData {
  final String id;
  final double rating;
  final String? comment;
  final String reviewerName;
  final String? reviewerAvatar;
  final String? jobTitle;
  final DateTime createdAt;

  ReviewData({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewerName,
    this.reviewerAvatar,
    this.jobTitle,
    required this.createdAt,
  });
}

final userReviewsProvider = FutureProvider.family<List<ReviewData>, String>((
  ref,
  userId,
) async {
  try {
    final intUserId = int.tryParse(userId) ?? 1;
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(
      '${ApiConstants.reviewsByUser}/$intUserId',
    );
    final data = response.data;
    if (data == null) return [];

    final isSuccess = data['codigoRespuesta'] == '0' || data['success'] == true;
    if (isSuccess) {
      final list = (data['datos'] ?? data['data'] ?? []) as List;
      return list
          .map(
            (r) => ReviewData(
              id: (r['id'] ?? r['resenaId'] ?? '1').toString(),
              rating: ((r['rating'] ?? r['calificacion'] ?? 5) as num)
                  .toDouble(),
              comment: (r['comment'] ?? r['comentario'])?.toString(),
              reviewerName:
                  (r['reviewerName'] ?? r['evaluadorNombre'] ?? 'Usuario')
                      .toString(),
              reviewerAvatar: r['reviewerAvatar'] ?? r['evaluadorAvatar'],
              jobTitle: r['jobTitle'] ?? r['trabajoTitulo'],
              createdAt:
                  DateTime.tryParse(
                    (r['createdAt'] ?? r['fechaCreacion'] ?? '').toString(),
                  ) ??
                  DateTime.now(),
            ),
          )
          .toList();
    }
  } catch (_) {}
  return [];
});
