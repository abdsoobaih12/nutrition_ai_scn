import 'package:hive/hive.dart';

part 'analysis_result.g.dart';

@HiveType(typeId: 0)
class AnalysisResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final String analysisResult;

  AnalysisResult({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.analysisResult,
  });

  AnalysisResult.create({
    required this.imagePath,
    required this.analysisResult,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now();
}

