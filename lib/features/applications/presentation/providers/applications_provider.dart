import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class ApplicationData {
  final String id;
  final String jobId;
  final String jobTitle;
  final String employerName;
  final String? workerId;
  final String? workerName;
  final String? workerAvatar;
  final String status;
  final double proposedBudget;
  final String message;
  final DateTime createdAt;
  final String? categoryName;

  ApplicationData({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.employerName,
    this.workerId,
    this.workerName,
    this.workerAvatar,
    this.status = 'PENDIENTE',
    required this.proposedBudget,
    required this.message,
    required this.createdAt,
    this.categoryName,
  });

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
      case 'SENT':
        return 'Pendiente';
      case 'ACEPTADA':
      case 'ACCEPTED':
        return 'Aceptada';
      case 'RECHAZADA':
      case 'REJECTED':
        return 'Rechazada';
      case 'RETIRADA':
      case 'WITHDRAWN':
        return 'Retirada';
      default:
        return status;
    }
  }
}

class ApplicationsNotifier extends StateNotifier<List<ApplicationData>> {
  final ApiClient _apiClient;
  ApplicationsNotifier(this._apiClient) : super([]);

  Future<void> loadMyApplications({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.applicationsMine,
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data == null) return;

      final isSuccess =
          data['codigoRespuesta'] == '0' || data['success'] == true;
      if (isSuccess) {
        final list = (data['datos'] ?? data['data'] ?? []) as List;
        state = list
            .map(
              (a) => ApplicationData(
                id: (a['id'] ?? a['postulacionId'] ?? '1').toString(),
                jobId: (a['jobId'] ?? a['trabajoId'] ?? '').toString(),
                jobTitle: (a['title'] ?? a['trabajoTitulo'] ?? 'Trabajo')
                    .toString(),
                employerName: (a['employerName'] ?? a['empleadorNombre'] ?? a['trabajadorNombre'] ?? 'Usuario').toString(),
                workerId: (a['workerId'] ?? a['trabajadorId'])?.toString(),
                workerName: (a['workerName'] ?? a['trabajadorNombre'])?.toString(),
                workerAvatar: (a['workerAvatar'] ?? a['trabajadorFoto'])?.toString(),
                status: (a['status'] ?? a['estado'] ?? 'PENDIENTE').toString(),
                proposedBudget: ((a['proposedBudget'] ?? a['montoPropuesto'] ?? a['precioPropuesto'] ?? 0) as num).toDouble(),
                message: (a['message'] ?? a['mensaje'] ?? a['cartaPresentacion'] ?? '').toString(),
                createdAt:
                    DateTime.tryParse(
                      (a['createdAt'] ?? a['fechaCreacion'] ?? '').toString(),
                    ) ??
                    DateTime.now(),
                categoryName: a['categoryName']?.toString(),
              ),
            )
            .toList();
      }
    } catch (_) {}
  }

  Future<bool> apply({
    required String jobId,
    required String jobTitle,
    required String employerName,
    required double budget,
    required String message,
  }) async {
    try {
      final intJobId = int.tryParse(jobId) ?? 1;
      final response = await _apiClient.post(
        ApiConstants.applications,
        data: {
          'TrabajoId': intJobId,
          'MontoPropuesto': budget,
          'Mensaje': message,
          'jobId': jobId,
          'message': message,
          'proposedBudget': budget,
        },
      );
      final data = response.data;
      if (data == null) return false;

      final isSuccess =
          data['codigoRespuesta'] == '0' || data['success'] == true;
      if (isSuccess) {
        await loadMyApplications();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> withdraw(String applicationId) async {
    try {
      await _apiClient.put(
        '${ApiConstants.applications}/$applicationId/Retirar',
      );
      state = state.map((a) {
        if (a.id == applicationId) {
          return ApplicationData(
            id: a.id,
            jobId: a.jobId,
            jobTitle: a.jobTitle,
            employerName: a.employerName,
            status: 'RETIRADA',
            proposedBudget: a.proposedBudget,
            message: a.message,
            createdAt: a.createdAt,
            categoryName: a.categoryName,
          );
        }
        return a;
      }).toList();
    } catch (_) {}
  }
}

final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, List<ApplicationData>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      final notifier = ApplicationsNotifier(apiClient);
      notifier.loadMyApplications();
      return notifier;
    });
