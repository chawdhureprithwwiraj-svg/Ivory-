import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// The gold-bordered text field used on the sign-in screen. Lifted
/// out of login_screen.dart so that file stays inside a comfortable
/// paste, and reusable anywhere else a field should match it.

class IvoryField extends StatelessWidget {
  const IvoryField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final List<String>? autofillHints;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      textInputAction:
          onSubmitted != null ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(color: IvoryColors.burgundy, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

// END OF FILE - lib/widgets/ivory_field.dart
