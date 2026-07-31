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

// ─── CreateJobPage ─────────────────────────────────────────────────────────────
// Flujo simplificado: 1 sola pantalla con 5 preguntas + comentario.
// Sin pasos múltiples.

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController(); // ¿Qué trabajo necesitas?
  final _budgetCtrl  = TextEditingController(); // ¿Cuánto ofreces?
  final _commentCtrl = TextEditingController(); // Comentario adicional

  LatLng? _location;
  String? _locationLabel;
  bool _gpsLoading  = false;
  File? _photo;
  bool _isLoading   = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────
  Future<void> _useMyLocation() async {
    if (_gpsLoading) return;
    setState(() => _gpsLoading = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _location = LatLng(result.latitude, result.longitude);
          _locationLabel = '${result.district}, ${result.province}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Foto ───────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final file = await ImagePickerService.pickSingleImage(context);
    if (file != null) setState(() => _photo = file);
  }

  // ── Publicar ───────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_isLoading) return;
    setState(() { _autovalidate = AutovalidateMode.onUserInteraction; _error = null; });
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      setState(() => _error = 'Por favor indica la ubicación del trabajo.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final desc = _commentCtrl.text.trim().isNotEmpty
          ? _commentCtrl.text.trim()
          : _titleCtrl.text.trim();

      final ok = await ref.read(jobsProvider.notifier).createJobFromForm(
        title: _titleCtrl.text.trim(),
        description: desc,
        categoryName: 'Otros',
        address: _locationLabel,
        latitude: _location?.latitude,
        longitude: _location?.longitude,
        modality: 'PER_TASK',
        budgetMin: double.tryParse(_budgetCtrl.text),
        budgetMax: double.tryParse(_budgetCtrl.text),
        isUrgent: false,
        materials: 'TO_COORDINATE',
        workersNeeded: 1,
        photos: _photo != null ? [_photo!] : [],
      );
      if (!mounted) return;
      if (ok) {
        _showSuccess();
      } else {
        _addLocalJob();
      }
    } catch (_) {
      if (!mounted) return;
      _addLocalJob();
    }
  }

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  void _addLocalJob() {
    final newJob = JobEntity(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _commentCtrl.text.trim().isNotEmpty
          ? _commentCtrl.text.trim()
          : _titleCtrl.text.trim(),
      categoryId: 'cat_local',
      categoryName: 'Otros',
      address: _locationLabel ?? 'Lima',
      latitude: _location?.latitude ?? -12.1186,
      longitude: _location?.longitude ?? -77.0318,
      modality: 'PER_TASK',
      budgetMin: double.tryParse(_budgetCtrl.text),
      budgetMax: double.tryParse(_budgetCtrl.text),
      budgetFixed: true,
      materials: 'TO_COORDINATE',
      workersNeeded: 1,
      publisherId: 'user_current',
      publisherName: 'Tú',
      createdAt: DateTime.now(),
      publishedAt: DateTime.now(),
      images: _photo != null ? [_photo!.path] : [],
    );
    ref.read(jobsProvider.notifier).addJob(newJob);
    _showSuccess();
  }

  void _showSuccess() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Trabajo publicado con éxito!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) context.pop();
        else context.go('/');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Cabecera ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) context.pop();
                        else context.go('/');
                      },
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Publicar trabajo',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Formulario ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 1 ── ¿Qué trabajo necesitas? ─────────
                        _Question(number: '1', text: '¿Qué trabajo necesitas?'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
                          decoration: _inputDeco(
                              hint: 'Ej: Reparar una tubería, pintar sala...',
                              icon: Icons.work_outline_rounded),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v == null || v.trim().length < 5)
                              ? 'Mínimo 5 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 22),

                        // 2 ── ¿Dónde? ─────────────────────────
                        _Question(number: '2', text: '¿Dónde?'),
                        const SizedBox(height: 8),
                        // Botón GPS
                        GestureDetector(
                          onTap: _useMyLocation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _location != null
                                  ? AppColors.successLight
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _location != null
                                    ? AppColors.success
                                    : AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                _gpsLoading
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary))
                                    : Icon(
                                        _location != null
                                            ? Icons.check_circle_rounded
                                            : Icons.my_location_rounded,
                                        color: _location != null
                                            ? AppColors.success
                                            : AppColors.primary,
                                        size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _location != null
                                        ? (_locationLabel ?? 'Ubicación detectada')
                                        : 'Usar mi ubicación actual',
                                    style: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _location != null
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (_location != null)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _location = null; _locationLabel = null;
                                    }),
                                    child: const Icon(Icons.close_rounded,
                                        size: 16, color: AppColors.textHint),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Mini mapa si hay ubicación
                        if (_location != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: OsmMapWidget(
                              latitude: _location!.latitude,
                              longitude: _location!.longitude,
                              zoom: 15,
                              height: 140,
                              markers: [
                                MapJobMarker(
                                  id: 'sel',
                                  latitude: _location!.latitude,
                                  longitude: _location!.longitude,
                                  title: 'Trabajo',
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        // 3 ── ¿Cuánto ofreces? ──────────────
                        _Question(number: '3', text: '¿Cuánto ofreces?'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
                          decoration: _inputDeco(
                              hint: 'Ej: 120',
                              icon: Icons.payments_outlined,
                              prefix: 'S/   '),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) {
                              return 'Monto inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),

                        // 4 ── ¿Deseas agregar una foto? ───────
                        _Question(number: '4', text: '¿Deseas agregar una foto?'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: _photo != null
                                        ? Colors.transparent
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: _photo != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: Image.file(_photo!,
                                              fit: BoxFit.cover,
                                              width: double.infinity))
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined,
                                                color: AppColors.textHint, size: 28),
                                            SizedBox(height: 4),
                                            Text('Agregar foto',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: AppColors.textHint)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _photo = null),
                                child: Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: _photo == null
                                        ? AppColors.background
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _photo == null
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close_rounded,
                                          color: _photo == null
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                          size: 24),
                                      const SizedBox(height: 4),
                                      Text('Omitir',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _photo == null
                                                  ? AppColors.primary
                                                  : AppColors.textHint)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // 5 ── Comentario adicional ─────────────
                        _Question(number: '5',
                            text: 'Comentario adicional',
                            optional: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentCtrl,
                          maxLines: 3,
                          maxLength: 300,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                          decoration: _inputDeco(
                              hint: 'Ej: Necesito que traiga sus propias herramientas...',
                              icon: Icons.notes_rounded),
                        ),

                        // Error inline
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 17),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins', fontSize: 12,
                                        color: AppColors.error, height: 1.4))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Botón Publicar
                        _PublishButton(isLoading: _isLoading, onTap: _publish),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers de decoración ────────────────────────────────────────────────────

