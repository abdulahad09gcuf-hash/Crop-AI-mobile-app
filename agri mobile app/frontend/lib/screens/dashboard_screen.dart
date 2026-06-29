// lib/screens/dashboard_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'models/prediction_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StatsSummary? _stats;
  List<PredictionRecord> _records = [];
  bool _loading = true;
  int _pieTouched = -1;
  bool _serverOk = false;
  Map<String, dynamic>? _modelInfo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _serverOk = await ApiService.healthCheck();

      final raw = await ApiService.getHistory(limit: 200);

      _records = raw
          .map((e) => PredictionRecord.fromHistory(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      _stats = StatsSummary.fromRecords(_records);

      try {
        _modelInfo = await ApiService.getModelInfo();
      } catch (_) {}
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // 🌿 Light Green Theme Colors
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color darkGreen = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        title: Text(
          'Crop Diagnosis++',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _serverOk ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _serverOk ? 'Online' : 'Offline',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    if ((_stats?.total ?? 0) > 0) ...[
                      _buildPieChart(),
                      const SizedBox(height: 20),
                      _buildBarChart(),
                      const SizedBox(height: 20),
                      _buildConfidenceChart(),
                      const SizedBox(height: 20),
                    ] else
                      _buildEmptyState(),
                    if (_modelInfo != null) ...[
                      _buildModelInfoCard(),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Stat Cards
  // ─────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final s = _stats;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          'Total Scans',
          '${s?.total ?? 0}',
          Icons.document_scanner,
          primaryGreen,
        ),
        _StatCard(
          'Healthy',
          '${s?.healthy ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _StatCard(
          'Diseased',
          '${s?.diseased ?? 0}',
          Icons.bug_report,
          Colors.orange,
        ),
        _StatCard(
          'Deficiency',
          '${s?.deficiency ?? 0}',
          Icons.water_drop,
          Colors.teal,
        ),
      ],
    ).animate().fadeIn();
  }

  // ─────────────────────────────────────────────────────
  // Pie Chart
  // ─────────────────────────────────────────────────────

  Widget _buildPieChart() {
    final s = _stats!;

    if (s.byCategory.isEmpty) {
      return const SizedBox();
    }

    final entries = s.byCategory.entries.toList();

    return _ChartCard(
      title: 'Disease Categories',
      subtitle: 'Distribution of crop scan results',
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (_, r) {
                      setState(() {
                        _pieTouched =
                            r?.touchedSection?.touchedSectionIndex ?? -1;
                      });
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  sections: List.generate(entries.length, (i) {
                    final isTouched = i == _pieTouched;

                    final colors = [
                      Colors.green,
                      Colors.lightGreen,
                      Colors.teal,
                      Colors.orange,
                      Colors.lime,
                    ];

                    return PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      color: colors[i % colors.length],
                      radius: isTouched ? 70 : 58,
                      title: isTouched ? '${entries[i].value}' : '',
                      titleStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final colors = [
                  Colors.green,
                  Colors.lightGreen,
                  Colors.teal,
                  Colors.orange,
                  Colors.lime,
                ];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i % colors.length],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entries[i].key} (${entries[i].value})',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ─────────────────────────────────────────────────────
  // Bar Chart
  // ─────────────────────────────────────────────────────

  Widget _buildBarChart() {
    return _ChartCard(
      title: 'Top Conditions',
      subtitle: 'Most frequently detected diseases',
      child: const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Bar Chart Here',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Confidence Chart
  // ─────────────────────────────────────────────────────

  Widget _buildConfidenceChart() {
    return _ChartCard(
      title: 'Confidence Trend',
      subtitle: 'Prediction confidence levels',
      child: const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Confidence Chart Here',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Model Info
  // ─────────────────────────────────────────────────────

  Widget _buildModelInfoCard() {
    return _ChartCard(
      title: 'Model Info',
      subtitle: 'Loaded AI model details',
      child: Column(
        children: [
          _infoRow(
            'Architecture',
            _modelInfo!['model_type'] ?? 'MobileNet V3',
          ),
          _infoRow(
            'Parameters',
            '${_modelInfo!['parameters_M'] ?? '?'} M',
          ),
          _infoRow(
            'Classes',
            '${_modelInfo!['num_classes'] ?? 16}',
          ),
          _infoRow(
            'Image Size',
            '256 × 256 px',
          ),
          _infoRow(
            'Device',
            'CPU',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.green.shade700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: darkGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 56,
              color: primaryGreen,
            ),
            const SizedBox(height: 12),
            Text(
              'No crop data yet',
              style: GoogleFonts.spaceGrotesk(
                color: darkGreen,
                fontSize: 18,
              ),
            ),
            Text(
              'Scan crops to view analytics',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Stat Card Widget
// ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
    this.label,
    this.value,
    this.icon,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Chart Card Widget
// ─────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade900,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
