import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class ListeningPracticeApiService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Helper method to check and refresh token on 401
  static Future<String> _getValidTokenWithRetry() async {
    return await AuthService.getValidToken();
  }
  
  // Get parts list for a lesson
  static Future<Map<String, dynamic>> getLessonParts({
    required int lessonId,
  }) async {
    try {
      print('📚 Loading parts for lesson $lessonId...');
      var token = await _getValidTokenWithRetry();
      
      var response = await http.get(
        Uri.parse('$API_BASE_URL/grammar/lessons/$lessonId/parts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Parts response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('⚠️ Token expired, refreshing...');
        await AuthService.clearTokens();
        token = await AuthService.login();
        
        response = await http.get(
          Uri.parse('$API_BASE_URL/grammar/lessons/$lessonId/parts'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        print('🔄 Retry response: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load parts: ${response.statusCode}');
      }

      final partsData = json.decode(response.body);
      if (partsData['statusCode'] != 200 || partsData['data'] == null) {
        throw Exception('Invalid parts response');
      }

      print('✅ Loaded parts successfully');
      return partsData;
    } catch (e) {
      print('❌ Error loading parts: $e');
      throw Exception('Error loading parts: $e');
    }
  }

  // Get part details (includes questions)
  static Future<Map<String, dynamic>> getPartDetails({
    required int partId,
  }) async {
    try {
      print('📖 Loading part details for part $partId...');
      var token = await _getValidTokenWithRetry();
      
      var response = await http.get(
        Uri.parse('$API_BASE_URL/grammar/parts/$partId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Part details response: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('⚠️ Token expired, refreshing...');
        await AuthService.clearTokens();
        token = await AuthService.login();
        
        response = await http.get(
          Uri.parse('$API_BASE_URL/grammar/parts/$partId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        print('🔄 Retry response: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load part details: ${response.statusCode}');
      }

      final partDetailData = json.decode(response.body);
      if (partDetailData['statusCode'] != 200 || partDetailData['data'] == null) {
        throw Exception('Invalid part detail response');
      }

      print('✅ Loaded part details successfully');
      return partDetailData;
    } catch (e) {
      print('❌ Error loading part details: $e');
      throw Exception('Error loading part details: $e');
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
        Uri.parse('$API_BASE_URL/grammar/lessons/$lessonId/parts/$partId/submissions'),
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
          Uri.parse('$API_BASE_URL/grammar/lessons/$lessonId/parts/$partId/submissions'),
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