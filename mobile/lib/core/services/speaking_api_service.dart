import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class SpeakingApiService {

  // ===== TOPICS =====
  static Future<List<dynamic>> getLearningTopics() async {
    final token = await AuthService.getValidToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/speaking/learning/topics'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load speaking topics');
    }

    final jsonData = json.decode(response.body);
    return jsonData['data'] ?? [];
  }

  // ===== MATERIALS =====
  static Future<Map<String, dynamic>> getLearningMaterials(int activityId) async {
    final token = await AuthService.getValidToken();

    http.Response response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/speaking/learning/materials/$activityId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    // 🔥 nếu token hết hạn
    if (response.statusCode == 401) {
      await AuthService.clearTokens();
      final newToken = await AuthService.login();

      response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/speaking/learning/materials/$activityId'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $newToken',
        },
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load speaking materials (${response.statusCode})',
      );
    }

    final jsonData = json.decode(response.body);
    return jsonData['data'];
  }
}
