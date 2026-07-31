import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

// ─── AppTextField ────────────────────────────────────────────────────────────

/// Campo de texto reutilizable con soporte para validación, prefijo, sufijo
/// y manejo de teclado. Integra el tema global de inputs (radio 14 px).
class AppTextField extends StatefulWidget {
  final String? hint;
  final String? label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.hint,
    this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: isPassword && !_showPassword,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      maxLines: isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: AppColors.textHint)
            : null,
        suffixIcon: isPassword
            ? _ToggleVisibilityButton(
                visible: _showPassword,
                onToggle: () => setState(() => _showPassword = !_showPassword),
              )
            : widget.suffix,
        counterText: '',
      ),
    );
  }
}

// ─── AppPasswordField ────────────────────────────────────────────────────────

/// Campo dedicado para contraseñas con toggle de visibilidad incorporado.
/// Siempre usa maxLines = 1.
class AppPasswordField extends StatefulWidget {
  final String? hint;
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;

  const AppPasswordField({
    super.key,
    this.hint = 'Contraseña',
    this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      maxLines: 1,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: AppColors.textHint,
        ),
        suffixIcon: _ToggleVisibilityButton(
          visible: _visible,
          onToggle: () => setState(() => _visible = !_visible),
        ),
        counterText: '',
      ),
    );
  }
}

// ─── AppDividerWithText ──────────────────────────────────────────────────────

/// Divisor horizontal con texto centrado. Ejemplo: "o continúa con".
class AppDividerWithText extends StatelessWidget {
  final String text;
  final Color? lineColor;
  final TextStyle? textStyle;

  const AppDividerWithText({
    super.key,
    required this.text,
    this.lineColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = lineColor ?? AppColors.border;
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style:
                textStyle ??
                const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1, height: 1)),
      ],
    );
  }
}

// ─── Privado: botón de visibilidad ───────────────────────────────────────────

class _ToggleVisibilityButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onToggle;

  const _ToggleVisibilityButton({
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.textHint,
      ),
      splashRadius: 20,
      tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
    );
  }
}
