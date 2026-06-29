// lib/models/prediction_model.dart

class PredictionRecord {
  final String id;
  final String predictedLabel;
  final double confidence;
  final Map<String, dynamic> recommendation;
  final List<MapEntry<String, double>> top5;
  final String? filename;
  final String? createdAt;

  PredictionRecord({
    required this.id,
    required this.predictedLabel,
    required this.confidence,
    required this.recommendation,
    required this.top5,
    this.filename,
    this.createdAt,
  });

  // From /predict response
  factory PredictionRecord.fromJson(Map<String, dynamic> json) {
    final top5Raw = json['top_5'] as List<dynamic>? ?? [];
    final top5 = top5Raw.map((e) {
      if (e is List) return MapEntry(e[0].toString(), (e[1] as num).toDouble());
      if (e is Map) {
        final key = e.keys.first.toString();
        return MapEntry(key, (e[key] as num).toDouble());
      }
      return MapEntry('unknown', 0.0);
    }).toList();

    return PredictionRecord(
      id: json['record_id']?.toString() ?? '',
      predictedLabel: json['predicted_label'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: Map<String, dynamic>.from(json['recommendation'] ?? {}),
      top5: top5,
      filename: json['filename'],
      createdAt: null,
    );
  }

  // From /history list
  factory PredictionRecord.fromHistory(Map<String, dynamic> json) {
    final rec = json['recommendation'];
    final recMap = rec is Map ? Map<String, dynamic>.from(rec) : <String, dynamic>{};

    return PredictionRecord(
      id: json['id']?.toString() ?? '',
      predictedLabel: json['predicted_label'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: recMap,
      top5: [],
      filename: json['filename'],
      createdAt: json['created_at']?.toString(),
    );
  }

  String get displayLabel =>
      predictedLabel.replaceAll('_', ' ').replaceAll('  ', ' ');

  String get confidencePct => '${(confidence * 100).toStringAsFixed(1)}%';

  bool get isHealthy =>
      predictedLabel.toLowerCase().contains('healthy');

  bool get isDeficiency =>
      predictedLabel.toLowerCase().contains('deficiency') ||
      predictedLabel.toLowerCase().contains('nitrogen') ||
      predictedLabel.toLowerCase().contains('phosphorous') ||
      predictedLabel.toLowerCase().contains('potassium') ||
      predictedLabel.toLowerCase().contains('pottasium') ||
      predictedLabel.toLowerCase().contains('magnessium');

  String get typeLabel {
    if (isHealthy) return 'Healthy';
    if (isDeficiency) return 'Deficiency';
    final type = recommendation['type']?.toString() ?? '';
    if (type.isNotEmpty) return type;
    return 'Disease';
  }
}

class StatsSummary {
  final int total;
  final int healthy;
  final int diseased;
  final int deficiency;
  final Map<String, int> byCategory;
  final Map<String, int> byLabel;

  StatsSummary({
    required this.total,
    required this.healthy,
    required this.diseased,
    required this.deficiency,
    required this.byCategory,
    required this.byLabel,
  });

  factory StatsSummary.fromRecords(List<PredictionRecord> records) {
    int h = 0, dis = 0, def = 0;
    final byCategory = <String, int>{};
    final byLabel    = <String, int>{};

    for (final r in records) {
      if (r.isHealthy)         { h++;   }
      else if (r.isDeficiency) { def++; }
      else                     { dis++; }

      final cat = r.typeLabel;
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;

      final lbl = r.displayLabel;
      byLabel[lbl] = (byLabel[lbl] ?? 0) + 1;
    }

    return StatsSummary(
      total: records.length,
      healthy: h,
      diseased: dis,
      deficiency: def,
      byCategory: byCategory,
      byLabel: byLabel,
    );
  }
}