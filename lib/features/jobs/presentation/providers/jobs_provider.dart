import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/services/jobs_cache_service.dart';
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
  /// true cuando los datos vienen del caché local (modo offline / stale)
  final bool isFromCache;
  /// true cuando el caché se está refrescando en background
  final bool isRefreshingInBackground;

  const JobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.searchQuery,
    this.categoryFilter,
    this.modalityFilter,
    this.isFromCache = false,
    this.isRefreshingInBackground = false,
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
    bool? isFromCache,
    bool? isRefreshingInBackground,
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
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshingInBackground: isRefreshingInBackground ?? this.isRefreshingInBackground,
    );
  }
}

// Jobs Notifier
class JobsNotifier extends StateNotifier<JobsState> {
  final ApiClient _apiClient;

  JobsNotifier(this._apiClient) : super(const JobsState());

  Future<void> loadJobs({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;

    // ── Stale-While-Revalidate ─────────────────────────────────────
    // 1. Si es refresh y hay caché, mostrarlo INMEDIATAMENTE (sin loader)
    if (refresh && page == 1) {
      final cached = await JobsCacheService.loadJobs();
      if (cached != null && cached.isNotEmpty) {
        final cachedJobs = cached
            .map((j) => JobEntity.fromJson(j))
            .toList();
        // Mostrar caché instantáneamente mientras cargamos en background
        state = state.copyWith(
          jobs: cachedJobs,
          isLoading: false,
          isFromCache: true,
          isRefreshingInBackground: true,
          error: null,
        );
        // Ahora refrescar en background sin bloquear la UI
        _fetchFromApi(page: 1, refresh: true);
        return;
      }
    }

    // Sin caché: mostrar loader normal y cargar
    state = state.copyWith(isLoading: true, error: null, isFromCache: false);
    await _fetchFromApi(page: page, refresh: refresh);
  }

  Future<void> _fetchFromApi({required int page, required bool refresh}) async {
    try {
      dynamic data;
      try {
        final response = await _apiClient.get(
          ApiConstants.jobsSearch,
          queryParameters: {
            'page': page,
            'pageSize': 50,
            if (state.categoryFilter != null) 'categoryId': state.categoryFilter,
            if (state.modalityFilter != null) 'modality': state.modalityFilter,
            if (state.searchQuery != null && state.searchQuery!.isNotEmpty)
              'search': state.searchQuery,
          },
        );
        data = response.data;
      } catch (_) {
        final response = await _apiClient.get(
          ApiConstants.jobs,
          queryParameters: {'page': page, 'pageSize': 50},
        );
        data = response.data;
      }

      List rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        rawList = (data['data'] ?? data['datos'] ?? data['items'] ??
            data['jobs'] ?? data['trabajos'] ?? data['result'] ?? []) as List;
      }

      if (rawList.isNotEmpty) {
        final jobsList = rawList
            .map((j) => JobEntity.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();

        // Guardar en caché después de cada fetch exitoso
        try {
          final rawMaps = rawList.map((j) => Map<String, dynamic>.from(j as Map)).toList();
          await JobsCacheService.saveJobs(rawMaps);
        } catch (_) {}

        state = state.copyWith(
          jobs: refresh ? jobsList : [...state.jobs, ...jobsList],
          isLoading: false,
          isRefreshingInBackground: false,
          isFromCache: false,
          hasMore: false,
          currentPage: page + 1,
          error: null,
        );
      } else {
        // Sin datos de API — si ya tenemos caché, no sobreescribir con vacío
        state = state.copyWith(
          isLoading: false,
          isRefreshingInBackground: false,
          error: null,
          jobs: state.jobs.isNotEmpty ? state.jobs : [],
        );
      }
    } catch (e) {
      // Si falla la API pero tenemos datos (caché o previos), no mostrar error
      if (state.jobs.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          isRefreshingInBackground: false,
          isFromCache: true,
          error: null,
        );
      } else {
        // Sin caché ni conexión — estado vacío sin error forzado
        state = state.copyWith(
          isLoading: false,
          isRefreshingInBackground: false,
          jobs: [],
          error: 'Sin conexión. Verifica tu internet y vuelve a intentarlo.',
        );
      }
    }
  }

  int _resolveCategoryId(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.contains('barber') || clean.contains('peluquer') || clean.contains('estética') || clean.contains('estetica')) return 11;
    if (clean.contains('vidrier') || clean.contains('aluminio')) return 12;
    if (clean.contains('tornero') || clean.contains('fresador')) return 13;
    if (clean.contains('maquinaria')) return 14;
    if (clean.contains('chófer') || clean.contains('chofer') || clean.contains('conductor')) return 15;
    if (clean.contains('repartidor') || clean.contains('delivery')) return 16;
    if (clean.contains('cocinero') || clean.contains('chef') || clean.contains('cocina')) return 17;
    if (clean.contains('mozo') || clean.contains('mesero')) return 18;
    if (clean.contains('panader') || clean.contains('pasteler')) return 19;
    if (clean.contains('dj') || clean.contains('sonido') || clean.contains('iluminaci')) return 20;
    if (clean.contains('fotograf') || clean.contains('video')) return 21;
    if (clean.contains('costura') || clean.contains('confecci') || clean.contains('sastre')) return 22;
    if (clean.contains('diseñad') || clean.contains('disenad') || clean.contains('gráfico') || clean.contains('grafico')) return 23;
    if (clean.contains('contable') || clean.contains('sunat') || clean.contains('asesor')) return 24;
    if (clean.contains('clases') || clean.contains('tutor') || clean.contains('profesor')) return 25;
    if (clean.contains('paseador') || clean.contains('mascota')) return 26;

