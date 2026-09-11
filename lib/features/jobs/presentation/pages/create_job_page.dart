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

// ─── PeruCategoryItem ────────────────────────────────────────────────────────
class PeruCategoryItem {
  final String name;
  final IconData icon;
  final String group;
  final List<String> keywords;
  final bool isPopular;

  const PeruCategoryItem({
    required this.name,
    required this.icon,
    required this.group,
    this.keywords = const [],
    this.isPopular = false,
  });
}

// ─── Directorio Completo de Categorías y Trabajos en Perú ────────────────────
const List<PeruCategoryItem> _allPeruCategories = [
  // Popular en Perú
  PeruCategoryItem(name: 'Gasfitería', icon: Icons.water_drop_rounded, group: 'Hogar', isPopular: true, keywords: ['tubería', 'fuga', 'agua', 'grifo', 'inodoro', 'desagüe', 'gasfitero', 'plomería']),
  PeruCategoryItem(name: 'Electricidad', icon: Icons.flash_on_rounded, group: 'Hogar', isPopular: true, keywords: ['luz', 'cable', 'tablero', 'tomacorriente', 'corto', 'electricista']),
  PeruCategoryItem(name: 'Pintura', icon: Icons.format_paint_rounded, group: 'Hogar', isPopular: true, keywords: ['pared', 'fachada', 'látex', 'esmalte', 'empaste', 'pintor']),
  PeruCategoryItem(name: 'Albañilería', icon: Icons.handyman_rounded, group: 'Hogar', isPopular: true, keywords: ['mayólica', 'porcelanato', 'muro', 'piso', 'tarrajeo', 'albañil', 'cemento']),
  PeruCategoryItem(name: 'Carpintería', icon: Icons.table_restaurant_rounded, group: 'Hogar', isPopular: true, keywords: ['mueble', 'ropero', 'repostero', 'mdf', 'puerta', 'carpintero']),
  PeruCategoryItem(name: 'Limpieza', icon: Icons.cleaning_services_rounded, group: 'Limpieza', isPopular: true, keywords: ['casa', 'hogar', 'depa', 'limpieza', 'post construccion']),
  PeruCategoryItem(name: 'Cerrajería', icon: Icons.lock_rounded, group: 'Técnicos', isPopular: true, keywords: ['chapa', 'llave', 'puerta', 'cerrajero', 'candado']),
  PeruCategoryItem(name: 'Sistemas y PC', icon: Icons.computer_rounded, group: 'Técnicos', isPopular: true, keywords: ['computadora', 'formateo', 'wifi', 'laptop', 'tecnico', 'programacion', 'sistemas', 'software']),
  PeruCategoryItem(name: 'Mecánica', icon: Icons.directions_car_rounded, group: 'Técnicos', isPopular: true, keywords: ['auto', 'carro', 'moto', 'aceite', 'frenos', 'mecanico']),
  PeruCategoryItem(name: 'Mudanzas', icon: Icons.local_shipping_rounded, group: 'Logística', isPopular: true, keywords: ['flete', 'carga', 'mudanza', 'camioneta', 'cargador']),
  PeruCategoryItem(name: 'Soldadura', icon: Icons.precision_manufacturing_rounded, group: 'Construcción', isPopular: true, keywords: ['reja', 'porton', 'soldador', 'fierro', 'metal']),
  PeruCategoryItem(name: 'Enfermería', icon: Icons.health_and_safety_rounded, group: 'Asistencia', isPopular: true, keywords: ['abuelo', 'enfermera', 'inyección', 'cuidado']),

  // Técnicos & Mantenimiento
  PeruCategoryItem(name: 'Electrodomésticos', icon: Icons.kitchen_rounded, group: 'Técnicos', keywords: ['lavadora', 'refrigeradora', 'cocina', 'microondas']),
  PeruCategoryItem(name: 'Aire Acondicionado', icon: Icons.ac_unit_rounded, group: 'Técnicos', keywords: ['aire', 'clima', 'split', 'mantenimiento']),
  PeruCategoryItem(name: 'Cámaras y Alarmas', icon: Icons.videocam_rounded, group: 'Técnicos', keywords: ['cctv', 'alarma', 'camara', 'cerco']),
  PeruCategoryItem(name: 'Reparación Celulares', icon: Icons.smartphone_rounded, group: 'Técnicos', keywords: ['pantalla', 'bateria', 'pin', 'celular']),
  PeruCategoryItem(name: 'Drywall', icon: Icons.grid_view_rounded, group: 'Construcción', keywords: ['tabiquería', 'techo falso', 'placa']),
  PeruCategoryItem(name: 'Techos y Goteras', icon: Icons.roofing_rounded, group: 'Construcción', keywords: ['gotera', 'calamina', 'policarbonato', 'impermeabilizado']),
  PeruCategoryItem(name: 'Fumigación', icon: Icons.bug_report_rounded, group: 'Limpieza', keywords: ['desinfeccion', 'insectos', 'chinche', 'cucaracha']),

  // Asistencia & Limpieza
  PeruCategoryItem(name: 'Asistencia Hogar', icon: Icons.local_laundry_service_rounded, group: 'Limpieza', keywords: ['planchado', 'ropa', 'doméstica']),
  PeruCategoryItem(name: 'Niñera', icon: Icons.child_care_rounded, group: 'Asistencia', keywords: ['babysitter', 'bebe', 'hijos']),
  PeruCategoryItem(name: 'Jardinería', icon: Icons.grass_rounded, group: 'Hogar', keywords: ['césped', 'poda', 'jardín', 'plantas']),

  // Construcción & Metalurgia
  PeruCategoryItem(name: 'Vidriería', icon: Icons.window_rounded, group: 'Construcción', keywords: ['vidrio', 'templado', 'mampara', 'espejo']),
  PeruCategoryItem(name: 'Mecanizado', icon: Icons.settings_suggest_rounded, group: 'Construcción', keywords: ['torno', 'metal', 'pieza']),
  PeruCategoryItem(name: 'Maquinaria', icon: Icons.agriculture_rounded, group: 'Construcción', keywords: ['excavadora', 'montacargas', 'retro']),

  // Logística & Transporte
  PeruCategoryItem(name: 'Conductor', icon: Icons.directions_bus_rounded, group: 'Logística', keywords: ['conductor', 'chofer', 'viaje', 'licencia']),
  PeruCategoryItem(name: 'Delivery', icon: Icons.two_wheeler_rounded, group: 'Logística', keywords: ['moto', 'delivery', 'paquete', 'courier']),

  // Gastronomía & Eventos
  PeruCategoryItem(name: 'Gastronomía', icon: Icons.restaurant_rounded, group: 'Gastronomía', isPopular: true, keywords: ['comida', 'buffet', 'parrilla', 'menu', 'cocina', 'chef']),
  PeruCategoryItem(name: 'Mozos y Eventos', icon: Icons.room_service_rounded, group: 'Gastronomía', keywords: ['mozo', 'banquete', 'matrimonio']),
  PeruCategoryItem(name: 'Panadería', icon: Icons.cake_rounded, group: 'Gastronomía', keywords: ['torta', 'bocadito', 'postre']),
  PeruCategoryItem(name: 'DJ y Sonido', icon: Icons.headset_mic_rounded, group: 'Eventos', keywords: ['fiesta', 'parlante', 'evento']),
  PeruCategoryItem(name: 'Fotografía', icon: Icons.camera_alt_rounded, group: 'Eventos', keywords: ['bodas', 'foto', 'camara', 'sesion']),

  // Servicios Varios
  PeruCategoryItem(name: 'Cosmetología y Barbería', icon: Icons.content_cut_rounded, group: 'Estética', isPopular: true, keywords: ['corte', 'tinte', 'manicure', 'barbero', 'barberia', 'peluqueria', 'estetica', 'cosmetologia']),
  PeruCategoryItem(name: 'Costura', icon: Icons.checkroom_rounded, group: 'Servicios', keywords: ['ropa', 'basta', 'vestido', 'sastre']),
  PeruCategoryItem(name: 'Diseño Gráfico', icon: Icons.palette_rounded, group: 'Servicios', keywords: ['logo', 'banner', 'diseno']),
  PeruCategoryItem(name: 'Contabilidad', icon: Icons.receipt_long_rounded, group: 'Servicios', keywords: ['contabilidad', 'impuestos', 'boleta', 'sunat']),
  PeruCategoryItem(name: 'Tutoría y Clases', icon: Icons.school_rounded, group: 'Servicios', keywords: ['profesor', 'matematica', 'ingles', 'clases']),
  PeruCategoryItem(name: 'Mascotas', icon: Icons.pets_rounded, group: 'Servicios', keywords: ['perro', 'veterinaria', 'gato']),
];

