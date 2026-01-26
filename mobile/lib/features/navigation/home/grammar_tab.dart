import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../grammar/grammar_lesson_screen.dart';
import '../../../core/services/auth_service.dart';

class GrammarTab extends StatefulWidget {
  const GrammarTab({Key? key}) : super(key: key);

  @override
  State<GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends State<GrammarTab> {
  // API Configuration
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Grammar Lessons Data (loaded from API)
  List<Map<String, dynamic>> _grammarLessons = [];
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
    _loadGrammarLessons();
  }

  Future<void> _loadGrammarLessons() async {
    setState(() {
      _isLoadingLessons = true;
      _lessonsError = null;
    });

    try {
      final token = await AuthService.getValidToken();
      
      // Gọi API /api/grammar/lessons
      final response = await http.get(
        Uri.parse('$API_BASE_URL/grammar/lessons?limit=50&categoryId=2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📚 Grammar lessons response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse response: {statusCode: 200, message: "Success", data: {lessons: [...], pagination: {...}}}
        if (data['statusCode'] == 200 && data['data'] != null && data['data']['lessons'] != null) {
          final lessons = data['data']['lessons'] as List;
          
          setState(() {
            _grammarLessons = lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              
              // Extract data
              final title = lesson['title']?.toString() ?? 'Unknown Lesson';
              final description = lesson['description']?.toString() ?? '';
              final level = lesson['level'] as Map<String, dynamic>?;
              final levelDescription = level?['description']?.toString() ?? 'Unknown Level';
              final parts = lesson['parts'] as List? ?? [];
              
              // Map to UI format
              return {
                'lesson_id': lesson['lesson_id'],
                'title': title,
                'description': description,
                'level': levelDescription,
                'progress': 0.0, // TODO: Sẽ lấy từ API progress sau
                'lessons': parts.length,
                'color': _colors[index % _colors.length],
              };
            }).toList();
            _isLoadingLessons = false;
          });
        } else {
          setState(() {
            _lessonsError = 'Invalid response structure';
            _isLoadingLessons = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired, retry with new token
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.get(
          Uri.parse('$API_BASE_URL/grammar/lessons?limit=20'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          
          if (data['statusCode'] == 200 && data['data'] != null && data['data']['lessons'] != null) {
            final lessons = data['data']['lessons'] as List;
            
            setState(() {
              _grammarLessons = lessons.asMap().entries.map((entry) {
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
          } else {
            setState(() {
              _lessonsError = 'Invalid response structure';
              _isLoadingLessons = false;
            });
          }
        } else {
          setState(() {
            _lessonsError = 'Failed to load lessons: ${retryResponse.statusCode}';
            _isLoadingLessons = false;
          });
        }
      } else {
        setState(() {
          _lessonsError = 'Failed to load lessons: ${response.statusCode}';
          _isLoadingLessons = false;
        });
      }
    } catch (e) {
      print('❌ Error loading grammar lessons: $e');
      setState(() {
        _lessonsError = 'Error loading lessons: $e';
        _isLoadingLessons = false;
      });
    }
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
              'Loading grammar lessons...',
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
              onPressed: _loadGrammarLessons,
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
    if (_grammarLessons.isEmpty) {
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
              'No grammar lessons available',
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
            'Grammar Points',
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
            onRefresh: _loadGrammarLessons,
            color: const Color(0xFF3DD598),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _grammarLessons.length,
              itemBuilder: (context, index) {
                final lesson = _grammarLessons[index];
                return _buildGrammarCard(context, lesson);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrammarCard(BuildContext context, Map<String, dynamic> lesson) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarLessonScreen(
              grammarTitle: lesson['title'],
              grammarLevel: lesson['level'],
              lessonId: lesson['lesson_id'],
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