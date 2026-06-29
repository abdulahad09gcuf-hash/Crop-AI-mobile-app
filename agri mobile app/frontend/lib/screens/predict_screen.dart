// lib/screens/predict_screen.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'models/prediction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import '../widgets/top5_chart.dart';
import '../widgets/recommendation_card.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with SingleTickerProviderStateMixin {
  XFile? _xfile;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;
  PredictionRecord? _result;
  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 90);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _xfile = xfile;
      _imageBytes = bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _predict() async {
    if (_xfile == null || _imageBytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await ApiService.predict(_xfile!, _imageBytes!);
      if (data['success'] == true) {
        setState(() {
          _result = PredictionRecord.fromJson(data);
        });
      } else {
        setState(() {
          _error = data['error'] ?? 'Prediction failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _reset() => setState(() {
        _xfile = null;
        _imageBytes = null;
        _result = null;
        _error = null;
      });

  bool get _hasImage => _imageBytes != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
        expandedHeight: 130,
        pinned: true,
        backgroundColor: AppColors.bgSurface,
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          title: Text('Crop Diagnosis',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2E8A), AppColors.bgSurface],
              ),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.eco_rounded,
                    size: 70, color: AppColors.primary.withOpacity(0.25)),
              ),
            ),
          ),
        ),
      );

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUploadZone(),
          const SizedBox(height: 16),

          // ── Error Banner ──────────────────────────────────────────
          if (_error != null) _buildErrorBanner(),

          // ── Results ───────────────────────────────────────────────
          if (_result != null) ...[
            ResultCard(record: _result!).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 12),
            Top5Chart(top5: _result!.top5).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            RecommendationCard(rec: _result!.recommendation)
                .animate()
                .fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              label: Text('Scan Another',
                  style: GoogleFonts.dmSans(color: AppColors.accent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = !_hasImage
            ? Color.lerp(
                AppColors.primary, AppColors.primaryLight, _pulseCtrl.value)!
            : AppColors.primary;
        return Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glow, width: !_hasImage ? 2 : 1),
            color: AppColors.bgCard,
            boxShadow: !_hasImage
                ? [
                    BoxShadow(
                      color: glow.withOpacity(0.18),
                      blurRadius: 24,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: !_hasImage ? _uploadPlaceholder() : _imagePreview(),
        );
      },
    );
  }

  Widget _uploadPlaceholder() => InkWell(
        onTap: _showPickerSheet,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                    size: 56, color: AppColors.primary)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2.seconds, color: AppColors.primaryLight),
            const SizedBox(height: 12),
            Text('Upload Crop Image',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text('JPG, PNG, WEBP, BMP — max 10 MB',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!kIsWeb) ...[
                  _chipButton(Icons.camera_alt, 'Camera',
                      () => _pickImage(ImageSource.camera)),
                  const SizedBox(width: 12),
                ],
                _chipButton(Icons.photo_library_rounded, 'Gallery',
                    () => _pickImage(ImageSource.gallery)),
              ],
            ),
          ],
        ),
      );

  Widget _chipButton(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _imagePreview() => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.bg.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_loading) ...[
                  ElevatedButton.icon(
                    onPressed: _predict,
                    icon: const Icon(Icons.biotech_rounded, size: 18),
                    label: Text('Analyze Plant',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _showPickerSheet,
                    icon: const Icon(Icons.swap_horiz,
                        color: AppColors.textSecondary),
                    tooltip: 'Change image',
                    style:
                        IconButton.styleFrom(backgroundColor: AppColors.bgCard),
                  ),
                ] else
                  _buildLoader(),
              ],
            ),
          ),
        ],
      );

  Widget _buildLoader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Text('Analyzing...',
                style: GoogleFonts.dmSans(color: AppColors.accent)),
          ],
        ),
      );

  // ── IMPROVED Error Banner with connection tips ─────────────────────────
  Widget _buildErrorBanner() {
    final isConnectionError = _error!.contains('Cannot reach server') ||
        _error!.contains('SocketException') ||
        _error!.contains('network');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isConnectionError ? 'Connection Failed' : 'Prediction Error',
                style: GoogleFonts.dmSans(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _error = null),
              child:
                  const Icon(Icons.close, color: AppColors.textMuted, size: 18),
            ),
          ]),
        ),

        // ── Message ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Text(_error!,
              style: GoogleFonts.dmSans(
                  color: AppColors.dangerLight, fontSize: 12, height: 1.5)),
        ),

        // ── Fix tips for connection errors ───────────
        if (isConnectionError) ...[
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Fix:',
                    style: GoogleFonts.dmSans(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    )),
                const SizedBox(height: 6),
                _tip(Icons.computer, 'Run: python app.py on your computer'),
                _tip(Icons.wifi, 'Both devices on the same WiFi'),
                _tip(Icons.settings, 'Update server IP in Settings tab'),
                _tip(Icons.phone_android,
                    'Emulator: use 10.0.2.2 instead of localhost'),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 14),
      ]),
    ).animate().shake(hz: 2, offset: const Offset(4, 0));
  }

  Widget _tip(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary))),
        ]),
      );

  void _showPickerSheet() {
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Select Image Source',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _sourceCard(
                      Icons.camera_alt_rounded, 'Camera', 'Take a photo', () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              })),
              const SizedBox(width: 12),
              Expanded(
                  child: _sourceCard(
                      Icons.photo_library_rounded, 'Gallery', 'Choose existing',
                      () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              })),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceCard(
          IconData icon, String title, String sub, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Column(children: [
            Icon(icon, size: 32, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(sub,
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
      );
}
