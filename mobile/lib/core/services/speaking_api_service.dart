import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SpeakingApiService {
  static const String _baseUrl = 'http://api.e-learning.click/api';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getStoredToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    return {
      'Content-Type': 'application/json',
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1️⃣ Get topics
  static Future<List<dynamic>> getTopics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/speaking/learning/topics'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load speaking topics');
    }

    final json = jsonDecode(response.body);
    return json['data'] ?? [];
  }

  /// 2️⃣ Get materials by activityId
  static Future<Map<String, dynamic>> getMaterials(int activityId) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/speaking/learning/materials/$activityId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load speaking detail');
    }

    final json = jsonDecode(response.body);
    return json['data'];
  }
}
