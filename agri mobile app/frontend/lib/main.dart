// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/predict_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait on mobile
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
       defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Restore saved server URL + JWT token
  await ApiService.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropAI diagnosis ++',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

// ── Auth Gate — decides whether to show login or main shell ───────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loggedIn = ApiService.isLoggedIn;
  }

  void _onLogin()  => setState(() => _loggedIn = true);
  void _onLogout() {
    ApiService.logout();
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(onSuccess: _onLogin);
    }
    return _Shell(onLogout: _onLogout);
  }
}

// ── Main Shell (bottom nav) ───────────────────────────────────────────────────
class _Shell extends StatefulWidget {
  final VoidCallback onLogout;
  const _Shell({required this.onLogout});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _idx = 0;

  late final List<Widget> _screens = [
    const PredictScreen(),
    const HistoryScreen(),
    const DashboardScreen(),
    SettingsScreen(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() => Container(
    decoration: BoxDecoration(
      color: AppColors.bgSurface,
      border: const Border(
        top: BorderSide(color: Color(0xFF252A52), width: 1)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          _NavItem(0, Icons.biotech_outlined,   Icons.biotech,    'Diagnose',  _idx, _go),
          _NavItem(1, Icons.history_outlined,    Icons.history,    'History',   _idx, _go),
          _NavItem(2, Icons.bar_chart_outlined,  Icons.bar_chart,  'Analytics', _idx, _go),
          _NavItem(3, Icons.settings_outlined,   Icons.settings,   'Settings',  _idx, _go),
        ]),
      ),
    ),
  );

  void _go(int i) => setState(() => _idx = i);
}

class _NavItem extends StatelessWidget {
  final int myIdx, currentIdx;
  final IconData icon, activeIcon;
  final String label;
  final void Function(int) onTap;

  const _NavItem(this.myIdx, this.icon, this.activeIcon, this.label,
    this.currentIdx, this.onTap);

  bool get _active => myIdx == currentIdx;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () => onTap(myIdx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _active
            ? AppColors.primary.withOpacity(0.15)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _active ? activeIcon : icon,
              key: ValueKey(_active),
              color: _active ? AppColors.accent : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: _active ? FontWeight.w700 : FontWeight.w400,
            color: _active ? AppColors.accent : AppColors.textMuted)),
        ]),
      ),
    ),
  );
}