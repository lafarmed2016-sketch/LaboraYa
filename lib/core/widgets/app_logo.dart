import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final MainAxisAlignment alignment;

  const AppLogo({
    super.key,
    this.fontSize = 32,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Labora',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Ya',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
