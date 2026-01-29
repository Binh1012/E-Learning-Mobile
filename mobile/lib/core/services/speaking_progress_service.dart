import 'package:shared_preferences/shared_preferences.dart';

class SpeakingProgressService {
  static String _learnedKey(int lessonId) =>
      'speaking_learned_$lessonId';

  static String _totalKey(int lessonId) =>
      'speaking_total_$lessonId';

  /// learned cards
  static Future<Set<String>> getLearned(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_learnedKey(lessonId))?.toSet() ?? {};
  }

  static Future<void> markLearned(
      int lessonId, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getLearned(lessonId);
    set.add(value);
    await prefs.setStringList(
        _learnedKey(lessonId), set.toList());
  }

  /// total cards
  static Future<void> saveTotal(
      int lessonId, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalKey(lessonId), total);
  }

  static Future<int> getTotal(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey(lessonId)) ?? 0;
  }
}
