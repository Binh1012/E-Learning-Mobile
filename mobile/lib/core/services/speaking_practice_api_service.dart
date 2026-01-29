import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class SpeakingPracticeApiService {
  static const String _baseUrl = 'http://api.e-learning.click/api';

  /// Lấy materials để practice
  static Future<Map<String, dynamic>> getTestMaterials(int activityId) async {
    final token = await AuthService.getValidToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/speaking/learning/test/materials/$activityId'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load speaking materials');
    }

    final data = json.decode(response.body);
    if (data['statusCode'] != 200 || data['data'] == null) {
      throw Exception('Invalid speaking materials response');
    }

    return data['data'];
  }
}
