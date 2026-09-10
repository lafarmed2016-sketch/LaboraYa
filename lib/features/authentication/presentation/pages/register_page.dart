import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/auth_service.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';

// ─── RegisterPage — registro rápido en 1 pantalla ────────────────────────────
// Solo pide lo mínimo: nombre, apellido, correo, contraseña, confirmar.
// El resto (teléfono, DNI, foto, ubicación) se completa en /complete-profile.

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _confirmCtrl    = TextEditingController();

  bool _isLoading   = false;
  String? _error;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final ok = await ref.read(authServiceProvider).register(
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        phone:     '',          // se completará en /complete-profile
        password:  _passCtrl.text,
        userType:  'WORKER',    // valor por defecto; el rol real lo define el uso
      );
      if (!mounted) return;
      if (ok) {
        // Registro exitoso → completar perfil antes de entrar a la app
        context.go('/complete-profile');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo crear la cuenta. Intenta de nuevo.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _dioMsg(e);
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _isLoading = false;
        _error = raw.isNotEmpty ? raw : 'Ocurrió un error inesperado.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  String _dioMsg(DioException e) {
    final d = e.response?.data;
    if (d is Map) {
      final m = d['datos'] ?? d['mensaje'] ?? d['message'];
      if (m != null && m.toString().trim().isNotEmpty) return m.toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Verifica tu internet.';
      case DioExceptionType.connectionError:
        return 'Sin conexión. Verifica tu internet.';
      case DioExceptionType.badResponse:
        final s = e.response?.statusCode;
        if (s == 409) return 'Este correo ya está registrado.';
        if (s != null && s >= 500) return 'Error del servidor. Intenta más tarde.';
        return 'No se pudo crear la cuenta. Intenta de nuevo.';
      default:
        return 'Sin conexión. Verifica tu internet.';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() { _error = null; _isLoading = true; });

    try {
      final googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: '320726381262-pv5u18f1ki1sfp544prfvftbk7birpsv.apps.googleusercontent.com',
            )
          : GoogleSignIn(
              serverClientId: '320726381262-pv5u18f1ki1sfp544prfvftbk7birpsv.apps.googleusercontent.com',
            );

      final googleAccount = await googleSignIn.signIn();

      if (googleAccount == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('No se pudo obtener el usuario de Google.');

      final authService = ref.read(authServiceProvider);
      try {
        await authService.loginWithGoogleAccount(
          email: user.email ?? googleAccount.email,
          googleId: user.uid,
          displayName: user.displayName ?? googleAccount.displayName ?? 'Usuario Google',
        );
      } catch (_) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          final storage = ref.read(secureStorageProvider);
          await storage.saveAccessToken(idToken);
          await storage.saveUserId(user.uid);
          await storage.saveUsername(user.displayName ?? user.email ?? '');
        }
      }

      if (!mounted) return;

      ref.invalidate(profileProvider);
      ref.invalidate(jobsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(conversationsProvider);
      context.go('/');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          msg = 'Ya existe una cuenta con ese correo. Inicia sesión con email.';
          break;
        case 'invalid-credential':
          msg = 'Credencial inválida. Intenta de nuevo.';
          break;
        case 'user-disabled':
          msg = 'Esta cuenta ha sido deshabilitada.';
          break;
        default:
          msg = e.message ?? 'Error al registrarse con Google.';
      }
      setState(() { _error = msg; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      if (raw.contains('sign_in_canceled') || raw.contains('canceled') || raw.contains('12501')) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _error = raw.isNotEmpty
            ? raw
            : 'Error al conectar con Google. Verifica tu conexión.';
        _isLoading = false;
      });
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
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),

                    // ── Título ────────────────────────────────────────
                    const Text(
                      'Crear cuenta.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D4E),
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Solo te tomará un momento',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF8A8FA8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Nombre ───────────────────────────────────────
                    _RegField(
                      controller: _firstNameCtrl,
                      label: 'Nombre',
                      hint: 'Juan',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Apellido ──────────────────────────────────────
                    _RegField(
                      controller: _lastNameCtrl,
                      label: 'Apellido',
                      hint: 'Pérez',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu apellido'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Correo ────────────────────────────────────────
                    _RegField(
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      hint: 'ejemplo@correo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        final emailRx = RegExp(r'^[\w.+-]+@[\w-]+\.\w{2,}$');
                        if (!emailRx.hasMatch(v.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Contraseña ────────────────────────────────────
                    _RegPasswordField(
                      controller: _passCtrl,
                      label: 'Contraseña',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Confirmar contraseña ──────────────────────────
                    _RegPasswordField(
                      controller: _confirmCtrl,
                      label: 'Confirmar contraseña',
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                        if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),

                    // ── Error ─────────────────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.error,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 28),

                    // ── Botón Crear cuenta ────────────────────────────
                    _SubmitButton(isLoading: _isLoading, onTap: _submit),
                    const SizedBox(height: 24),

                    // ── Divider "o regístrate con" ────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 1, color: const Color(0xFFDDE1E7)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'o regístrate con',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF8A8FA8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: const Color(0xFFDDE1E7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Facebook + Google ─────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialBtn(
                            iconAsset: 'assets/icons/facebook.png',
                            fallbackIcon: Icons.facebook,
                            fallbackColor: const Color(0xFF1877F2),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SocialBtn(
                            iconAsset: 'assets/icons/gmail.png',
                            fallbackIcon: Icons.g_mobiledata,
                            fallbackColor: const Color(0xFFEA4335),
                            onTap: _handleGoogleSignIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── ¿Ya tienes cuenta? ────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta?  ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              color: Color(0xFF8A8FA8),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/login'),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón de submit ──────────────────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _SubmitButton({required this.isLoading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Campo de texto ───────────────────────────────────────────────────────────

class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _RegField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF1A1D4E),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFB0B5C8),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFB0B5C8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ─── Campo contraseña ─────────────────────────────────────────────────────────

class _RegPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _RegPasswordField({
    required this.controller,
    required this.label,
    this.textInputAction,
    this.validator,
  });

  @override
  State<_RegPasswordField> createState() => _RegPasswordFieldState();
}

class _RegPasswordFieldState extends State<_RegPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
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

    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF1A1D4E),
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        hintText: '••••••••',
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFB0B5C8),
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: Color(0xFFB0B5C8),
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: const Color(0xFFB0B5C8),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ─── Botón social ─────────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final String iconAsset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDE1E7), width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Center(
          child: Image.asset(
            iconAsset,
            width: 64,
            height: 64,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              size: 64,
              color: fallbackColor,
            ),
          ),
        ),
      ),
    );
  }
}
