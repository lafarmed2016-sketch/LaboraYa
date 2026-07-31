import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/applications/presentation/providers/applications_provider.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

// ─── Pasos internos ──────────────────────────────────────────────────────────
enum _ApplyStep { form, review, processing, success }

// ─── ApplyPage ────────────────────────────────────────────────────────────────

class ApplyPage extends ConsumerStatefulWidget {
  final JobEntity job;
  const ApplyPage({super.key, required this.job});

  @override
  ConsumerState<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends ConsumerState<ApplyPage> {
  _ApplyStep _step = _ApplyStep.form;

  // Formulario
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  bool _workerMaterials = false;
  String? _applicationId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prellena el presupuesto con el valor del trabajo
    if (widget.job.budgetMin != null) {
      _budgetCtrl.text = widget.job.budgetMin!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _budgetCtrl.dispose();
    _availabilityCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _step = _ApplyStep.processing;
      _errorMessage = null;
    });

    // Simula un mínimo de 1.2 s para que el estado "procesando" sea visible
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final ok = await ref
          .read(applicationsProvider.notifier)
          .apply(
            jobId: widget.job.id,
            jobTitle: widget.job.title,
            employerName: widget.job.publisherName,
            budget: double.tryParse(_budgetCtrl.text) ?? 0,
            message: _msgCtrl.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        // Obtiene el ID generado del primer elemento insertado
        final apps = ref.read(applicationsProvider);
        _applicationId = apps.isNotEmpty ? apps.first.id : null;
        setState(() => _step = _ApplyStep.success);
      } else {
        setState(() {
          _step = _ApplyStep.form;
          _errorMessage = 'No se pudo enviar la postulación. Intenta de nuevo.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _ApplyStep.form;
        _errorMessage = 'Sin conexión. Verifica tu internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Evitar salir accidentalmente durante el procesamiento
      canPop: _step != _ApplyStep.processing,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: switch (_step) {
            _ApplyStep.form => _FormStep(
              key: const ValueKey('form'),
              formKey: _formKey,
              job: widget.job,
              msgCtrl: _msgCtrl,
              budgetCtrl: _budgetCtrl,
              availabilityCtrl: _availabilityCtrl,
              timeCtrl: _timeCtrl,
              workerMaterials: _workerMaterials,
              errorMessage: _errorMessage,
              onWorkerMaterials: (v) => setState(() => _workerMaterials = v),
              onBack: () => context.pop(),
              onNext: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _step = _ApplyStep.review);
                }
              },
            ),
            _ApplyStep.review => _ReviewStep(
              key: const ValueKey('review'),
              job: widget.job,
              message: _msgCtrl.text,
              budget: double.tryParse(_budgetCtrl.text) ?? 0,
              availability: _availabilityCtrl.text,
              estimatedTime: _timeCtrl.text,
              workerMaterials: _workerMaterials,
              onBack: () => setState(() => _step = _ApplyStep.form),
              onSubmit: _submit,
            ),
            _ApplyStep.processing => const _ProcessingStep(
              key: ValueKey('processing'),
            ),
            _ApplyStep.success => _SuccessStep(
              key: const ValueKey('success'),
              applicationId: _applicationId,
              jobTitle: widget.job.title,
              onMyApplications: () => context.go('/my-applications'),
              onExplore: () => context.go('/'),
            ),
          },
        ),
      ),
    );
  }
}