InputDecoration _inputDeco({
  required String hint,
  required IconData icon,
  String? prefix,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: Color(0xFFDDE1E7), width: 1.2),
  );
  const focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.primary, width: 1.8),
  );
  const errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.error, width: 1.2),
  );
  return InputDecoration(
    hintText: hint,
    prefixText: prefix,
    hintStyle: const TextStyle(
        fontFamily: 'Poppins', fontSize: 14, color: Color(0xFFB0B5C8)),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFFB0B5C8)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: focusBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: errorBorder,
    errorStyle: const TextStyle(
        fontFamily: 'Poppins', fontSize: 11, color: AppColors.error),
  );
}

// ─── Widget de pregunta numerada ──────────────────────────────────────────────

class _Question extends StatelessWidget {
  final String number;
  final String text;
  final bool optional;

  const _Question({
    required this.number,
    required this.text,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 12,
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Opcional',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 10,
                    color: AppColors.textSecondary)),
          ),
        ],
      ],
    );
  }
}

// ─── Botón Publicar ───────────────────────────────────────────────────────────

class _PublishButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _PublishButton({required this.isLoading, required this.onTap});

  @override
  State<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends State<_PublishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90),
        lowerBound: 0, upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_press);
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) { _press.reverse(); if (!widget.isLoading) widget.onTap(); },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading ? [] : [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Publicar',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}
