import 'dart:io';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class UserService {
  static const String _baseUrl = 'http://api.e-learning.click/api';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Attach Bearer token
  static Future<Options> _authOptions() async {
    final token = await AuthService.getValidToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // ===============================
  // GET /api/users
  // ===============================
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(
      '/users',
      options: await _authOptions(),
    );

    if (response.statusCode == 200 && response.data['data'] != null) {
      return response.data['data'];
    }

    throw Exception('Failed to load profile');
  }

  // ===============================
  // PATCH /api/users
  // ===============================
  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String phoneNumber,
  }) async {
    final response = await _dio.patch(
      '/users',
      data: {
        'username': username,
        'phone_number': phoneNumber,
      },
      options: await _authOptions(),
    );

    if (response.statusCode == 200 && response.data['data'] != null) {
      return response.data['data'];
    }

    throw Exception('Failed to update profile');
  }

  // ===============================
  // PATCH /api/users/update-avatar
  // ===============================
  static Future<void> updateAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.patch(
      '/users/update-avatar',
      data: formData,
      options: await _authOptions(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload avatar');
    }
  }
}
