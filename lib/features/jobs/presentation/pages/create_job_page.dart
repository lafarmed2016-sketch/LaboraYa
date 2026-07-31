import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/image_picker_service.dart';
import 'package:laboraya_app/core/services/location_service.dart';
import 'package:laboraya_app/features/map/presentation/widgets/osm_map_widget.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────

// Campos soportados por el backend actual:
//   title, description, categoryName, modality, address, latitude, longitude
//   budgetMin, budgetMax, budgetFixed, isUrgent, materials, duration, workersNeeded
//
// Campos UI-only (marcados con aviso):
//   scheduleStart/End, experienceRequired, paymentMethod

const _kTotalSteps = 2;
const _kStepLabels = [
  'Datos del Trabajo',
  'Detalles y Publicación',
];

const _kCategories = [
  'Plomería',
  'Electricidad',
  'Pintura',
  'Carpintería',
  'Albañilería',
  'Limpieza',
  'Cerrajería',
  'Mecánica',
  'Jardinería',
  'Mudanzas',
  'Instalaciones',
  'Tecnología',
  'Otros',
];

const _kModalities = {
  'PER_TASK': 'Por tarea',
  'PER_DAY': 'Por día',
  'PER_WEEK': 'Por semana',
  'PER_MONTH': 'Por mes',
  'PER_CONTRACT': 'Por contrato',
  'FULL_TIME': 'Tiempo completo',
};

const _kMaterials = {
  'BY_EMPLOYER': 'Los proporciono yo',
  'BY_WORKER': 'A cargo del trabajador',
  'TO_COORDINATE': 'Por coordinar',
};

// ─── CreateJobPage ────────────────────────────────────────────────────────────

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  int _step = 0;

  // Paso 0 — Información Principal
  final _step0Key = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Plomería';

  // Ubicación
  final _addressCtrl = TextEditingController();
  LatLng? _location;

  // Presupuesto / Pago único
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(); // unused but kept for compatibility
  bool _fixedPrice = true;
  String _paymentMethod = 'Efectivo';

  // Paso 1 — Detalles
  String _modality = 'PER_TASK';
  String _materials = 'TO_COORDINATE';
  final _durationCtrl = TextEditingController();
  int _workersNeeded = 1;
  bool _isUrgent = false;
  final _experienceCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();

  // Imágenes
  final List<File> _photos = [];

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  // ── Navegación ────────────────────────────────────────────────

  void _next() {
    if (_step == 0) {
      if (!_step0Key.currentState!.validate()) return;
      if (_location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona una ubicación reuniendo tu punto en el mapa u obteniendo tu GPS.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  // ── Publicar — solo campos soportados ─────────────────────────

  Future<void> _publish() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build description appending optional details for full visibility:
      String fullDesc = _descCtrl.text.trim();
      final extraDetails = <String>[];
      if (_paymentMethod.isNotEmpty && _paymentMethod != 'Efectivo') {
        extraDetails.add('Método de pago preferido: $_paymentMethod');
      }
      if (_experienceCtrl.text.trim().isNotEmpty) {
        extraDetails.add('Experiencia requerida: ${_experienceCtrl.text.trim()}');
      }
      if (_scheduleCtrl.text.trim().isNotEmpty) {
        extraDetails.add('Horario disponible: ${_scheduleCtrl.text.trim()}');
      }
      if (_durationCtrl.text.trim().isNotEmpty) {
        extraDetails.add('Duración estimada: ${_durationCtrl.text.trim()}');
      }
      if (_workersNeeded > 1) {
        extraDetails.add('Trabajadores requeridos: $_workersNeeded');
      }
      if (_materials != 'TO_COORDINATE') {
        final materialsLabel = _kMaterials[_materials] ?? _materials;
        extraDetails.add('Materiales: $materialsLabel');
      }

      if (extraDetails.isNotEmpty) {
        fullDesc += '\n\n📝 Detalles adicionales:\n' + extraDetails.map((det) => '• $det').join('\n');
      }

      final ok = await ref
          .read(jobsProvider.notifier)
          .createJobFromForm(
            title: _titleCtrl.text.trim(),
            description: fullDesc,
            categoryName: _category,
            address: _addressCtrl.text.trim().isNotEmpty
                ? _addressCtrl.text.trim()
                : null,
            latitude: _location?.latitude,
            longitude: _location?.longitude,
            modality: _modality,
            budgetMin: double.tryParse(_minCtrl.text),
            budgetMax: double.tryParse(_minCtrl.text),
            isUrgent: _isUrgent,
            materials: _materials,
            workersNeeded: _workersNeeded,
            photos: _photos,
          );
      if (!mounted) return;
      if (ok) {
        _showSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo publicar. Intenta de nuevo.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      // Fallback local cuando el API no está disponible
      _addLocalJob();
    }
  }

  void _addLocalJob() {
    final newJob = JobEntity(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: 'cat_local',
      categoryName: _category,
      address: _addressCtrl.text.trim().isNotEmpty
          ? _addressCtrl.text.trim()
          : 'Lima',
      latitude: _location?.latitude ?? -12.1186,
      longitude: _location?.longitude ?? -77.0318,
      modality: _modality,
      budgetMin: double.tryParse(_minCtrl.text),
      budgetMax: double.tryParse(_minCtrl.text),
      budgetFixed: true,
      materials: _materials,
      workersNeeded: _workersNeeded,
      publisherId: 'user_current',
      publisherName: 'Tú',
      createdAt: DateTime.now(),
      publishedAt: DateTime.now(),
      images: _photos.map((f) => f.path).toList(),
    );
    ref.read(jobsProvider.notifier).addJob(newJob);
    _showSuccess();
  }

  void _showSuccess() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/my-jobs');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Trabajo publicado con éxito!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _CreateJobHeader(
              step: _step,
              totalSteps: _kTotalSteps,
              stepLabels: _kStepLabels,
              onBack: _back,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        ),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
             _CreateJobFooter(
              step: _step,
              totalSteps: _kTotalSteps,
              isLoading: _isLoading,
              error: _step == _kTotalSteps - 1 ? _error : null,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _Step0InfoCombined(
          key: const ValueKey(0),
          formKey: _step0Key,
          titleCtrl: _titleCtrl,
          descCtrl: _descCtrl,
          category: _category,
          onCategory: (v) => setState(() => _category = v),
          minCtrl: _minCtrl,
          addressCtrl: _addressCtrl,
          location: _location,
          onLocation: (l) => setState(() => _location = l),
          photos: _photos,
          onAdd: (files) => setState(() => _photos.addAll(files)),
          onRemove: (i) => setState(() => _photos.removeAt(i)),
          onReorder: (oldIndex, newIndex) => setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _photos.removeAt(oldIndex);
            _photos.insert(newIndex, item);
          }),
        ),
      _ => _Step1DetailsCombined(
          key: const ValueKey(1),
          modality: _modality,
          materials: _materials,
          workersNeeded: _workersNeeded,
          isUrgent: _isUrgent,
          onModality: (v) => setState(() => _modality = v),
          onMaterials: (v) => setState(() => _materials = v),
          onWorkers: (v) => setState(() => _workersNeeded = v),
          onUrgent: (v) => setState(() => _isUrgent = v),
          title: _titleCtrl.text,
          category: _category,
          address: _addressCtrl.text,
          budget: double.tryParse(_minCtrl.text),
          photosCount: _photos.length,
        ),
    };
  }
}

