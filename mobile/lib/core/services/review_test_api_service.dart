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
      print('ðŸ“š Loading full lesson data for exam $lessonId...');
      var token = await _getValidTokenWithRetry();
      
      var response = await http.get(
        Uri.parse('$API_BASE_URL/exams/lessons/$lessonId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ðŸ“¨ Lesson response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('âš ï¸ Token expired, refreshing...');
        await AuthService.clearTokens();
        token = await AuthService.login();
        
        response = await http.get(
          Uri.parse('$API_BASE_URL/exams/lessons/$lessonId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        print('ðŸ”„ Retry response: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load lesson data: ${response.statusCode}');
      }

      final lessonData = json.decode(response.body);
      if (lessonData['statusCode'] != 200 || lessonData['data'] == null) {
        throw Exception('Invalid lesson response');
      }

      print('âœ… Loaded lesson data successfully');
      return lessonData;
    } catch (e) {
      print('âŒ Error loading lesson data: $e');
      throw Exception('Error loading lesson data: $e');
    }
  }

  // Submit entire exam with all answers
  // Format: partAnswers = {part_id: "ABCDABCD", ...}
  // Returns complete test results with scoring and level upgrade info
  static Future<Map<String, dynamic>> submitExam({
    required int lessonId,
    required Map<int, String> partAnswers, // Map of part_id -> answer string
  }) async {
    try {
      final token = await _getValidTokenWithRetry();
      
      // Convert Map to List format for API
      final answersList = partAnswers.entries.map((entry) => {
        'part_id': entry.key,
        'answer': entry.value,
      }).toList();
      
      final requestBody = {
        'lesson_id': lessonId,
        'answers': answersList,
      };

      print('ðŸŽ¯ Submitting exam: lessonId=$lessonId');
      print('ðŸ“ Answers: ${jsonEncode(answersList)}');
      
      var response = await http.post(
        Uri.parse('$API_BASE_URL/exams/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('ðŸ“¥ Exam submission response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('âš ï¸ Token expired, retrying...');
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        response = await http.post(
          Uri.parse('$API_BASE_URL/exams/submit'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(requestBody),
        );
        
        print('ðŸ”„ Retry response: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        
        // Log detailed results
        if (result['data'] != null) {
          final examData = result['data'];
          print('âœ… Exam submission successful');
          print('ðŸŽ¯ Total Score: ${examData['total_score']}');
          print('ðŸ“Š Status: ${examData['status']}');
          if (examData['level_upgraded'] == true) {
            print('ðŸŽ‰ Level upgraded to: ${examData['new_level']}');
          } else {
            print('ðŸ“ˆ Keep practicing to level up!');
          }
        }
        
        return result;
      } else {
        print('âŒ Response body: ${response.body}');
        throw Exception('Failed to submit exam: ${response.statusCode}');
      }
    } catch (e) {
      print('âŒ Error submitting exam: $e');
      throw Exception('Error submitting exam: $e');
    }
  }
}
