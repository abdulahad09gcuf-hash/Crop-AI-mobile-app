// lib/screens/settings_screen.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const SettingsScreen({super.key, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  bool _testing = false;
  bool? _testResult;
  List<String> _classes = [];

  String get _platformHint {
    if (kIsWeb) return '🌐 Web: use http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '📱 Android emulator: http://10.0.2.2:5000\n'
            '📱 Real device (WiFi): http://192.168.x.x:5000';
      case TargetPlatform.iOS:
        return '📱 iOS simulator: http://127.0.0.1:5000\n'
            '📱 Real device (WiFi): http://192.168.x.x:5000';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return '🖥️ Desktop: http://localhost:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = ApiService.baseUrl;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      _classes = await ApiService.getClasses();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveUrl() async {
    final normalizedUrl = ApiService.normalizeBaseUrl(_urlCtrl.text);
    ApiService.baseUrl = normalizedUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', normalizedUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Server URL saved', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppColors.success));
    }
    _loadClasses();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    ApiService.baseUrl = ApiService.normalizeBaseUrl(_urlCtrl.text);
    final ok = await ApiService.healthCheck();
    setState(() {
      _testResult = ok;
      _testing = false;
    });
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_url');
    setState(() {
      ApiService.baseUrl = ApiService.normalizeBaseUrl(_platformDefault());
      _urlCtrl.text = ApiService.baseUrl;
      _testResult = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reset to platform default',
              style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppColors.primary));
    }
  }

  String _platformDefault() {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white),
              child: Text('Sign Out',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.onLogout?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Profile Card ─────────────────────────────────────────
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.bgCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent]),
                  ),
                  child: Center(
                    child: Text(
                        (user['name'] as String? ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? '',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    Text(user['email'] ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                )),
                const Icon(Icons.verified_user,
                    color: AppColors.accent, size: 18),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // ── Platform hint ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_platformHint,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.5))),
            ]),
          ),

          _sectionHeader('Server Configuration'),
          const SizedBox(height: 10),
          _card(Column(children: [
            TextField(
              controller: _urlCtrl,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Flask API URL',
                labelStyle:
                    GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                hintText: 'http://localhost:5000',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgCardLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF252A52))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF252A52))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
                prefixIcon: const Icon(Icons.link, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent))
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: Text('Test', style: GoogleFonts.spaceGrotesk()),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent)),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: _saveUrl,
                icon: const Icon(Icons.save, size: 16),
                label: Text('Save', style: GoogleFonts.spaceGrotesk()),
              )),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _resetToDefault,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: Color(0xFF252A52))),
                child: const Icon(Icons.refresh, size: 16),
              ),
            ]),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_testResult! ? AppColors.success : AppColors.danger)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(_testResult! ? Icons.check_circle : Icons.error,
                      color:
                          _testResult! ? AppColors.success : AppColors.danger,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          _testResult!
                              ? '✅ Connected to ${ApiService.baseUrl}'
                              : '❌ Cannot reach ${ApiService.baseUrl}\n'
                                  'Check Flask is running and URL is correct.',
                          style: GoogleFonts.spaceGrotesk(
                              color: _testResult!
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontSize: 12,
                              height: 1.4))),
                ]),
              ),
            ],
          ])),

          const SizedBox(height: 20),
          _sectionHeader('Supported Classes (${_classes.length})'),
          const SizedBox(height: 10),
          if (_classes.isNotEmpty)
            _card(Column(children: _classes.map(_classRow).toList()))
          else
            _card(Center(
                child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Connect to server to load classes',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted)),
            ))),

          const SizedBox(height: 20),
          _sectionHeader('About'),
          const SizedBox(height: 10),
          _card(Column(children: [
            _infoRow(Icons.model_training, 'Model', 'MobileNet V3 Large'),
            _infoRow(Icons.storage, 'Database', 'MongoDB'),
            _infoRow(Icons.code, 'Backend', 'Flask REST API'),
            _infoRow(Icons.phone_android, 'Frontend', 'Flutter'),
            _infoRow(Icons.security, 'Auth', 'JWT Bearer Token'),
            _infoRow(Icons.category, 'Classes', '16 crop conditions'),
            _infoRow(Icons.image, 'Image Size', '256 × 256 px'),
          ])),

          const SizedBox(height: 24),

          // ── Logout ─────────────────────────────────────────────────────
          if (widget.onLogout != null)
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: Text('Sign Out',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(String t) => Text(t,
      style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2));

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252A52)),
        ),
        child: child,
      );

  Widget _classRow(String name) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(name.replaceAll('_', ' '),
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 13))),
        ]),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      );
}
