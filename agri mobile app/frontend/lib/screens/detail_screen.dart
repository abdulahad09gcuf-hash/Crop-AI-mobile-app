// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/prediction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import '../widgets/top5_chart.dart';
import '../widgets/recommendation_card.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final PredictionRecord record;
  const DetailScreen({super.key, required this.record});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  PredictionRecord? _full;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  Future<void> _loadFull() async {
    try {
      final data = await ApiService.getHistoryDetail(widget.record.id);
      setState(() {
        _full = PredictionRecord.fromHistory(data);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _full = widget.record;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _full ?? widget.record;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Detail',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurface,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResultCard(record: record),
                  const SizedBox(height: 12),
                  if (record.top5.isNotEmpty) ...[
                    Top5Chart(top5: record.top5),
                    const SizedBox(height: 12),
                  ],
                  RecommendationCard(rec: record.recommendation),
                  const SizedBox(height: 12),
                  if (record.createdAt != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E4A2C)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text('Scanned: ${record.createdAt}',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: AppColors.textMuted)),
                      ]),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
