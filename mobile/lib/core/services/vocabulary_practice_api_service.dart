import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class VocabularyPracticeApiService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Get lesson details with parts - API MỚI
  static Future<Map<String, dynamic>> getLessonWithParts({
    required int lessonId,
  }) async {
    final token = await AuthService.getValidToken();
    
    final response = await http.get(
      Uri.parse('$API_BASE_URL/vocabs/lessons/$lessonId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load lesson: ${response.statusCode}');
    }

    final lessonData = json.decode(response.body);
    if (lessonData['statusCode'] != 200 || lessonData['data'] == null) {
      throw Exception('Invalid lesson response');
    }

    return lessonData;
  }

  // Load correct answers from URL
  static Future<String> fetchCorrectAnswers(String correctAnswerPath) async {
    // Thêm base URL nếu path chưa có
    String fullUrl = correctAnswerPath;
    if (!correctAnswerPath.startsWith('http')) {
      fullUrl = 'https://e-learn-backend.s3.ap-southeast-2.amazonaws.com/$correctAnswerPath';
    }
    
    final response = await http.get(Uri.parse(fullUrl));
    
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

  // Submit lesson answers
  static Future<Map<String, dynamic>> submitLesson({
    required int lessonId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final token = await AuthService.getValidToken();
    
    final response = await http.post(
      Uri.parse('$API_BASE_URL/vocabs/lessons/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'lesson_id': lessonId,
        'answers': answers,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit lesson: ${response.statusCode}');
    }

    final resultData = json.decode(response.body);
    if (resultData['statusCode'] != 200 || resultData['data'] == null) {
      throw Exception('Invalid submit response');
    }

    return resultData;
  }
}