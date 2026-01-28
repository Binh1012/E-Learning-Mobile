import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class ReviewTestApiService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Helper method to check and refresh token on 401
  static Future<String> _getValidTokenWithRetry() async {
    return await AuthService.getValidToken();
  }
  
  // Get full lesson data (parts + questions + displayOrders) in one call
  static Future<Map<String, dynamic>> getLessonData({
    required int lessonId,
  }) async {
    try {
      print('📚 Loading full lesson data for exam $lessonId...');
      var token = await _getValidTokenWithRetry();
      
      var response = await http.get(
        Uri.parse('$API_BASE_URL/exams/lessons/$lessonId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Lesson response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('⚠️ Token expired, refreshing...');
        await AuthService.clearTokens();
        token = await AuthService.login();
        
        response = await http.get(
          Uri.parse('$API_BASE_URL/exams/lessons/$lessonId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        print('🔄 Retry response: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load lesson data: ${response.statusCode}');
      }

      final lessonData = json.decode(response.body);
      if (lessonData['statusCode'] != 200 || lessonData['data'] == null) {
        throw Exception('Invalid lesson response');
      }

      print('✅ Loaded lesson data successfully');
      return lessonData;
    } catch (e) {
      print('❌ Error loading lesson data: $e');
      throw Exception('Error loading lesson data: $e');
    }
  }

  // Submit all answers for a part and get scoring feedback
  // Format: answers = "ABCDA" (concatenated answers for all questions in part)
  // Returns score and detailed feedback (correct answers, submission ID, etc.)
  static Future<Map<String, dynamic>> submitPartAnswers({
    required int lessonId,
    required int partId,
    required String answers,
  }) async {
    try {
      final token = await _getValidTokenWithRetry();
      
      final requestBody = {
        'answers': answers,
      };

      print('📤 Submitting part answers: lessonId=$lessonId, partId=$partId, answers=$answers');
      
      var response = await http.post(
        Uri.parse('$API_BASE_URL/exams/lessons/$lessonId/parts/$partId/submissions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Part submission response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('⚠️ Token expired, retrying...');
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        response = await http.post(
          Uri.parse('$API_BASE_URL/exams/lessons/$lessonId/parts/$partId/submissions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(requestBody),
        );
        
        print('🔄 Retry response: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        
        // Log detailed feedback
        if (result['data'] != null && result['data']['data'] != null) {
          final submissionData = result['data']['data'];
          print('✅ Part submission successful');
          print('🎯 Score: ${submissionData['score']}');
          print('✏️ Your answers: ${submissionData['answers']}');
          print('✓ Correct answers: ${submissionData['correctAnswers']}');
          print('🔖 Submission ID: ${submissionData['userSubmissionId']}');
        }
        
        return result;
      } else {
        throw Exception('Failed to submit part answers: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting part answers: $e');
      throw Exception('Error submitting part answers: $e');
    }
  }

  // Load correct answers from URL
  static Future<String> fetchCorrectAnswers(String correctAnswerPath) async {
    try {
      print('📥 Fetching correct answers from: $correctAnswerPath');
      final response = await http.get(Uri.parse(correctAnswerPath));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load correct answers: ${response.statusCode}');
      }

      final answers = utf8.decode(response.bodyBytes).trim();
      print('✅ Loaded correct answers: ${answers.length} characters');
      return answers;
    } catch (e) {
      print('❌ Error fetching correct answers: $e');
      throw Exception('Error fetching correct answers: $e');
    }
  }
}