import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

// Jobs state
class JobsState {
  final List<JobEntity> jobs;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? searchQuery;
  final String? categoryFilter;
  final String? modalityFilter;

  const JobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.searchQuery,
    this.categoryFilter,
    this.modalityFilter,
  });

  JobsState copyWith({
    List<JobEntity>? jobs,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? searchQuery,
    String? categoryFilter,
    String? modalityFilter,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      modalityFilter: modalityFilter ?? this.modalityFilter,
    );
  }
}

// Jobs Notifier
class JobsNotifier extends StateNotifier<JobsState> {
  final ApiClient _apiClient;
  final Map<String, List<String>> _localJobImages = {};

  JobsNotifier(this._apiClient) : super(const JobsState());

  Future<void> loadJobs({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get(
        ApiConstants.jobsSearch,
        queryParameters: {
          'page': page,
          'pageSize': 20,
          if (state.categoryFilter != null) 'categoryId': state.categoryFilter,
          if (state.modalityFilter != null) 'modality': state.modalityFilter,
          if (state.searchQuery != null && state.searchQuery!.isNotEmpty)
            'search': state.searchQuery,
        },
      );

      final data = response.data;
      if (data == null || (data is String && data.trim().isEmpty)) {
        state = state.copyWith(
          jobs: refresh ? [] : state.jobs,
          isLoading: false,
          hasMore: false,
        );
        return;
      }

      if (data is Map<String, dynamic> && (data['success'] == true || data['codigoRespuesta'] == '0')) {
        final rawList = data['data'] ?? data['datos'] ?? [];
        final jobsList = (rawList as List)
            .map((j) => JobEntity.fromJson(j as Map<String, dynamic>))
            .toList();

        // Merge local photos logic by matching title
        final mergedJobsList = jobsList.map((job) {
          if (_localJobImages.containsKey(job.title) && job.images.isEmpty) {
            return job.copyWith(images: _localJobImages[job.title]);
          }
          return job;
        }).toList();

        final mergedExistingJobs = state.jobs.map((job) {
          if (_localJobImages.containsKey(job.title) && job.images.isEmpty) {
            return job.copyWith(images: _localJobImages[job.title]);
          }
          return job;
        }).toList();

        final meta = data['meta'];
        final totalPages = meta?['totalPages'] ?? 1;

        state = state.copyWith(
          jobs: refresh ? mergedJobsList : [...mergedExistingJobs, ...mergedJobsList],
          isLoading: false,
          hasMore: page < totalPages,
          currentPage: page + 1,
        );
      } else {
        final errorMsg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Error al cargar trabajos';
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e) {
      _loadDemoJobs();
    }
  }

  /// Crear trabajo desde el formulario — intenta API, fallback local
  Future<bool> createJobFromForm({
    required String title,
    required String description,
    required String categoryName,
    String? address,
    double? latitude,
    double? longitude,
    required String modality,
    double? budgetMin,
    double? budgetMax,
    bool isUrgent = false,
    String materials = 'TO_COORDINATE',
    String? duration,
    int workersNeeded = 1,
    List<File> photos = const [],
  }) async {
    final cats = [
      'Plomería', 'Electricidad', 'Pintura', 'Carpintería', 'Albañilería', 
      'Limpieza', 'Cerrajería', 'Mecánica', 'Jardinería', 'Mudanzas', 
      'Instalaciones', 'Tecnología', 'Otros'
    ];
    final catId = cats.indexOf(categoryName) + 1;
    final finalCatId = catId > 0 ? catId : 1;

    try {
      final dataMap = {
        'title': title,
        'Titulo': title,
        'description': description,
        'Descripcion': description,
        'categoryId': finalCatId,
        'CategoriaId': finalCatId,
        'modality': modality,
        'TipoPago': modality.toUpperCase(),
        'address': address,
        'Direccion': address,
        'Ciudad': 'Lima, Perú',
        'latitude': latitude,
        'Latitud': latitude,
        'longitude': longitude,
        'Longitud': longitude,
        'budgetMin': budgetMin,
        'Presupuesto': budgetMin,
        'budgetMax': budgetMax ?? budgetMin,
        'budgetFixed': true,
        'isUrgent': isUrgent,
        'EsUrgente': isUrgent,
        'materials': materials,
        'duration': duration,
        'workersNeeded': workersNeeded,
        'publishNow': true,
      };

      bool isSuccess = false;
      dynamic response;

      // Cache locally chosen photographs for this job post
      if (photos.isNotEmpty) {
        _localJobImages[title] = photos.map((f) => f.path).toList();
      }

      if (photos.isNotEmpty) {
        try {
          final multipartList = <MultipartFile>[];
          for (final photo in photos) {
            multipartList.add(await MultipartFile.fromFile(photo.path, filename: 'job_photo.jpg'));
          }

          final formData = FormData.fromMap({
            ...dataMap,
            'images': multipartList,
            'files': multipartList,
            'foto': multipartList.isNotEmpty ? multipartList.first : null,
          });

          response = await _apiClient.post(ApiConstants.jobsCreate, data: formData);
          final data = response.data;
          if (data is Map) {
            if (data['codigoRespuesta'] == '0' || data['success'] == true) {
              isSuccess = true;
            } else {
              throw Exception(data['mensaje'] ?? 'Error desconocido');
            }
          }
        } catch (e) {
          // If Multipart upload fails/isn't supported by the route, print and fall back
          state = state.copyWith(error: 'Advertencia: no se pudieron cargar las fotos en el servidor: $e');
        }
      }

      if (!isSuccess) {
        response = await _apiClient.post(
          ApiConstants.jobsCreate,
          data: dataMap,
        );
        final data = response.data;
        if (data is Map) {
          if (data['codigoRespuesta'] == '0' || data['success'] == true) {
            isSuccess = true;
          } else {
            state = state.copyWith(error: data['mensaje'] ?? 'Error desconocido');
            return false;
          }
        }
      }

      if (isSuccess) {
        await loadJobs(refresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Agregar un trabajo publicado por el usuario
  void addJob(JobEntity job) {
    state = state.copyWith(jobs: [job, ...state.jobs]);
  }

  /// Eliminar un trabajo
  void removeJob(String jobId) {
    state = state.copyWith(
      jobs: state.jobs.where((j) => j.id != jobId).toList(),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadJobs(refresh: true);
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(categoryFilter: categoryId, currentPage: 1);
    loadJobs(refresh: true);
  }

  void setModalityFilter(String? modality) {
    state = state.copyWith(modalityFilter: modality, currentPage: 1);
    loadJobs(refresh: true);
  }

  void clearFilters() {
    state = const JobsState();
    loadJobs(refresh: true);
  }

  /// Datos demo para presentación cuando el API no está disponible
  void _loadDemoJobs() {
    state = state.copyWith(
      jobs: [],
      isLoading: false,
      hasMore: false,
      error: null,
    );
  }
}

// Provider
final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final notifier = JobsNotifier(apiClient);
  notifier.loadJobs(refresh: true);
  return notifier;
});

// Single job provider - busca en lista local primero, luego en API
final jobDetailProvider = FutureProvider.family<JobEntity?, String>((
  ref,
  jobId,
) async {
  // Siempre buscar en la lista local primero (incluye demos)
  final jobs = ref.read(jobsProvider).jobs;
  final localJob = jobs.where((j) => j.id == jobId).firstOrNull;
  if (localJob != null) return localJob;

  // Si no está local, intentar la API
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('${ApiConstants.jobs}/$jobId');
    final data = response.data;
    if (data['success'] == true) {
      final jobData = data['data']['job'] as Map<String, dynamic>;
      return JobEntity.fromJson(jobData);
    }
    return null;
  } catch (e) {
    return null;
  }
});
