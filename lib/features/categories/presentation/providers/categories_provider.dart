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
    if (data is Map) {
      final isSuccess = data['success'] == true || data['codigoRespuesta'] == '0';
      if (isSuccess) {
        final list = (data['datos'] ?? data['data'] ?? []) as List;
        return list.map((c) {
          final map = c as Map<String, dynamic>;
          return CategoryData(
            id: (map['id'] ?? '').toString(),
            name: (map['nombre'] ?? map['name'] ?? '').toString(),
            description: map['descripcion']?.toString() ?? map['description']?.toString(),
            icon: map['icono']?.toString() ?? map['icon']?.toString(),
            sortOrder: (map['orden'] ?? map['sortOrder'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
    }
  } catch (_) {}
  return [];
});
