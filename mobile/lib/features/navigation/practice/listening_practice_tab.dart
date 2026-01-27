import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../listening_practice/listening_practice_screen.dart';
import '../../../core/services/auth_service.dart';

class ListeningPracticeTab extends StatefulWidget {
  const ListeningPracticeTab({Key? key}) : super(key: key);

  @override
  State<ListeningPracticeTab> createState() => _ListeningPracticeTabState();
}

class _ListeningPracticeTabState extends State<ListeningPracticeTab> {
  // API Configuration
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Listening Practice Data (loaded from API)
  List<Map<String, dynamic>> _listeningLessons = [];
  bool _isLoadingLessons = true;
  String? _lessonsError;

  // Color palette for lessons
  final List<Color> _colors = [
    const Color(0xFF3DD598),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFB84D),
    const Color(0xFF9B59B6),
    const Color(0xFF3498DB),
  ];

  @override
  void initState() {
    super.initState();
    _loadListeningLessons();
  }

  Future<void> _loadListeningLessons() async {
  setState(() {
    _isLoadingLessons = true;
    _lessonsError = null;
  });

  try {
    final token = await AuthService.getValidToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // 1. Gọi đồng thời cả 2 category
    final List<http.Response> responses = await Future.wait([
      http.get(Uri.parse('$API_BASE_URL/grammar/lessons?categoryId=4'), headers: headers),
      http.get(Uri.parse('$API_BASE_URL/grammar/lessons?categoryId=5'), headers: headers),
    ]);

    // Kiểm tra nếu có bất kỳ request nào bị 401 (Token hết hạn)
    bool isUnauthorized = responses.any((r) => r.statusCode == 401);

    if (isUnauthorized) {
      // Logic Retry giống hệt code cũ của bạn
      await AuthService.clearTokens();
      final newToken = await AuthService.login();
      final newHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $newToken',
      };

      final retryResponses = await Future.wait([
        http.get(Uri.parse('$API_BASE_URL/grammar/lessons?categoryId=4'), headers: newHeaders),
        http.get(Uri.parse('$API_BASE_URL/grammar/lessons?categoryId=5'), headers: newHeaders),
      ]);

      _processResponses(retryResponses);
    } else {
      // Nếu không bị 401, xử lý kết quả bình thường
      _processResponses(responses);
    }
  } catch (e) {
    print('❌ Error loading grammar lessons: $e');
    setState(() {
      _lessonsError = 'Error loading lessons: $e';
      _isLoadingLessons = false;
    });
  }
}

// Tách logic xử lý data ra một hàm riêng để tránh lặp lại code (giữ nguyên logic parse của bạn)
void _processResponses(List<http.Response> responses) {
  List<dynamic> allRawLessons = [];
  bool hasError = false;
  String errorMsg = '';

  for (var response in responses) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['statusCode'] == 200 && data['data'] != null && data['data']['lessons'] != null) {
        allRawLessons.addAll(data['data']['lessons'] as List);
      } else {
        hasError = true;
        errorMsg = 'Invalid response structure';
      }
    } else {
      hasError = true;
      errorMsg = 'Failed to load lessons: ${response.statusCode}';
    }
  }

  if (hasError && allRawLessons.isEmpty) {
    setState(() {
      _lessonsError = errorMsg;
      _isLoadingLessons = false;
    });
    return;
  }

  // Mapping dữ liệu sang UI format (Giữ nguyên logic mapping của bạn)
  setState(() {
    _listeningLessons = allRawLessons.asMap().entries.map((entry) {
      final index = entry.key;
      final lesson = entry.value;

      final title = lesson['title']?.toString() ?? 'Unknown Lesson';
      final description = lesson['description']?.toString() ?? '';
      final level = lesson['level'] as Map<String, dynamic>?;
      final levelDescription = level?['description']?.toString() ?? 'Unknown Level';
      final parts = lesson['parts'] as List? ?? [];

      return {
        'lesson_id': lesson['lesson_id'],
        'title': title,
        'description': description,
        'level': levelDescription,
        'progress': 0.0,
        'lessons': parts.length,
        'color': _colors[index % _colors.length],
      };
    }).toList();
    _isLoadingLessons = false;
  });
}

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoadingLessons) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF3DD598),
            ),
            SizedBox(height: 16),
            Text(
              'Loading listening practice lessons...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    // Error state
    if (_lessonsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load lessons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _lessonsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadListeningLessons,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DD598),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Empty state
    if (_listeningLessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No listening practice lessons available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    // Success state - display lessons
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Listening Practice',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadListeningLessons,
            color: const Color(0xFF3DD598),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _listeningLessons.length,
              itemBuilder: (context, index) {
                final lesson = _listeningLessons[index];
                return _buildListeningCard(context, lesson);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningCard(BuildContext context, Map<String, dynamic> lesson) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListeningPracticeScreen(
              listeningTitle: lesson['title'],
              listeningLevel: lesson['level'],
              lessonId: lesson['lesson_id'],
              lessonDescription: lesson['description']
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lesson['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lesson['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              lesson['description'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Level
            Text(
              lesson['level'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            // Progress row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${(lesson['progress'] * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: lesson['progress'],
                backgroundColor: const Color(0xFFE9ECEF),
                valueColor: AlwaysStoppedAnimation<Color>(lesson['color']),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            
            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lesson['lessons']} parts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: lesson['color'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}