// ─── Paso 1: Formulario ───────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final JobEntity job;
  final TextEditingController msgCtrl;
  final TextEditingController budgetCtrl;
  final TextEditingController availabilityCtrl;
  final TextEditingController timeCtrl;
  final bool workerMaterials;
  final String? errorMessage;
  final ValueChanged<bool> onWorkerMaterials;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FormStep({
    super.key,
    required this.formKey,
    required this.job,
    required this.msgCtrl,
    required this.budgetCtrl,
    required this.availabilityCtrl,
    required this.timeCtrl,
    required this.workerMaterials,
    required this.errorMessage,
    required this.onWorkerMaterials,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar personalizado
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _CircleBack(onBack: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Postularme',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Barra de progreso paso 1/2
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _ProgressBar(step: 0, total: 2),
        ),
        // Formulario
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip del trabajo
                  _JobChip(job: job),
                  const SizedBox(height: 20),
                  // Mensaje
                  const _FieldLabel('Mensaje al empleador *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: msgCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    decoration: const InputDecoration(
                      hintText:
                          'Preséntate y explica por qué eres la persona adecuada...',
                      hintStyle: TextStyle(fontFamily: 'Poppins'),
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Escribe al menos 10 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Presupuesto propuesto
                  const _FieldLabel('Tu propuesta económica (S/) *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    decoration: InputDecoration(
                      prefixText: 'S/ ',
                      hintText: 'Ej: 150',
                      helperText:
                          'Presupuesto del trabajo: ${job.formattedBudget}',
                      helperStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa tu propuesta';
                      }
                      if (double.tryParse(v) == null) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Disponibilidad
                  const _FieldLabel('Disponibilidad'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: availabilityCtrl,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ej: Lunes a viernes, de 8 a. m. a 6 p. m.',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tiempo estimado
                  const _FieldLabel('Tiempo estimado'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: timeCtrl,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ej: 3 horas, 2 días',
                      prefixIcon: Icon(Icons.timer_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Materiales
                  Row(
                    children: [
                      Checkbox(
                        value: workerMaterials,
                        onChanged: (v) => onWorkerMaterials(v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Cuento con los materiales necesarios',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Error
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: errorMessage!),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Footer
        _Footer(label: 'Revisar postulación', onPressed: onNext),
      ],
    );
  }
}

// ─── Paso 2: Revisión ─────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final JobEntity job;
  final String message;
  final double budget;
  final String availability;
  final String estimatedTime;
  final bool workerMaterials;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _ReviewStep({
    super.key,
    required this.job,
    required this.message,
    required this.budget,
    required this.availability,
    required this.estimatedTime,
    required this.workerMaterials,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _CircleBack(onBack: onBack),
                const SizedBox(width: 12),
                const Text(
                  'Revisar y enviar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _ProgressBar(step: 1, total: 2),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trabajo
                _ReviewCard(
                  title: 'Trabajo',
                  rows: [
                    _ReviewRow('Título', job.title),
                    _ReviewRow('Presupuesto', job.formattedBudget),
                    _ReviewRow('Modalidad', job.modalityLabel),
                    _ReviewRow('Empleador', job.publisherName),
                    _ReviewRow('Ubicación', job.address ?? 'No especificada'),
                  ],
                ),
                const SizedBox(height: 14),
                // Propuesta
                _ReviewCard(
                  title: 'Tu propuesta',
                  rows: [
                    _ReviewRow(
                      'Presupuesto propuesto',
                      'S/ ${budget.toStringAsFixed(0)}',
                      highlight: true,
                    ),
                    if (availability.isNotEmpty)
                      _ReviewRow('Disponibilidad', availability),
                    if (estimatedTime.isNotEmpty)
                      _ReviewRow('Tiempo estimado', estimatedTime),
                    _ReviewRow(
                      'Materiales',
                      workerMaterials
                          ? 'Cuento con materiales'
                          : 'Sin materiales propios',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Mensaje
                _ReviewCard(
                  title: 'Mensaje',
                  rows: [],
                  body: message.isEmpty ? 'Sin mensaje' : message,
                ),
                const SizedBox(height: 14),
                // Condiciones
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al enviar, aceptas los Términos de LaboraYa. '
                          'El empleador revisará tu postulación y te contactará por chat.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.primary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Footer(label: 'Enviar postulación', onPressed: onSubmit),
      ],
    );
  }
}

// ─── Paso 3: Procesando ───────────────────────────────────────────────────────

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 28),
          Text(
            'Estamos enviando\ntu postulación...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Por favor espera un momento.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paso 4: Éxito ────────────────────────────────────────────────────────────

class _SuccessStep extends StatefulWidget {
  final String? applicationId;
  final String jobTitle;
  final VoidCallback onMyApplications;
  final VoidCallback onExplore;

  const _SuccessStep({
    super.key,
    required this.applicationId,
    required this.jobTitle,
    required this.onMyApplications,
    required this.onExplore,
  });

  @override
  State<_SuccessStep> createState() => _SuccessStepState();
}

class _SuccessStepState extends State<_SuccessStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.applicationId != null
        ? '#${widget.applicationId!.substring(0, 8).toUpperCase()}'
        : '#APP00001';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
        child: Column(
          children: [
            // Check animado
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  const Text(
                    '¡Tu postulación\nfue enviada!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.jobTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 28),
                  // Card resumen
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _ReviewRow('Código', code),
                        const SizedBox(height: 8),
                        _ReviewRow('Estado', 'Enviada'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Estado',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Enviada',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onMyApplications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Ver mis postulaciones',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.onExplore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Seguir explorando',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (step + 1) / total,
        backgroundColor: AppColors.border,
        color: AppColors.primary,
        minHeight: 4,
      ),
    );
  }
}

class _JobChip extends StatelessWidget {
  final JobEntity job;
  const _JobChip({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${job.formattedBudget} · ${job.modalityLabel}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final List<_ReviewRow> rows;
  final String? body;

  const _ReviewCard({required this.title, required this.rows, this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (body != null)
            Text(
              body!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            )
          else
            ...rows.map(
              (r) =>
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: r),
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ReviewRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Footer({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  final VoidCallback onBack;
  const _CircleBack({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
