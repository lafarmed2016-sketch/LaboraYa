import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class CategoryData {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int sortOrder;

  CategoryData({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.sortOrder = 0,
  });
}

final categoriesProvider = FutureProvider<List<CategoryData>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.categories);
    final data = response.data;
    if (data['success'] == true) {
      return (data['data'] as List)
          .map(
            (c) => CategoryData(
              id: c['id'],
              name: c['name'] ?? '',
              description: c['description'],
              icon: c['icon'],
              sortOrder: c['sortOrder'] ?? 0,
            ),
          )
          .toList();
    }
  } catch (_) {}
  return [];
});
