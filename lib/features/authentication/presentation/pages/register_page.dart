import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/constants/ubigeo_peru.dart';
import 'package:laboraya_app/core/services/auth_service.dart';
import 'package:laboraya_app/core/services/location_service.dart';

// ─── Constantes ─────────────────────────────────────────────────────────────

// Pasos soportados por el backend actual
// Paso 0: datos personales  → campos: firstName, lastName, email, phone, password
// Paso 1: tipo de perfil    → campo:  userType
// Paso 2: ubicación         → UI-only (backend no soporta aún)
// Paso 3: categorías        → UI-only (backend no soporta aún)
// Paso 4: confirmación      → envía al endpoint /auth/register

const int _kTotalSteps = 4;

const _kStepLabels = [
  'Datos personales',
  'Ubicación',
  'Mis intereses',
  'Confirmar',
];

// ─── RegisterPage ────────────────────────────────────────────────────────────

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  int _step = 0;

  // ── Paso 0: Datos personales ─────────────────────────────
  final _step0Key = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ── Paso 1: Tipo de perfil ────────────────────────────────
  String _userType = 'WORKER';

  // ── Paso 2: Ubicación ──────────────────────────────────────
  String _department = '';
  final _provinceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  // ── Paso 3: Categorías ────────────────────────────────────
  final Set<String> _selectedCategories = {};

  // ── Paso 4: Submit ─────────────────────────────────────────
  bool _isLoading = false;
  String? _submitError;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  // ── Navegación entre pasos ────────────────────────────────

  void _next() {
    if (_step == 0 && !_step0Key.currentState!.validate()) return;
    if (_step < _kTotalSteps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  // ── Submit ──────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _submitError = null;
    });
    try {
      final ok = await ref
          .read(authServiceProvider)
          .register(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            userType: _userType,
          );
      if (!mounted) return;
      if (ok) {
        context.go('/');
      } else {
        setState(() {
          _isLoading = false;
          _submitError = 'No se pudo crear la cuenta. Intenta de nuevo.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitError = _dioMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      setState(() {
        _isLoading = false;
        _submitError = msg.isNotEmpty
            ? msg
            : 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  String _dioMessage(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      final msg = responseData['datos'] ?? responseData['mensaje'] ?? responseData['message'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Verifica tu internet.';
      case DioExceptionType.connectionError:
        return 'Sin conexión. Verifica tu internet.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 409) return 'Este correo ya está registrado.';
        if (status != null && status >= 500) {
          return 'Error del servidor. Intenta más tarde.';
        }
        return 'No se pudo crear la cuenta. Intenta de nuevo.';
      default:
        return 'Sin conexión. Verifica tu internet.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _RegisterHeader(
                step: _step,
                totalSteps: _kTotalSteps,
                stepLabels: _kStepLabels,
                onBack: _back,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
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
              _RegisterFooter(
                step: _step,
                totalSteps: _kTotalSteps,
                isLoading: _isLoading,
                error: _step == _kTotalSteps - 1 ? _submitError : null,
                onNext: _next,
                onLogin: () => context.go('/auth/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _StepPersonalData(
        key: const ValueKey(0),
        formKey: _step0Key,
        firstNameCtrl: _firstNameCtrl,
        lastNameCtrl: _lastNameCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
        passCtrl: _passCtrl,
        confirmPassCtrl: _confirmPassCtrl,
      ),
      1 => _StepLocation(
        key: const ValueKey(1),
        department: _department,
        provinceCtrl: _provinceCtrl,
        districtCtrl: _districtCtrl,
        onDepartment: (v) => setState(() => _department = v),
      ),
      2 => _StepCategories(
        key: const ValueKey(2),
        selected: _selectedCategories,
        onToggle: (cat) => setState(() {
          if (_selectedCategories.contains(cat)) {
            _selectedCategories.remove(cat);
          } else {
            _selectedCategories.add(cat);
          }
        }),
      ),
      _ => _StepConfirm(
        key: const ValueKey(3),
        firstName: _firstNameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        userType: _userType,
        district: _districtCtrl.text.isNotEmpty ? _districtCtrl.text : null,
        categories: _selectedCategories,
      ),
    };
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final List<String> stepLabels;
  final VoidCallback onBack;

  const _RegisterHeader({
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / totalSteps,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _RegisterFooter extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool isLoading;
  final String? error;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const _RegisterFooter({
    required this.step,
    required this.totalSteps,
    required this.isLoading,
    required this.error,
    required this.onNext,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error del paso final
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: error != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
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
                  )
                : const SizedBox.shrink(),
          ),
          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
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
                      isLast ? 'Crear cuenta' : 'Continuar',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Botones sociales (solo en paso 0) ────────────────────────
          if (step == 0) ...[
            Row(
              children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFEAECF0))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o regístrate con',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFEAECF0))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RegSocialIconButton(
                    iconAsset: 'assets/icons/facebook.png',
                    fallbackIcon: Icons.facebook,
                    fallbackColor: const Color(0xFF1877F2),
                    onTap: _regSignInWithFacebook,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RegSocialIconButton(
                    iconAsset: 'assets/icons/gmail.png',
                    fallbackIcon: Icons.g_mobiledata,
                    fallbackColor: const Color(0xFFEA4335),
                    onTap: _regSignInWithGoogle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Ya tienes cuenta?  ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onLogin,
                child: const Text(
                  'Inicia sesión',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Paso 0: Datos personales ─────────────────────────────────────────────────

// ─── Paso 0: Datos personales ─────────────────────────────────────────────────

class _StepPersonalData extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;

  const _StepPersonalData({
    super.key,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
  });

  @override
  State<_StepPersonalData> createState() => _StepPersonalDataState();
}

class _StepPersonalDataState extends State<_StepPersonalData> {
  @override
  void initState() {
    super.initState();
    widget.passCtrl.addListener(_onPassChanged);
  }

  @override
  void dispose() {
    widget.passCtrl.removeListener(_onPassChanged);
    super.dispose();
  }

  void _onPassChanged() {
    if (mounted) setState(() {});
  }

  int _calculateStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass) || RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final passText = widget.passCtrl.text;
    final strength = _calculateStrength(passText);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle(
              title: 'Cuéntanos sobre ti',
              subtitle: 'Esta información se usará para crear tu perfil profesional.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: widget.firstNameCtrl,
                    hint: 'Nombres',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    ctrl: widget.lastNameCtrl,
                    hint: 'Apellidos',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Field(
              ctrl: widget.emailCtrl,
              hint: 'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Correo electrónico inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              ctrl: widget.phoneCtrl,
              hint: 'Número de celular',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu celular';
                if (v.trim().length < 9) return 'Número de celular inválido (mínimo 9 dígitos)';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _PasswordField(
              ctrl: widget.passCtrl,
              hint: 'Contraseña fuerte (Mín. 8 caracteres, mayúscula y números)',
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 8) return 'La contraseña debe tener mínimo 8 caracteres';
                if (!RegExp(r'[A-Z]').hasMatch(v)) {
                  return 'Debe incluir al menos una letra mayúscula (A-Z)';
                }
                if (!RegExp(r'[0-9]').hasMatch(v) && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                  return 'Debe incluir al menos un número (0-9) o símbolo';
                }
                return null;
              },
            ),

            // Indicador de fortaleza de contraseña
            if (passText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (index) {
                  Color barColor = Colors.grey.shade300;
                  if (index < strength) {
                    if (strength <= 1) {
                      barColor = AppColors.error;
                    } else if (strength <= 3) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.green;
                    }
                  }
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                strength <= 1
                    ? 'Seguridad: Débil (agrega mayúsculas y números)'
                    : strength <= 3
                        ? 'Seguridad: Media'
                        : 'Seguridad: Excelente (Fuerte)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: strength <= 1
                      ? AppColors.error
                      : strength <= 3
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                ),
              ),
            ],

            const SizedBox(height: 14),
            _PasswordField(
              ctrl: widget.confirmPassCtrl,
              hint: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                if (v != widget.passCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Paso 1: Tipo de perfil ───────────────────────────────────────────────────

class _StepProfileType extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _StepProfileType({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: '¿Cómo usarás\nLaboraYa?',
            subtitle:
                'Puedes cambiar tu modo desde la aplicación en cualquier momento.',
          ),
          const SizedBox(height: 24),
          _TypeCard(
            icon: Icons.engineering_rounded,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primary,
            title: 'Quiero encontrar trabajo',
            subtitle:
                'Ofrece tus servicios, aplica a cachuelos y conecta con clientes en tu zona.',
            value: 'WORKER',
            selected: selected,
            onTap: () => onChanged('WORKER'),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            icon: Icons.business_center_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: AppColors.warning,
            title: 'Quiero contratar profesionales',
            subtitle: 'Publica requerimientos y encuentra personal confiable rápidamente.',
            value: 'EMPLOYER',
            selected: selected,
            onTap: () => onChanged('EMPLOYER'),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            icon: Icons.swap_horiz_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            title: 'Quiero ambas cosas',
            subtitle: 'Ofrece tus servicios y contrata profesionales desde un solo perfil.',
            value: 'BOTH',
            selected: selected,
            onTap: () => onChanged('BOTH'),
          ),
        ],
      ),
    );
  }
}

// ─── Paso 2: Ubicación ────────────────────────────────────────────────────────

// ─── Paso 2: Ubicación ────────────────────────────────────────────────────────

class _StepLocation extends StatefulWidget {
  final String department;
  final TextEditingController provinceCtrl;
  final TextEditingController districtCtrl;
  final ValueChanged<String> onDepartment;

  const _StepLocation({
    super.key,
    required this.department,
    required this.provinceCtrl,
    required this.districtCtrl,
    required this.onDepartment,
  });

  @override
  State<_StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends State<_StepLocation> {
  bool _isFetchingGps = false;

  Future<void> _handleFetchLocation() async {
    setState(() => _isFetchingGps = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (result != null) {
        widget.onDepartment(result.department);
        widget.provinceCtrl.text = result.province;
        widget.districtCtrl.text = result.district;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ubicación GPS obtenida: ${result.district}, ${result.province}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDept = widget.department.isEmpty ? 'Lima' : widget.department;
    final provincias = UbigeoPeru.getProvincias(currentDept);
    final distritos = UbigeoPeru.getDistritos(currentDept);

    final String currentProvince = widget.provinceCtrl.text.isEmpty && provincias.isNotEmpty
        ? provincias.first
        : widget.provinceCtrl.text;
    if (widget.provinceCtrl.text.isEmpty && provincias.isNotEmpty) {
      widget.provinceCtrl.text = provincias.first;
    }

    final String currentDistrict = widget.districtCtrl.text;
    final bool isProvinceInList = provincias.contains(currentProvince);
    final bool isDistrictInList = distritos.contains(currentDistrict);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: '¿Dónde estás ubicado?',
            subtitle: 'Te mostraremos ofertas laborales y profesionales cerca de tu zona.',
          ),
          const SizedBox(height: 24),

          // Selector de departamento
          _DropdownField(
            label: 'Departamento',
            value: widget.department.isEmpty ? 'Lima' : widget.department,
            items: UbigeoPeru.departamentos,
            icon: Icons.location_city_outlined,
            onChanged: (val) {
              widget.onDepartment(val);
              final newProvincias = UbigeoPeru.getProvincias(val);
              if (newProvincias.isNotEmpty) {
                widget.provinceCtrl.text = newProvincias.first;
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 14),

          // Selector pre-cargado de Provincia
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provincia',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: isProvinceInList ? currentProvince : (provincias.isNotEmpty ? provincias.first : null),
                items: provincias
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      widget.provinceCtrl.text = v;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Selecciona tu provincia',
                  prefixIcon: Icon(Icons.map_outlined, size: 18, color: AppColors.textHint),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                isExpanded: true,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selector pre-cargado de Distrito (43 distritos de Lima)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distrito',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: isDistrictInList ? currentDistrict : null,
                items: distritos
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      widget.districtCtrl.text = v;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Selecciona tu distrito',
                  prefixIcon: Icon(Icons.place_outlined, size: 18, color: AppColors.textHint),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                isExpanded: true,
              ),
              if (!isDistrictInList && currentDistrict.isNotEmpty) ...[
                const SizedBox(height: 10),
                _Field(
                  ctrl: widget.districtCtrl,
                  hint: 'Distrito personalizado',
                  icon: Icons.edit_location_alt_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Botón GPS Real
          GestureDetector(
            onTap: _isFetchingGps ? null : _handleFetchLocation,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _isFetchingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isFetchingGps
                          ? 'Obteniendo ubicación GPS...'
                          : 'Usar mi ubicación actual (GPS)',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paso 3: Categorías de Cachuelos y Servicios en Perú ──────────────────────

class _StepCategories extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _StepCategories({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  static const _categories = [
    ('Gasfitería y Plomería', Icons.water_drop_rounded),
    ('Electricidad y Cableado', Icons.electrical_services_rounded),
    ('Pintura y Acabados', Icons.format_paint_rounded),
    ('Carpintería y Melamina', Icons.carpenter_rounded),
    ('Albañilería y Construcción', Icons.construction_rounded),
    ('Limpieza de Casas y Oficinas', Icons.cleaning_services_rounded),
    ('Cerrajería 24 Horas', Icons.lock_rounded),
    ('Mecánica de Auto y Moto', Icons.build_rounded),
    ('Jardinería y Paisajismo', Icons.grass_rounded),
    ('Mudanzas, Fletes y Carga', Icons.local_shipping_rounded),
    ('Reparación de Artefactos', Icons.kitchen_rounded),
    ('Técnico PC y Celulares', Icons.computer_rounded),
    ('Costura, Confección y Sastrería', Icons.checkroom_rounded),
    ('Cuidado de Adultos Mayores', Icons.elderly_rounded),
    ('Cuidado de Niños / Nanas', Icons.child_care_rounded),
    ('Paseador y Cuidado de Mascotas', Icons.pets_rounded),
    ('Asistente del Hogar y Cocina', Icons.restaurant_rounded),
    ('Chofer / Conductor Privado', Icons.directions_car_rounded),
    ('Eventos, Catering y Mozos', Icons.flatware_rounded),
    ('Atención al Cliente y Ventas', Icons.storefront_rounded),
    ('Seguridad y Vigilancia', Icons.security_rounded),
    ('Belleza, Barbería y Manicure', Icons.content_cut_rounded),
    ('Clases Particulares / Tutoría', Icons.school_rounded),
    ('Mensajería y Delivery Express', Icons.delivery_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Categorías de interés',
            subtitle:
                'Selecciona los servicios que ofreces o buscas contratar. Puedes elegir varias.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((cat) {
              final isSel = selected.contains(cat.$1);
              return GestureDetector(
                onTap: () => onToggle(cat.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.$2,
                        size: 16,
                        color: isSel ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.$1,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${selected.length} categoría${selected.length == 1 ? '' : 's'} seleccionada${selected.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Paso 4: Confirmación ─────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  final String firstName;
  final String email;
  final String phone;
  final String userType;
  final String? district;
  final Set<String> categories;

  const _StepConfirm({
    super.key,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.userType,
    this.district,
    required this.categories,
  });

  String get _userTypeLabel => switch (userType) {
    'WORKER' => 'Trabajador / Profesional',
    'EMPLOYER' => 'Empleador / Contratante',
    _ => 'Trabajador y empleador',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: '¡Todo listo!',
            subtitle: 'Confirma tus datos para crear tu cuenta en LaboraYa.',
          ),
          const SizedBox(height: 24),
          _SummaryCard(
            title: 'Resumen de tu cuenta',
            rows: [
              _SummaryRow(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: firstName.isEmpty ? '—' : firstName,
              ),
              _SummaryRow(
                icon: Icons.email_outlined,
                label: 'Correo',
                value: email.isEmpty ? '—' : email,
              ),
              _SummaryRow(
                icon: Icons.phone_outlined,
                label: 'Celular',
                value: phone.isEmpty ? '—' : phone,
              ),
              _SummaryRow(
                icon: Icons.engineering_rounded,
                label: 'Modo',
                value: _userTypeLabel,
              ),
              if (district != null && district!.isNotEmpty)
                _SummaryRow(
                  icon: Icons.place_outlined,
                  label: 'Ubicación',
                  value: district!,
                ),
              if (categories.isNotEmpty)
                _SummaryRow(
                  icon: Icons.category_outlined,
                  label: 'Intereses',
                  value:
                      categories.take(3).join(', ') +
                      (categories.length > 3
                          ? ' +${categories.length - 3}'
                          : ''),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Al presionar "Crear cuenta" aceptas los Términos de Servicio y la Política de Privacidad de LaboraYa.',
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
    );
  }
}

// ─── Widgets reutilizables internos ──────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _UiOnlyBanner extends StatelessWidget {
  final String message;
  const _UiOnlyBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  bool get _isSel => value == selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSel ? AppColors.primary : AppColors.border,
            width: _isSel ? 2 : 1,
          ),
          boxShadow: _isSel
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isSel ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _isSel ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSel ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: _isSel
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<_SummaryRow> rows;
  final bool isUiOnly;

  const _SummaryCard({
    required this.title,
    required this.rows,
    this.isUiOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 0.3,
              ),
            ),
            if (isUiOnly) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Solo local',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: rows.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < rows.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Campos de formulario ─────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.ctrl,
    required this.hint,
    this.textInputAction,
    this.validator,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.ctrl,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: AppColors.textHint,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.textHint,
          ),
          tooltip: _visible ? 'Ocultar' : 'Mostrar',
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
      ),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
      isExpanded: true,
    );
  }
}


// ─── Botón social registro — solo ícono (como la foto) ────────────────────────

class _RegSocialIconButton extends StatelessWidget {
  final String iconAsset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;

  const _RegSocialIconButton({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE4E7EC), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Center(
          child: Image.asset(
            iconAsset,
            width: 66, height: 66,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 66, color: fallbackColor),
          ),
        ),
      ),
    );
  }
}

// ─── Botón social registro (PNG) ──────────────────────────────────────────────

class _RegSocialButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _RegSocialButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE4E7EC), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF344054),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.public, size: 26, color: Color(0xFF98A2B3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),
            ),
            const SizedBox(width: 26),
          ],
        ),
      ),
    );
  }
}

// ─── Auth social placeholder (registro) ──────────────────────────────────────

Future<void> _regSignInWithGoogle() async {
  // TODO: Integrar Google Sign-In para registro.
  // Requiere el paquete `google_sign_in` y configuración de Firebase.
}

Future<void> _regSignInWithFacebook() async {
  // TODO: Integrar Facebook Login para registro.
  // Requiere el paquete `flutter_facebook_auth` y configuración de Facebook App.
}