// ─── Header y Footer ─────────────────────────────────────────────────────────

class _CreateJobHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final List<String> stepLabels;
  final VoidCallback onBack;

  const _CreateJobHeader({
    required this.step,
    required this.totalSteps,
    required this.stepLabels,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${step + 1} de $totalSteps',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      stepLabels[step],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / totalSteps,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CreateJobFooter extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool isLoading;
  final String? error;
  final VoidCallback onNext;
  final VoidCallback? onDraft;

  const _CreateJobFooter({
    required this.step,
    required this.totalSteps,
    required this.isLoading,
    required this.error,
    required this.onNext,
    this.onDraft,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast ? 'Publicar trabajo' : 'Continuar',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Paso 0: Información General Combined ───────────────────────────────────────────

class _Step0InfoCombined extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String category;
  final ValueChanged<String> onCategory;
  final TextEditingController minCtrl;
  final TextEditingController addressCtrl;
  final LatLng? location;
  final ValueChanged<LatLng> onLocation;
  final List<File> photos;
  final ValueChanged<List<File>> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _Step0InfoCombined({
    super.key,
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.category,
    required this.onCategory,
    required this.minCtrl,
    required this.addressCtrl,
    required this.location,
    required this.onLocation,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SLabel('Categoría *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              items: _kCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onCategory(v);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined, size: 18),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _SLabel('Título del trabajo *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleCtrl,
              maxLength: 80,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ej: Reparación de tubería o Pintura de sala',
                prefixIcon: Icon(Icons.work_outline, size: 18),
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Mínimo 5 caracteres'
                  : null,
            ),
            const SizedBox(height: 14),
            const _SLabel('Descripción *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: descCtrl,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Describe el trabajo con el mayor detalle posible...',
              ),
              validator: (v) => (v == null || v.trim().length < 15)
                  ? 'Mínimo 15 caracteres'
                  : null,
            ),
            const SizedBox(height: 14),
            const _SLabel('Pago ofrecido (S/) *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                prefixText: 'S/   ',
                hintText: 'Ej: 150',
                prefixIcon: Icon(Icons.payments_outlined, size: 18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa el pago';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const _SLabel('Dirección de referencia *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: addressCtrl,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ej: Av. Larco 1234, Miraflores',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa la dirección'
                  : null,
            ),
            const SizedBox(height: 16),
            const _SLabel('Punto en el mapa'),
            const SizedBox(height: 8),
            const Text(
              'Toca el mapa para marcar la ubicación exacta del trabajo.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ubicación: ${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            RepaintBoundary(
              child: OsmMapWidget(
                latitude: location?.latitude ?? -12.1186,
                longitude: location?.longitude ?? -77.0318,
                zoom: 14,
                height: 200,
                markers: location != null
                    ? [
                        MapJobMarker(
                          id: 'sel',
                          latitude: location!.latitude,
                          longitude: location!.longitude,
                          title: 'Ubicación',
                        ),
                      ]
                    : [],
                onTap: onLocation,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                try {
                  final result = await LocationService.getCurrentLocation();
                  if (result != null) {
                    onLocation(LatLng(result.latitude, result.longitude));
                    final addressStr = '${result.district}, ${result.province}';
                    if (addressCtrl.text.trim().isEmpty) {
                      addressCtrl.text = addressStr;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ubicación detectada: $addressStr'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Usar mi ubicación actual GPS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SLabel('Fotos del trabajo (Opcional)'),
            const SizedBox(height: 4),
            const Text(
              'Agrega hasta 5 imágenes claras sobre lo que necesitas hacer.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ImageActionBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Cámara',
                  onTap: () async {
                    if (photos.length >= 5) return;
                    final file = await ImagePickerService.pickSingleImage(context);
                    if (file != null) onAdd([file]);
                  },
                ),
                const SizedBox(width: 12),
                _ImageActionBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Galería',
                  onTap: () async {
                    if (photos.length >= 5) return;
                    final files = await ImagePickerService.pickMultipleImages();
                    if (files.isNotEmpty) {
                      onAdd(files.take(5 - photos.length).toList());
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photos.isEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.textHint,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sin fotos agregadas aún',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 90,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  onReorder: onReorder,
                  itemBuilder: (ctx, idx) {
                    final file = photos[idx];
                    return _ImageTile(
                      key: ValueKey(file.path),
                      file: file,
                      onRemove: () => onRemove(idx),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Paso 1: Detalles y Publicación Combined ──────────────────────────────────────────

class _Step1DetailsCombined extends StatelessWidget {
  final String modality;
  final String materials;
  final int workersNeeded;
  final bool isUrgent;
  final ValueChanged<String> onModality;
  final ValueChanged<String> onMaterials;
  final ValueChanged<int> onWorkers;
  final ValueChanged<bool> onUrgent;

  final String title;
  final String category;
  final String address;
  final double? budget;
  final int photosCount;

  const _Step1DetailsCombined({
    super.key,
    required this.modality,
    required this.materials,
    required this.workersNeeded,
    required this.isUrgent,
    required this.onModality,
    required this.onMaterials,
    required this.onWorkers,
    required this.onUrgent,
    required this.title,
    required this.category,
    required this.address,
    required this.budget,
    required this.photosCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${budget?.toStringAsFixed(2) ?? "0.00"}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (photosCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.photo_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$photosCount imágenes adjuntadas',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SLabel('Frecuencia del pago'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: modality,
            items: _kModalities.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onModality(v);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.schedule_outlined, size: 18),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14),
            isExpanded: true,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _SLabel('¿Quién proporciona los materiales?'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: materials,
            items: _kMaterials.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onMaterials(v);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.handyman_outlined, size: 18),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14),
            isExpanded: true,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _SLabel('Trabajadores necesarios'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cantidad de personal',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                      onPressed: workersNeeded > 1 ? () => onWorkers(workersNeeded - 1) : null,
                    ),
                    Text(
                      '$workersNeeded',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: workersNeeded < 10 ? () => onWorkers(workersNeeded + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text(
                '¿Es un trabajo urgente?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Aparecerá destacado en la lista principal',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11),
              ),
              value: isUrgent,
              activeColor: AppColors.primary,
              onChanged: onUrgent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Auxiliary Helpers ──────────────────────────────────────────────────────────

class _ImageActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImageActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _ImageTile({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SLabel extends StatelessWidget {
  final String text;
  const _SLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}
