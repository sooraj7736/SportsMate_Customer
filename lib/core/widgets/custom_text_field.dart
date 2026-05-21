import 'package:flutter/material.dart';

/// A reusable text field that automatically respects the app theme.
/// Colors (hint, prefix icon, border) are resolved from the active
/// ThemeData — no hardcoded colors.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Icon color pulled from theme — adapts to light/dark automatically
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: suffixIcon,
          labelText: label,
          errorText: errorText,
          // InputDecorationTheme from AppTheme handles fill, border, etc.
        ),
      ),
    );
  }
}