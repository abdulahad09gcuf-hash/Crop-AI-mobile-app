// lib/widgets/result_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/models/prediction_model.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final PredictionRecord record;
  const ResultCard({super.key, required this.record});

  Color get _color {
    if (record.isHealthy) return AppColors.success;
    if (record.isDeficiency) return AppColors.warning;
    return AppColors.danger;
  }

  IconData get _icon {
    if (record.isHealthy) return Icons.check_circle_rounded;
    if (record.isDeficiency) return Icons.water_drop_outlined;
    return Icons.coronavirus_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_color.withOpacity(0.15), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withOpacity(0.18),
              border: Border.all(color: _color.withOpacity(0.4)),
            ),
            child: Icon(_icon, color: _color, size: 28),
          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Detection Result',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(
                record.displayLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _Pill(record.typeLabel, _color),
          const SizedBox(width: 8),
          _Pill(
            '${(record.confidence * 100).toStringAsFixed(1)}% confidence',
            AppColors.primary,
          ),
        ]),
        const SizedBox(height: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Confidence',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted)),
            const Spacer(),
            Text(record.confidencePct,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w700,
                )),
          ]),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: record.confidence),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: AppColors.bgCardLight,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
