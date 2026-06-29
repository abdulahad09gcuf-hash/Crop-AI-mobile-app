// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'models/prediction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PredictionRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.getHistory();

      final records = raw
          .map(
            (e) => PredictionRecord.fromHistory(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _records = records;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _deleteRecord(String id) async {
    try {
      final ok = await ApiService.deleteRecord(id);

      if (ok && mounted) {
        setState(() {
          _records.removeWhere(
            (e) => e.id == id,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Record deleted"),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          "Scan History",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.danger,
                    ),
                  ),
                )
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 70,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No History Found",
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary,
                            ),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _records.length,
                        itemBuilder: (_, index) {
                          final item = _records[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    record: item,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ResultCard(
                                    record: item,
                                  ),
                                ),
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: PopupMenuButton(
                                    color: AppColors.bgCard,
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                        ),
                                      )
                                    ],
                                    onSelected: (v) {
                                      if (v == 'delete') {
                                        _deleteRecord(
                                          item.id,
                                        );
                                      }
                                    },
                                  ),
                                )
                              ],
                            ),
                          ).animate().fadeIn().slideY(
                                begin: 0.2,
                              );
                        },
                      ),
                    ),
    );
  }
}
