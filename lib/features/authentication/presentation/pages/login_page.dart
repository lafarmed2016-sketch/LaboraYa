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

// ─── Paleta del diseño ────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF4F5BD5); // azul-violeta del botón Login
const _kTitle     = Color(0xFF1A1D4E); // azul noche para el título
const _kSubtitle  = Color(0xFF8A8FA8);
const _kBorder    = Color(0xFFDDE1E7);
const _kText      = Color(0xFF1A1D4E);
const _kHint      = Color(0xFFB0B5C8);

// ─── LoginPage ────────────────────────────────────────────────────────────────

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _rememberMe  = false;
  bool _isLoading   = false;
  String? _errorMessage;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  // ── Entrada suave ─────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (conservada intacta) ───────────────────────────────────────
  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _autovalidate  = AutovalidateMode.onUserInteraction;
      _errorMessage  = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final ok = await ref
          .read(authServiceProvider)
          .login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(profileProvider);
        ref.invalidate(jobsProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(conversationsProvider);
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Correo o contraseña incorrectos.';
          _isLoading    = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFromDio(e);
        _isLoading    = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _errorMessage = raw.isNotEmpty
            ? raw
            : 'Usuario o contraseña incorrectos. Verifica tus datos.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
        _isLoading    = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() { _errorMessage = null; _isLoading = true; });

    try {
      // 1. Inicia el flujo de selección de cuenta Google
      // En Android usamos serverClientId para obtener token válido para backend/Firebase
      final googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: '320726381262-pv5u18f1ki1sfp544prfvftbk7birpsv.apps.googleusercontent.com',
            )
          : GoogleSignIn(
              serverClientId: '320726381262-pv5u18f1ki1sfp544prfvftbk7birpsv.apps.googleusercontent.com',
            );

      final googleAccount = await googleSignIn.signIn();

      // Usuario canceló
      if (googleAccount == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Obtener tokens de autenticación
      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Autenticar con Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('No se pudo obtener el usuario de Google.');

      // 4. Iniciar sesión / registrar en el Backend C# (WorkGoApp V2 API)
      final authService = ref.read(authServiceProvider);
      try {
        await authService.loginWithGoogleAccount(
          email: user.email ?? googleAccount.email,
          googleId: user.uid,
          displayName: user.displayName ?? googleAccount.displayName ?? 'Usuario Google',
        );
      } catch (_) {
        // Fallback a almacenamiento local de credenciales si la API responde diferente
        final idToken = await user.getIdToken();
        if (idToken != null) {
          final storage = ref.read(secureStorageProvider);
          await storage.saveAccessToken(idToken);
          await storage.saveUserId(user.uid);
          await storage.saveUsername(user.displayName ?? user.email ?? '');
        }
      }

      if (!mounted) return;

      // 5. Invalidar providers y navegar al inicio
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
          msg = e.message ?? 'Error al iniciar sesión con Google.';
      }
      setState(() { _errorMessage = msg; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      // Si el usuario cancela el selector de cuenta o 12501 no mostrar mensaje de error
      if (raw.contains('sign_in_canceled') || raw.contains('canceled') || raw.contains('12501')) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _errorMessage = raw.isNotEmpty
            ? raw
            : 'Error al conectar con Google. Verifica tu conexión.';
        _isLoading = false;
      });
    }
  }

  String _messageFromDio(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      final msg = responseData['datos'] ??
          responseData['mensaje'] ??
          responseData['message'];
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
        final s = e.response?.statusCode;
        if (s == 401 || s == 403) return 'Correo o contraseña incorrectos.';
        if (s != null && s >= 500) {
          return 'Error del servidor. Intenta más tarde.';
        }
        return 'No se pudo iniciar sesión. Intenta de nuevo.';
      default:
        return 'Sin conexión. Verifica tu internet.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/welcome');
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

                    // ── Título ────────────────────────────────────────────
                    const Text(
                      'Iniciar sesión\nen tu cuenta.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _kTitle,
                        height: 1.18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hola, bienvenido de vuelta a tu cuenta',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: _kSubtitle,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Campo E-mail ──────────────────────────────────────
                    _CleanField(
                      controller: _emailCtrl,
                      label: 'E-mail',
                      hint: 'ejemplo@correo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) =>
                          setState(() => _errorMessage = null),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu usuario o correo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // ── Campo Password ────────────────────────────────────
                    _CleanPasswordField(
                      controller: _passCtrl,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) =>
                          setState(() => _errorMessage = null),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Remember me + Forgot password ─────────────────────
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: _kPrimary,
                            shape: const CircleBorder(),
                            side: const BorderSide(
                              color: _kBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recordarme',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _kText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              context.push('/auth/forgot-password'),
                          child: const Text(
                            'Olvidé mi contraseña',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Error inline ──────────────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.35),
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
                                        _errorMessage!,
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

                    // ── Botón Login ───────────────────────────────────────
                    _LoginButton(
                      isLoading: _isLoading,
                      onLogin: _handleLogin,
                    ),
                    const SizedBox(height: 28),

                    // ── Divider "or sign up with" ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: _kBorder,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'o continúa con',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _kSubtitle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: _kBorder,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Botones sociales: Facebook · Google ───────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialBtn(
                            iconAsset: 'assets/icons/facebook.png',
                            fallbackIcon: Icons.facebook,
                            fallbackColor: const Color(0xFF1877F2),
                            onTap: signInWithFacebook,
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
                    const SizedBox(height: 32),

                    // ── ¿Sin cuenta? Regístrate ───────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¿No tienes una cuenta?  ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              color: _kSubtitle,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/auth/register'),
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
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

// ─── Botón Login ──────────────────────────────────────────────────────────────

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onLogin;
  const _LoginButton({required this.isLoading, required this.onLogin});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
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
        if (!widget.isLoading) widget.onLogin();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
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
                    'Iniciar sesión',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Campo de texto con label flotante ───────────────────────────────────────

class _CleanField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _CleanField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: _kText,
      ),
      decoration: _buildDecoration(label: label, hint: hint),
    );
  }
}

// ─── Campo contraseña ─────────────────────────────────────────────────────────

class _CleanPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _CleanPasswordField({
    required this.controller,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  @override
  State<_CleanPasswordField> createState() => _CleanPasswordFieldState();
}

class _CleanPasswordFieldState extends State<_CleanPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: _kText,
      ),
      decoration: _buildDecoration(label: 'Contraseña', hint: 'Tu contraseña').copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 19,
            color: _kHint,
          ),
        ),
      ),
    );
  }
}

// ─── Decoración compartida de campos ─────────────────────────────────────────

InputDecoration _buildDecoration({
  required String label,
  required String hint,
}) {
  const focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: _kPrimary, width: 1.8),
  );
  const normalBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: _kBorder, width: 1.2),
  );
  const errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.error, width: 1.2),
  );

  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: _kPrimary,
      fontWeight: FontWeight.w500,
    ),
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: _kHint,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: normalBorder,
    enabledBorder: normalBorder,
    focusedBorder: focusBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: errorBorder,
    errorStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 11.5,
      color: AppColors.error,
    ),
  );
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
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Center(
          child: Image.asset(
            iconAsset,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              size: 48,
              color: fallbackColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Auth social placeholders ─────────────────────────────────────────────────

Future<void> signInWithGoogle() async {
  // TODO: Integrar Google Sign-In.
}

Future<void> signInWithFacebook() async {
  // TODO: Integrar Facebook Login.
}
