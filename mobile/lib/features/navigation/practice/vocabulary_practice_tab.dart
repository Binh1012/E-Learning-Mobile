import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../vocab_practice/vocabulary_practice_screen.dart';

class VocabularyPracticeTab extends StatefulWidget {
  const VocabularyPracticeTab({Key? key}) : super(key: key);

  @override
  State<VocabularyPracticeTab> createState() => _VocabularyPracticeTabState();
}

class _VocabularyPracticeTabState extends State<VocabularyPracticeTab> {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  List<Map<String, dynamic>> _vocabularyLessons = [];
  bool _isLoadingLessons = true;
  String? _lessonsError;

  @override
  void initState() {
    super.initState();
    _loadVocabularyLessons();
  }

  Future<void> _loadVocabularyLessons() async {
    setState(() {
      _isLoadingLessons = true;
      _lessonsError = null;
    });

    try {
      final token = await AuthService.getValidToken();
      
      // Changed from grammar/lessons to vocabulary/lessons
      final response = await http.get(
        Uri.parse('$API_BASE_URL/grammar/lessons?limit=50&categoryId=2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📚 Vocabulary lessons response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['statusCode'] == 200 && data['data'] != null && data['data']['lessons'] != null) {
          final lessons = data['data']['lessons'] as List;
          
          setState(() {
            _vocabularyLessons = lessons.map((lesson) {
              final title = lesson['title']?.toString() ?? 'Unknown Lesson';
              final description = lesson['description']?.toString() ?? '';
              final parts = lesson['parts'] as List? ?? [];
              
              return {
                'lesson_id': lesson['lesson_id'],
                'title': title,
                'description': description,
                'progress': 0.0,
                'parts': parts.length,
                'completed': 0,
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
        await AuthService.clearTokens();
        final newToken = await AuthService.login();
        
        final retryResponse = await http.get(
          Uri.parse('$API_BASE_URL/vocabulary/lessons?limit=20'),
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
              _vocabularyLessons = lessons.map((lesson) {
                final title = lesson['title']?.toString() ?? 'Unknown Lesson';
                final description = lesson['description']?.toString() ?? '';
                final parts = lesson['parts'] as List? ?? [];
                
                return {
                  'lesson_id': lesson['lesson_id'],
                  'title': title,
                  'description': description,
                  'progress': 0.0,
                  'parts': parts.length,
                  'completed': 0,
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
      print('❌ Error loading vocabulary lessons: $e');
      setState(() {
        _lessonsError = 'Error loading lessons: $e';
        _isLoadingLessons = false;
      });
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.7) {
      return const Color(0xFF3DD598); // Green for high progress
    } else if (progress >= 0.3) {
      return const Color(0xFFFFB84D); // Orange for medium progress
    } else {
      return const Color(0xFF3DD598); // Default green
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
            CircularProgressIndicator(color: Color(0xFF3DD598)),
            SizedBox(height: 16),
            Text(
              'Loading vocabulary lessons...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Failed to load lessons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _lessonsError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVocabularyLessons,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DD598),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_vocabularyLessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.abc, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No vocabulary lessons available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            'Vocabulary Practice',
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
            onRefresh: _loadVocabularyLessons,
            color: const Color(0xFF3DD598),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _vocabularyLessons.length,
              itemBuilder: (context, index) {
                final lesson = _vocabularyLessons[index];
                return _buildPracticeCard(lesson);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(Map<String, dynamic> lesson) {
    final progress = lesson['progress'] as double;
    final progressPercent = (progress * 100).toInt();
    final progressColor = _getProgressColor(progress);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            lesson['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          if (lesson['description'] != null && lesson['description'].toString().isNotEmpty) ...[
            Text(
              lesson['description'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Parts info
          Text(
            '${lesson['completed']} of ${lesson['parts']} completed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$progressPercent%',
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
              value: progress,
              backgroundColor: const Color(0xFFE9ECEF),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Practice Now button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to vocabulary practice screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VocabularyPracticeScreen(
                      vocabularyTitle: lesson['title'],
                      lessonId: lesson['lesson_id'],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DD598),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Practice Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}