import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class VocabularyApiService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Get topics with authentication
  static Future<Map<String, dynamic>> getTopics() async {
    try {
      final token = await AuthService.getValidToken();
      
      final response = await http.get(
        Uri.parse('$API_BASE_URL/vocabs/topics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📋 Topics response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.get(
          Uri.parse('$API_BASE_URL/vocabs/topics'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to load topics: ${retryResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to load topics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching topics: $e');
    }
  }

  // Get new words to learn
  static Future<Map<String, dynamic>> getNewWords({
    required String topicName,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      
      final response = await http.get(
        Uri.parse('$API_BASE_URL/vocabs/new-words?topic=${Uri.encodeComponent(topicName)}&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📚 New words response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.get(
          Uri.parse('$API_BASE_URL/vocabs/new-words?topic=${Uri.encodeComponent(topicName)}&limit=$limit'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to load new words: ${retryResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to load new words: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching new words: $e');
    }
  }

  // Get review deck
  static Future<Map<String, dynamic>> getReviewDeck({
    String? topicName,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      
      String url = '$API_BASE_URL/vocabs/review-deck?limit=$limit';
      if (topicName != null) {
        url += '&topic=${Uri.encodeComponent(topicName)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔄 Review deck response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to load review deck: ${retryResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to load review deck: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching review deck: $e');
    }
  }

  // Submit answer with quality rating (1-4)
  // Quality mapping:
  // 1 = Không nhớ (Need to relearn)
  // 2 = Hơi nhớ (Need practice)
  // 3 = Nhớ khá (Mastered)
  // 4 = Nhớ rất tốt (Perfect recall)
  static Future<Map<String, dynamic>> submitAnswer({
    required String wordKey,
    required int quality,
  }) async {
    try {
      // Validate quality range
      if (quality < 1 || quality > 4) {
        throw Exception('Quality must be between 1 and 4');
      }

      final token = await AuthService.getValidToken();
      
      final requestBody = {
        'wordKey': wordKey,
        'quality': quality,
      };

      print('📤 Submitting answer: $requestBody');
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/vocabs/answer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Answer response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        
        // Log spaced repetition data
        if (result['data'] != null) {
          print('✅ Answer submitted successfully');
          print('📊 Ease Factor: ${result['data']['easeFactor']}');
          print('📅 Next Review: ${result['data']['nextReview']}');
          print('⏱️ Interval: ${result['data']['interval']} days');
          print('🔁 Repetition: ${result['data']['repetition']}');
        }
        
        return result;
      } else if (response.statusCode == 401) {
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.post(
          Uri.parse('$API_BASE_URL/vocabs/answer'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(requestBody),
        );
        
        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to submit answer: ${retryResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to submit answer: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting answer: $e');
      throw Exception('Error submitting answer: $e');
    }
  }
}