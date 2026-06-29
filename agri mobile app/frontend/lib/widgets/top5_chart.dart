// lib/widgets/top5_chart.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class Top5Chart extends StatelessWidget {
  final List<MapEntry<String, double>> top5;
  const Top5Chart({super.key, required this.top5});

  @override
  Widget build(BuildContext context) {
    if (top5.isEmpty) return const SizedBox();
    final items = top5.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252A52)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart_rounded,
              size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top Predictions',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
            Text('Probability distribution',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        ...List.generate(items.length, (i) {
          final entry = items[i];
          final color = AppColors.chartColors[i % AppColors.chartColors.length];
          final label = entry.key.replaceAll('_', ' ').replaceAll('  ', ' ');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0 ? color : color.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: i == 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${(entry.value * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
              ]),
              const SizedBox(height: 5),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: entry.value),
                duration: Duration(milliseconds: 600 + i * 100),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: i == 0 ? 8 : 5,
                    backgroundColor: AppColors.bgCardLight,
                    valueColor: AlwaysStoppedAnimation(
                      i == 0 ? color : color.withOpacity(0.55)),
                  ),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}