import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SpeakingApiService {
  static const _baseUrl =
      'http://api.e-learning.click/api';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token missing');
    }
    return {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getTopics() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/speaking/learning/topics'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Load topics failed');
    }
    return jsonDecode(res.body)['data'];
  }

  static Future<Map<String, dynamic>> getMaterials(
      int activityId) async {
    final res = await http.get(
      Uri.parse(
          '$_baseUrl/speaking/learning/materials/$activityId'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Load materials failed');
    }
    return jsonDecode(res.body)['data'];
  }
}