// ─── CreateJobPage ─────────────────────────────────────────────────────────────
// Flujo simplificado original: 1 sola pantalla con preguntas numeradas.
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

  String _selectedCategory = 'Gasfitería / Plomería';
  // ignore: prefer_final_fields
  String _selectedModality = 'PER_DAY';

  LatLng? _location;
  String? _locationLabel;
  bool _gpsLoading  = false;
  List<File> _photos = [];
  bool _isLoading   = false;
  String? _error;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── Modal Select2 Categorías en Perú ─────────────────────────────────────
  void _openCategorySelect2Modal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Select2CategoryModal(
        initialCategory: _selectedCategory,
        onCategorySelected: (catName) {
          setState(() {
            _selectedCategory = catName;
          });
        },
      ),
    );
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

  // ── Fotos Múltiples ─────────────────────────────────────────────
  Future<void> _pickPhotos() async {
    final list = await ImagePickerService.pickMultipleImages();
    if (list.isNotEmpty) {
      setState(() {
        for (final file in list) {
          if (!_photos.any((p) => p.path == file.path)) {
            _photos.add(file);
          }
        }
      });
    } else {
      final single = await ImagePickerService.pickSingleImage(context);
      if (single != null) {
        setState(() {
          if (!_photos.any((p) => p.path == single.path)) {
            _photos.add(single);
          }
        });
      }
    }
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
        categoryName: _selectedCategory,
        address: _locationLabel,
        latitude: _location?.latitude,
        longitude: _location?.longitude,
        modality: _selectedModality,
        budgetMin: double.tryParse(_budgetCtrl.text),
        budgetMax: double.tryParse(_budgetCtrl.text),
        isUrgent: false,
        materials: 'TO_COORDINATE',
        workersNeeded: 1,
        photos: _photos,
      );
      if (!mounted) return;
      if (ok) {
        ref.invalidate(myJobsProvider);
        _showSuccess();
      } else {
        final err = ref.read(jobsProvider).error ?? 'No se pudo publicar el trabajo en el servidor.';
        setState(() {
          _error = err;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  // ── Build Layout Original ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) { context.pop(); } else { context.go('/'); }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Cabecera Original ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) { context.pop(); } else { context.go('/'); }
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
                    const Text('¿Qué trabajo necesitas?',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Formulario Original ───────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 1 ── Categoría con Buscador Select2 ───────────────
                        const _Question(number: '1', text: 'Categoría'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openCategorySelect2Modal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.handyman_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedCategory,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 2 ── ¿Qué trabajo necesitas? ─────────
                        const _Question(number: '2', text: '¿Qué trabajo necesitas?'),
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

                        // 3 ── ¿Dónde? ─────────────────────────
                        const _Question(number: '3', text: '¿Dónde?'),
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

                        // 4 ── ¿Cuánto ofreces? ──────────────
                        const _Question(number: '4', text: '¿Cuánto ofreces?'),
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

                        // 5 ── ¿Deseas agregar fotos del trabajo? ───────
                        const _Question(number: '5', text: '¿Deseas agregar fotos del trabajo?', optional: true),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Botón Agregar Fotos
                              GestureDetector(
                                onTap: _pickPhotos,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        '+ Fotos',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Lista de fotos seleccionadas
                              ..._photos.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final f = entry.value;
                                return Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.file(f, fit: BoxFit.cover, width: 100, height: 100),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photos.removeAt(idx)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                           decoration: BoxDecoration(
                                             color: Colors.black.withValues(alpha: 0.7),
                                             shape: BoxShape.circle,
                                           ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 6 ── Comentario adicional ─────────────
                        const _Question(number: '6',
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

// ─── Modal Select2 Categorías en Perú ─────────────────────────────────────────
class _Select2CategoryModal extends StatefulWidget {
  final String initialCategory;
  final ValueChanged<String> onCategorySelected;

  const _Select2CategoryModal({
    required this.initialCategory,
    required this.onCategorySelected,
  });

  @override
  State<_Select2CategoryModal> createState() => _Select2CategoryModalState();
}

class _Select2CategoryModalState extends State<_Select2CategoryModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _query.length >= 2;
    
    final filteredCategories = showSearchResults
        ? _allPeruCategories.where((c) {
            final q = _query.toLowerCase();
            final matchesName = c.name.toLowerCase().contains(q);
            final matchesGroup = c.group.toLowerCase().contains(q);
            final matchesKeyword = c.keywords.any((k) => k.toLowerCase().contains(q));
            return matchesName || matchesGroup || matchesKeyword;
          }).toList()
        : _allPeruCategories;

    final popularList = _allPeruCategories.where((c) => c.isPopular).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.saved_search_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Categoría u Oficio',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Directorio completo de empleos en Perú',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Search Field Input (Select2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Escribe oficio (ej. gasfitería, pintura, chofer)...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
            ),
          ),

          // Search helper indicator bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(
                  showSearchResults ? Icons.filter_alt_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: showSearchResults ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  showSearchResults
                      ? '${filteredCategories.length} oficio(s) encontrado(s)'
                      : (_query.length == 1
                          ? 'Escribe al menos 2 letras para filtrar...'
                          : 'Popular en Perú. Escribe para buscar más oficios.'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: showSearchResults ? FontWeight.w600 : FontWeight.normal,
                    color: showSearchResults ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Category List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Option to use typed text directly if typed
                if (_query.trim().isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      widget.onCategorySelected(_query.trim());
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Usar "$_query" como oficio personalizado',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],

                // Popular Section Header when not filtering with >=2 chars
                if (!showSearchResults) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        SizedBox(width: 6),
                        Text(
                          'Más Solicitados en Perú',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...popularList.map((cat) => _CategoryListTile(
                        item: cat,
                        isSelected: widget.initialCategory.toLowerCase() == cat.name.toLowerCase(),
                        onTap: () {
                          widget.onCategorySelected(cat.name);
                          Navigator.pop(context);
                        },
                      )),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Todas las categorías y oficios',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],

                // Filtered List or Complete List
                ...filteredCategories.map((cat) => _CategoryListTile(
                      item: cat,
                      isSelected: widget.initialCategory.toLowerCase() == cat.name.toLowerCase(),
                      onTap: () {
                        widget.onCategorySelected(cat.name);
                        Navigator.pop(context);
                      },
                    )),

                if (showSearchResults && filteredCategories.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron coincidencias para "$_query"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final PeruCategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        tileColor: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            item.icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item.group,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Helpers de decoración Original ─────────────────────────────────────────

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

// ─── Widget de pregunta numerada Original ─────────────────────────────────────

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

// ─── Botón Publicar Original ──────────────────────────────────────────────────

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
