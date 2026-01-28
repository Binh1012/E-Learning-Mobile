import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  static const String TOKEN_KEY = 'auth_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String REMEMBER_ME_KEY = 'remember_me';

  // FIXED: Use 8+ character password
  static const String DEFAULT_EMAIL = 'ngokhanh418@gmail.com';
  static const String DEFAULT_PASSWORD = 'Khanh@123';  // Changed from 123456

  // check remember me
  static Future<void> saveLoginState({
    required String accessToken,
    required String refreshToken,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, accessToken);
    await prefs.setString(REFRESH_TOKEN_KEY, refreshToken);
    await prefs.setBool(REMEMBER_ME_KEY, rememberMe);
  }

// Check remember me
  static Future<bool> isRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(REMEMBER_ME_KEY) ?? false;
  }
  // Get stored token from SharedPreferences
  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(TOKEN_KEY);
    } catch (e) {
      print('Error getting stored token: $e');
      return null;
    }
  }

  // Save tokens to SharedPreferences
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TOKEN_KEY, accessToken);
      await prefs.setString(REFRESH_TOKEN_KEY, refreshToken);
      print('✅ Tokens saved successfully');
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Clear tokens from SharedPreferences
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      await prefs.remove(REFRESH_TOKEN_KEY);
      print('Tokens cleared');
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  // Login and get token
  static Future<String> login({
    String? email,
    String? password,
  }) async {
    final loginEmail = email ?? DEFAULT_EMAIL;
    final loginPassword = password ?? DEFAULT_PASSWORD;

    try {
      print('🔐 Attempting login...');
      print('Email: $loginEmail');
      print('Password length: ${loginPassword.length} characters');

      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': loginEmail,
          'password': loginPassword,
        }),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response structure: ${data.keys.toList()}');

        // Response structure: {"statusCode": 200, "message": "...", "data": {...}}
        if (data['statusCode'] == 200 && data['data'] != null) {
          final tokenData = data['data'];
          final accessToken = tokenData['accessToken'] as String?;
          final refreshToken = tokenData['refreshToken'] as String?;

          if (accessToken != null && accessToken.isNotEmpty) {
            print('✅ Access token received');

            // Save both tokens
            if (refreshToken != null && refreshToken.isNotEmpty) {
              return accessToken;
            } else {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(TOKEN_KEY, accessToken);
            }

            return accessToken;
          } else {
            throw Exception('No access token in response');
          }
        } else {
          throw Exception('Invalid response structure');
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Bad request';
        throw Exception('Login failed: $message');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login error: $e');
    }
  }

  // Get valid token (from storage or login)
  static Future<String> getValidToken() async {
    try {
      // Try to get stored token first
      String? token = await getStoredToken();

      if (token != null && token.isNotEmpty) {
        print('✅ Using cached token');
        return token;
      }

      // If no token, login to get new one
      print('⚠️ No cached token, logging in...');
      token = await login();
      return token;
    } catch (e) {
      print('❌ Error getting valid token: $e');
      throw Exception('Failed to get valid token: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(REFRESH_TOKEN_KEY);
    await prefs.remove(REMEMBER_ME_KEY);
  }

  //register
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final url = Uri.parse('$API_BASE_URL/users');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode({
        "username": name,
        "email": email,
        "password": password,
        "number_phone": phone,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Đăng ký thất bại');
    }
  }


  //forgot pass
  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Request failed');
    }
  }


}