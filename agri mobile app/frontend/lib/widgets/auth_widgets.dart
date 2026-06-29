// lib/widgets/auth_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable text input for login / signup screens.
class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        )),
      const SizedBox(height: 6),
      TextField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: keyboardType,
        onSubmitted:  onSubmitted,
        style: GoogleFonts.dmSans(
          color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted.withOpacity(0.6), fontSize: 14),
          filled:     true,
          fillColor:  AppColors.bgCardLight,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF252A52))),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF252A52))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary, width: 2)),
        ),
      ),
    ],
  );
}

/// Reusable error banner for login / signup screens.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.danger.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.danger.withOpacity(0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
        style: GoogleFonts.dmSans(
          color: AppColors.dangerLight, fontSize: 13))),
      GestureDetector(
        onTap: onDismiss,
        child: const Icon(Icons.close, color: AppColors.textMuted, size: 16)),
    ]),
  );
}