    if (clean.contains('plomer') || clean.contains('gasfiter')) return 1;
    if (clean.contains('electric')) return 2;
    if (clean.contains('pintur')) return 3;
    if (clean.contains('albañil') || clean.contains('albanil')) return 4;
    if (clean.contains('carpinter')) return 5;
    if (clean.contains('limpiez')) return 6;
    if (clean.contains('mecánic') || clean.contains('mecanic')) return 7;
    if (clean.contains('cerraj') || clean.contains('soldad')) return 8;
    if (clean.contains('técnic') || clean.contains('tecnic') || clean.contains('pc')) return 9;

    return 1;
  }

  /// Crear trabajo desde el formulario — envía directamente a API backend SQL
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
    final finalCatId = _resolveCategoryId(categoryName);

    try {
      String? base64Img;
      if (photos.isNotEmpty) {
        try {
          final bytes = await photos.first.readAsBytes();
          base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } catch (_) {}
      }

      final dataMap = <String, dynamic>{
        'title': title,
        'Titulo': title,
        'description': description,
        'Descripcion': description,
        'categoryId': finalCatId,
        'CategoriaId': finalCatId,
        'modality': modality,
        'TipoPago': modality.toUpperCase(),
        'address': address ?? '',
        'Direccion': address ?? '',
        'Ciudad': 'Lima, Perú',
        'latitude': latitude ?? 0.0,
        'Latitud': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'Longitud': longitude ?? 0.0,
        'budgetMin': budgetMin ?? 0.0,
        'Presupuesto': budgetMin ?? 0.0,
        'budgetMax': budgetMax ?? budgetMin ?? 0.0,
        'budgetFixed': true,
        'isUrgent': isUrgent,
        'EsUrgente': isUrgent,
        'materials': materials,
        'duration': duration,
        'workersNeeded': workersNeeded,
        'publishNow': true,
        if (base64Img != null) 'ImagenUrl': base64Img,
        if (base64Img != null) 'imageUrl': base64Img,
      };

      bool isSuccess = false;
      dynamic response;

      if (photos.isNotEmpty) {
        try {
          final formMap = <String, dynamic>{};
          dataMap.forEach((key, val) {
            if (val != null && !key.toLowerCase().contains('imagenurl') && !key.toLowerCase().contains('imageurl')) {
              formMap[key] = val.toString();
            }
          });

          final multipartFiles = <MultipartFile>[];
          for (int i = 0; i < photos.length; i++) {
            final f = photos[i];
            final mf = await MultipartFile.fromFile(
              f.path,
              filename: 'job_photo_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            multipartFiles.add(mf);
          }

          final formData = FormData.fromMap({
            ...formMap,
            'files': multipartFiles,
          });

          response = await _apiClient.post(ApiConstants.jobsCreate, data: formData);
          final data = response.data;
          if (data is Map) {
            if (data['codigoRespuesta'] == '0' || data['success'] == true) {
              isSuccess = true;
            } else {
              state = state.copyWith(error: data['mensaje'] ?? 'Error desconocido');
            }
          }
        } catch (e) {
          state = state.copyWith(error: 'Advertencia: no se pudieron cargar las fotos via FormData: $e');
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al publicar: $e');
      return false;
    }
  }

  void addLocalJob(JobEntity job) {
    state = state.copyWith(jobs: [job, ...state.jobs]);
  }

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


}

// Client Provider
final jobsClientProvider = Provider<JobsNotifier>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final notifier = JobsNotifier(apiClient);
  notifier.loadJobs(refresh: true);
  return notifier;
});

// Provider
final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final notifier = JobsNotifier(apiClient);
  notifier.loadJobs(refresh: true);
  return notifier;
});

// Single job provider
final jobDetailProvider = FutureProvider.family<JobEntity?, String>((
  ref,
  jobId,
) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('${ApiConstants.jobs}/$jobId');
    final data = response.data;
    final u = data is Map ? (data['datos'] ?? data['data'] ?? data) : null;
    if (u != null && u is Map) {
      final jobData = u['job'] ?? u;
      return JobEntity.fromJson(Map<String, dynamic>.from(jobData as Map));
    }
  } catch (_) {}

  final jobs = ref.read(jobsProvider).jobs;
  return jobs.where((j) => j.id == jobId).firstOrNull;
});

// My Jobs Provider — consulta mis publicaciones en V2 (/api/v2/TrabajoV2/MisPublicaciones)
final myJobsProvider = FutureProvider<List<JobEntity>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.get(ApiConstants.jobsMine);
    final data = response.data;
    if (data == null) return [];

    List rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      if (data['datos'] is List) {
        rawList = data['datos'] as List;
      } else if (data['data'] is List) {
        rawList = data['data'] as List;
      }
    }

    return rawList.map((j) => JobEntity.fromJson(j as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});
