// lib/widgets/recommendation_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  const RecommendationCard({super.key, required this.rec});

  Color get _typeColor {
    final t = rec['type']?.toString().toLowerCase() ?? '';
    if (t.contains('healthy'))                              return AppColors.success;
    if (t.contains('nutrient') || t.contains('deficiency')) return AppColors.warning;
    if (t.contains('fungal'))                               return AppColors.accent;
    if (t.contains('bacterial'))                            return AppColors.danger;
    return AppColors.primary;
  }

  IconData get _typeIcon {
    final t = rec['type']?.toString().toLowerCase() ?? '';
    if (t.contains('healthy'))                              return Icons.check_circle;
    if (t.contains('nutrient') || t.contains('deficiency')) return Icons.science;
    if (t.contains('fungal'))                               return Icons.blur_circular;
    if (t.contains('bacterial'))                            return Icons.biotech;
    return Icons.medical_services;
  }

  @override
  Widget build(BuildContext context) {
    final color   = _typeColor;
    final entries = rec.entries.where((e) => e.key != 'type').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Treatment Recommendation',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(rec['type']?.toString() ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(color: color.withOpacity(0.15)),
        const SizedBox(height: 8),
        ...entries.map((e) {
          if (e.key == 'Tip') {
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outline,
                  color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.value.toString(),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    )),
                ),
              ]),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 90,
                child: Text(e.key,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted)),
              ),
              Expanded(
                child: Text(e.value.toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}