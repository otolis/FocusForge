import 'package:flutter/material.dart';

/// A reusable text form field with consistent styling.
///
/// Inherits the 12dp border radius from the app theme's
/// [InputDecorationTheme].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
  });

  /// Label text displayed inside the input decoration.
  final String label;

  /// Optional controller for reading/writing the field value.
  final TextEditingController? controller;

  /// Optional validator for form validation.
  final String? Function(String?)? validator;

  /// Whether to obscure the text (for password fields).
  final bool obscureText;

  /// The keyboard type for the field.
  final TextInputType? keyboardType;

  /// The action button on the keyboard (next, done, etc.).
  final TextInputAction? textInputAction;

  /// Callback when the user submits the field.
  final ValueChanged<String>? onFieldSubmitted;

  /// Optional icon displayed before the input text.
  final Widget? prefixIcon;

  /// Optional icon displayed after the input text.
  final Widget? suffixIcon;

  /// Optional error text displayed below the field.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
    );
  }
}
