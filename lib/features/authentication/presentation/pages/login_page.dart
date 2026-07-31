import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/auth_service.dart';

// ─── LoginPage ───────────────────────────────────────────────────────────────
// Lógica de autenticación 100 % conservada.
// Transformación visual completa: panel blanco, campos light, logo visible.

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  // ── Form state (conservado) ───────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  // ── Animaciones ───────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl; // fade del fondo
  late final AnimationController _panelCtrl; // slide del panel
  late final AnimationController _contentCtrl; // fade+slide del contenido

  late final Animation<double> _bgFade;
  late final Animation<Offset> _panelSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bgFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));
    _contentFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    // Secuencia: fondo → panel → contenido
    _bgCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          _panelCtrl.forward().then((_) {
            if (mounted) _contentCtrl.forward();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _panelCtrl.dispose();
    _contentCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (conservada) ───────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final ok = await ref
          .read(authServiceProvider)
          .login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Correo o contraseña incorrectos.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFromDio(e);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  String _messageFromDio(DioException e) {
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
        final s = e.response?.statusCode;
        if (s == 401 || s == 403) return 'Correo o contraseña incorrectos.';
        if (s != null && s >= 500)
          return 'Error del servidor. Intenta más tarde.';
        return 'No se pudo iniciar sesión. Intenta de nuevo.';
      default:
        return 'Sin conexión. Verifica tu internet.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/welcome');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── 1. Fondo: collage de fotografías ──────────────────────
            Positioned.fill(
              child: FadeTransition(
                opacity: _bgFade,
                child: const _CollageBackground(),
              ),
            ),

            // ── 2. Degradado cinematográfico sobre el fondo ───────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.25, 0.52, 1.0],
                  ),
                ),
              ),
            ),

            // ── 3. Logo LaboraYa en la parte superior ─────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 32,
              left: 0,
              right: 0,
              child: FadeTransition(opacity: _bgFade, child: const _TopLogo()),
            ),

            // ── 4. Panel blanco con SlideTransition ───────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // Panel ocupa ~60 % de pantalla; sube cuando aparece teclado
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minHeight: screenH * 0.58,
                  maxHeight: screenH * 0.78,
                ),
                transform: Matrix4.translationValues(
                  0,
                  keyboardH > 0 ? -keyboardH * 0.45 : 0,
                  0,
                ),
                child: SlideTransition(
                  position: _panelSlide,
                  child: _LoginPanel(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    rememberMe: _rememberMe,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    autovalidate: _autovalidate,
                    contentFade: _contentFade,
                    contentSlide: _contentSlide,
                    onRememberMe: (v) =>
                        setState(() => _rememberMe = v ?? false),
                    onLogin: _handleLogin,
                    onErrorClear: () => setState(() => _errorMessage = null),
                  ),
                ),
              ),
            ),
          ],
        ),
      ), // Scaffold
    ); // PopScope
  }
}

// ─── Logo superior ────────────────────────────────────────────────────────────

class _TopLogo extends StatelessWidget {
  const _TopLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Isotipo circular
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'L',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'Y',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Wordmark
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Labora',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Ya',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF90CAF9),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Trabajo cerca de ti',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Panel blanco ─────────────────────────────────────────────────────────────

class _LoginPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final AutovalidateMode autovalidate;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final ValueChanged<bool?> onRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onErrorClear;

  const _LoginPanel({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.rememberMe,
    required this.isLoading,
    required this.errorMessage,
    required this.autovalidate,
    required this.contentFade,
    required this.contentSlide,
    required this.onRememberMe,
    required this.onLogin,
    required this.onErrorClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Form(
                key: formKey,
                autovalidateMode: autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 14, bottom: 28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE1E7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Título
                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo
                    const Text(
                      'Ingresa tu usuario o correo para continuar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        color: Color(0xFF667085),
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _LightField(
                      controller: emailCtrl,
                      hint: 'Usuario o correo electrónico',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => onErrorClear(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu usuario o correo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _LightPasswordField(
                      controller: passCtrl,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => onErrorClear(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Recordarme + Olvidé mi contraseña
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: onRememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFD0D5DD),
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
                            color: Color(0xFF344054),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/auth/forgot-password'),
                          child: const Text(
                            'Olvidé mi contraseña',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Error inline
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: errorMessage != null
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
                                    color: AppColors.error.withValues(
                                      alpha: 0.35,
                                    ),
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
                                        errorMessage!,
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
                    const SizedBox(height: 24),

                    // Botón Iniciar sesión
                    _LoginButton(isLoading: isLoading, onLogin: onLogin),
                    const SizedBox(height: 16),

                    // Divider decorativo
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFEAECF0),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o continúa con',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFEAECF0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Botones sociales: solo íconos, sin texto ─────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialIconButton(
                            iconAsset: 'assets/icons/facebook.png',
                            fallbackIcon: Icons.facebook,
                            fallbackColor: const Color(0xFF1877F2),
                            onTap: signInWithFacebook,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialIconButton(
                            iconAsset: 'assets/icons/gmail.png',
                            fallbackIcon: Icons.g_mobiledata,
                            fallbackColor: const Color(0xFFEA4335),
                            onTap: signInWithGoogle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ¿Aún no tienes cuenta?
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¿Aún no tienes una cuenta?  ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF667085),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/auth/register'),
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
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

// ─── Botón de login ───────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 100),
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
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}


// ─── Campo de texto light ─────────────────────────────────────────────────────

class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _LightField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    );
    final focus = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );
    final error = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF101828),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF98A2B3),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF98A2B3), size: 19),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 56,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: base,
        enabledBorder: base,
        focusedBorder: focus,
        errorBorder: error,
        focusedErrorBorder: error,
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ─── Campo contraseña light ───────────────────────────────────────────────────

