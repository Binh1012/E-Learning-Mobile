import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../review_test/review_test_screen.dart'; // TODO: Import when screen is ready

class ProgressTab extends StatefulWidget {
  const ProgressTab({Key? key}) : super(key: key);

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final TextEditingController _searchController = TextEditingController();
  
  // API Configuration
  static const String API_BASE_URL = 'http://api.e-learning.click/api';
  
  // Exam Lessons Data (loaded from API)
  List<Map<String, dynamic>> _examLessons = [];
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
    _loadExamLessons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExamLessons() async {
    setState(() {
      _isLoadingLessons = true;
      _lessonsError = null;
    });

    try {
      final token = await AuthService.getValidToken();
      
      // Call API /api/exams/lessons
      final response = await http.get(
        Uri.parse('$API_BASE_URL/exams/lessons'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📚 Exam lessons response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse response: {statusCode: 200, message: "Success", data: {lessons: [...], pagination: {...}}}
        if (data['statusCode'] == 200 && data['data'] != null) {
          List lessons;
          
          // Check if data has 'lessons' key or is directly an array
          if (data['data'] is List) {
            lessons = data['data'] as List;
          } else if (data['data']['lessons'] != null) {
            lessons = data['data']['lessons'] as List;
          } else {
            lessons = [];
          }
          
          setState(() {
            _examLessons = lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              
              // Extract data
              final title = lesson['title']?.toString() ?? 'Unknown Test';
              final description = lesson['description']?.toString() ?? '';
              final level = lesson['level'] as Map<String, dynamic>?;
              final levelName = level?['name']?.toString() ?? 'A1';
              final levelDescription = level?['description']?.toString() ?? 'Unknown Level';
              final parts = lesson['parts'] as List? ?? [];
              
              // Map to UI format
              return {
                'lesson_id': lesson['lesson_id'],
                'title': title,
                'description': description,
                'level': levelDescription,
                'level_name': levelName,
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
          Uri.parse('$API_BASE_URL/exams/lessons'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          
          if (data['statusCode'] == 200 && data['data'] != null) {
            List lessons;
            
            if (data['data'] is List) {
              lessons = data['data'] as List;
            } else if (data['data']['lessons'] != null) {
              lessons = data['data']['lessons'] as List;
            } else {
              lessons = [];
            }
            
            setState(() {
              _examLessons = lessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                
                final title = lesson['title']?.toString() ?? 'Unknown Test';
                final description = lesson['description']?.toString() ?? '';
                final level = lesson['level'] as Map<String, dynamic>?;
                final levelName = level?['name']?.toString() ?? 'A1';
                final levelDescription = level?['description']?.toString() ?? 'Unknown Level';
                final parts = lesson['parts'] as List? ?? [];
                
                return {
                  'lesson_id': lesson['lesson_id'],
                  'title': title,
                  'description': description,
                  'level': levelDescription,
                  'level_name': levelName,
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
      print('❌ Error loading exam lessons: $e');
      setState(() {
        _lessonsError = 'Error loading lessons: $e';
        _isLoadingLessons = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header with Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/Logo.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3DD598),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Welcome Title
                  const Expanded(
                    child: Text(
                      'Review Test',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Notification Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DD598),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tests',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              'Loading exam lessons...',
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
              onPressed: _loadExamLessons,
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
    if (_examLessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No exam lessons available',
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
    return RefreshIndicator(
      onRefresh: _loadExamLessons,
      color: const Color(0xFF3DD598),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: _examLessons.length,
        itemBuilder: (context, index) {
          final lesson = _examLessons[index];
          return _buildExamCard(context, lesson);
        },
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> lesson) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewTestScreen(
              testTitle: lesson['title'],
              testLevel: lesson['level'],
              lessonId: lesson['lesson_id'],
              lessonDescription: lesson['description'],
            ),
          ),
        );
        
        // Temporary: Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening: ${lesson['title']}'),
            backgroundColor: const Color(0xFF3DD598),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                  'Start Test',
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