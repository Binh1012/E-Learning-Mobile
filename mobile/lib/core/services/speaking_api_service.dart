import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class SpeakingApiService {

  // ===== LẤY DANH SÁCH TOPIC =====
  static Future<List<dynamic>> getLearningTopics() async {
    final token = await AuthService.getStoredToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/speaking/learning/topics'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load speaking topics');
    }
  }

  // ===== LẤY MATERIAL THEO ACTIVITY =====
  static Future<Map<String, dynamic>> getLearningMaterials(int activityId) async {
    final token = await AuthService.getStoredToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/speaking/learning/materials/$activityId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load speaking materials');
    }
  }
}