class _LightPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _LightPasswordField({
    required this.controller,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  @override
  State<_LightPasswordField> createState() => _LightPasswordFieldState();
}

class _LightPasswordFieldState extends State<_LightPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    );
    final focus = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );
    final error = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF101828),
      ),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF98A2B3),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF98A2B3),
            size: 19,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 56,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 19,
            color: const Color(0xFF98A2B3),
          ),
          tooltip: _visible ? 'Ocultar' : 'Mostrar',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: base,
        enabledBorder: base,
        focusedBorder: focus,
        errorBorder: error,
        focusedErrorBorder: error,
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ─── Collage de fondo ─────────────────────────────────────────────────────────

class _CollageBackground extends StatelessWidget {
  const _CollageBackground();

  // Tiles rediseñados para composición más dinámica:
  // Columna izquierda: 3 tiles verticales con altura variable
  // Columna derecha: 2 tiles con alturas complementarias
  static const _tiles = [
    // Columna izquierda — 3 imágenes
    _Tile(
      asset: 'assets/images/job_electricidad.png',
      top: 0.00,
      left: 0.00,
      wF: 0.52,
      hF: 0.35,
    ),
    _Tile(
      asset: 'assets/images/job_carpinteria.png',
      top: 0.37,
      left: 0.00,
      wF: 0.52,
      hF: 0.26,
    ),
    _Tile(
      asset: 'assets/images/job_mecanica.png',
      top: 0.65,
      left: 0.00,
      wF: 0.52,
      hF: 0.22,
    ),
    // Columna derecha — 3 imágenes con alturas distintas
    _Tile(
      asset: 'assets/images/job_pintura.png',
      top: 0.00,
      right: 0.00,
      wF: 0.45,
      hF: 0.22,
    ),
    _Tile(
      asset: 'assets/images/job_albanileria.png',
      top: 0.24,
      right: 0.00,
      wF: 0.45,
      hF: 0.28,
    ),
    _Tile(
      asset: 'assets/images/job_limpieza.png',
      top: 0.54,
      right: 0.00,
      wF: 0.45,
      hF: 0.20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return ColoredBox(
      color: const Color(0xFF0B1525),
      child: Stack(
        children: _tiles.map((t) {
          return Positioned(
            top: t.top != null ? sz.height * t.top! : null,
            bottom: t.bot != null ? sz.height * t.bot! : null,
            left: t.left != null ? sz.width * t.left! : null,
            right: t.right != null ? sz.width * t.right! : null,
            width: sz.width * t.wF,
            height: sz.height * t.hF,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  t.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2F4A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: Color(0xFF2A4A6B),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Tile {
  final String asset;
  final double? top, bot, left, right;
  final double wF, hF;
  const _Tile({
    required this.asset,
    this.top,
    this.bot,
    this.left,
    this.right,
    required this.wF,
    required this.hF,
  });
}

// ─── Botón social solo ícono (como la foto) ──────────────────────────────────

class _SocialIconButton extends StatelessWidget {
  final String iconAsset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;

  const _SocialIconButton({
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

// ─── Botón social completo (PNG) ──────────────────────────────────────────────

class _SocialLoginButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _SocialLoginButton({
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

// ─── Auth social placeholder ──────────────────────────────────────────────────

Future<void> signInWithGoogle() async {
  // TODO: Integrar Google Sign-In.
  // Requiere el paquete `google_sign_in` y configuración de Firebase.
}

Future<void> signInWithFacebook() async {
  // TODO: Integrar Facebook Login.
  // Requiere el paquete `flutter_facebook_auth` y configuración de Facebook App.
}
