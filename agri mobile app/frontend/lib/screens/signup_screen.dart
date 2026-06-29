// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/app_logo.dart';   // ← NEW

class SignupScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const SignupScreen({super.key, required this.onSuccess});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _loading      = false;
  bool  _showPass     = false;
  String? _error;

  Future<void> _signup() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm  = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required.'); return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.signup(name: name, email: email, password: password);
      if (!mounted) return;
      if (data['success'] == true) {
        widget.onSuccess();
      } else {
        setState(() => _error = data['error'] ?? 'Signup failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textSecondary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Logo + branding ──────────────────────────────────────────
            Center(child: Column(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29ABE2).withOpacity(0.30),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: const AppLogo(size: 64),
              ).animate().scale(curve: Curves.elasticOut),

              const SizedBox(height: 12),

              Text(
                'Create Account',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Start detecting crop diseases today',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
              ),
            ])),

            const SizedBox(height: 32),

            // ── Form card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252A52)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_error != null)
                  AuthErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ).animate().shake(hz: 2),

                AuthInputField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'Ahmad Khan',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 14),
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
                  obscure: !_showPass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _confirmCtrl,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: !_showPass,
                  onSubmitted: (_) => _signup(),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _signup,
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
                        'Create Account',
                        style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                ),
              ]),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                'Already have an account?',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.dmSans(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ]).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}