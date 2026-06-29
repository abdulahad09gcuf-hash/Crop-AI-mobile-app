// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/app_logo.dart';   // ← NEW
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const LoginScreen({super.key, required this.onSuccess});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _loading      = false;
  bool  _showPassword = false;
  String? _error;

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.login(email: email, password: password);
      if (!mounted) return;
      if (data['success'] == true) {
        widget.onSuccess();
      } else {
        setState(() => _error = data['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 32),

            // ── Logo + branding ──────────────────────────────────────────
            Center(child: Column(children: [
              // Glow ring behind logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29ABE2).withOpacity(0.35),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: const AppLogo(size: 80),
              ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),

              const SizedBox(height: 16),

              Text(
                'CropAI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              Text(
                'Crop Disease Detection',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ).animate().fadeIn(delay: 300.ms),
            ])),

            const SizedBox(height: 48),

            // ── Login card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252A52)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  'Welcome Back',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your account',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                if (_error != null)
                  AuthErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ).animate().shake(hz: 2),

                AuthInputField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                ),
              ]),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                "Don't have an account?",
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupScreen(onSuccess: widget.onSuccess),
                  ),
                ),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.dmSans(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ]).animate().fadeIn(delay: 400.ms),
          ]),
        ),
      ),
    );
  }
}