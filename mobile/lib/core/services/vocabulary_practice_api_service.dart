import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class VocabularyPracticeApiService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Get parts list for a vocabulary lesson
  static Future<Map<String, dynamic>> getLessonParts({
    required int lessonId,
  }) async {
    final token = await AuthService.getValidToken();
    
    final response = await http.get(
      Uri.parse('$API_BASE_URL/grammar/lessons/$lessonId/parts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load parts: ${response.statusCode}');
    }

    final partsData = json.decode(response.body);
    if (partsData['statusCode'] != 200 || partsData['data'] == null) {
      throw Exception('Invalid parts response');
    }

    return partsData;
  }

  // Get part details (includes questions and correct_answer_path)
  static Future<Map<String, dynamic>> getPartDetails({
    required int partId,
  }) async {
    final token = await AuthService.getValidToken();
    
    final response = await http.get(
      Uri.parse('$API_BASE_URL/grammar/parts/$partId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load part details: ${response.statusCode}');
    }

    final partDetailData = json.decode(response.body);
    if (partDetailData['statusCode'] != 200 || partDetailData['data'] == null) {
      throw Exception('Invalid part detail response');
    }

    return partDetailData;
  }

  // Load correct answers from URL
  static Future<String> fetchCorrectAnswers(String correctAnswerPath) async {
    final response = await http.get(Uri.parse(correctAnswerPath));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load correct answers: ${response.statusCode}');
    }

    return utf8.decode(response.bodyBytes).trim();
  }

  // Parse MULTIPLE_CHOICE answers (format: D,C,B,A,D,A)
  static List<String> parseMultipleChoiceAnswers(String content) {
    return content.split(',').map((e) => e.trim()).toList();
  }

  // Parse MATCHING answers (format: digital-kỹ thuật số,network-mạng lưới)
  static Map<String, String> parseMatchingAnswers(String content) {
    final pairs = content.split(',');
    final matchMap = <String, String>{};
    for (var pair in pairs) {
      final parts = pair.split('-');
      if (parts.length == 2) {
        matchMap[parts[0].trim()] = parts[1].trim();
      }
    }
    return matchMap;
  }

  // Parse FILL_IN_BLANK answers (format: hardware,profile)
  static List<String> parseFillInBlankAnswers(String content) {
    return content.split(',').map((e) => e.trim().toLowerCase()).toList();
  }

  // Fetch content from URL (for displayOrders text content)
  static Future<String> fetchContent(String contentPath) async {
    try {
      final response = await http.get(Uri.parse(contentPath));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        return 'Failed to load content';
      }
    } catch (e) {
      print('Error fetching content: $e');
      return 'Error: $e';
    }
  }
}