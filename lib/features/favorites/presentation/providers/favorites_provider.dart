import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final ApiClient _apiClient;
  FavoritesNotifier(this._apiClient) : super({});

  Future<void> loadFavorites() async {
    try {
      final response = await _apiClient.get(ApiConstants.favorites);
      final data = response.data;
      if (data == null) return;

      final isSuccess =
          data['codigoRespuesta'] == '0' || data['success'] == true;
      if (isSuccess) {
        final list = (data['datos'] ?? data['data'] ?? []) as List;
        final ids = list
            .map((f) => (f['id'] ?? f['trabajoId'] ?? f['jobId']).toString())
            .toSet();
        state = ids;
      }
    } catch (_) {}
  }

  Future<void> toggle(String jobId) async {
    final currentlyFav = state.contains(jobId);
    if (currentlyFav) {
      state = {...state}..remove(jobId);
    } else {
      state = {...state, jobId};
    }

    try {
      final intId = int.tryParse(jobId) ?? 1;
      await _apiClient.post(
        ApiConstants.favoriteToggle,
        data: {'TrabajoId': intId, 'jobId': jobId},
      );
    } catch (_) {
      // Revertir si falla
      if (currentlyFav) {
        state = {...state, jobId};
      } else {
        state = {...state}..remove(jobId);
      }
    }
  }

  bool isFavorite(String jobId) => state.contains(jobId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    final apiClient = ref.read(apiClientProvider);
    final notifier = FavoritesNotifier(apiClient);
    notifier.loadFavorites();
    return notifier;
  },
);
