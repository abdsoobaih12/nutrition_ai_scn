import 'package:hive_flutter/hive_flutter.dart';
import 'package:ai_scn/models/analysis_result.dart';

class HistoryService {
  static const String _boxName = 'analysisHistory';

  Future<Box<AnalysisResult>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<AnalysisResult>(_boxName);
    }
    return Hive.box<AnalysisResult>(_boxName);
  }

  Future<void> saveAnalysis(AnalysisResult result) async {
    final box = await _getBox();
    await box.put(result.id, result);
  }

  Future<List<AnalysisResult>> getHistory() async {
    final box = await _getBox();
    final allResults = box.values.toList();
    allResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allResults;
  }

  Future<void> deleteAnalysis(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> clearHistory() async {
    final box = await _getBox();
    await box.clear();
  }
}

