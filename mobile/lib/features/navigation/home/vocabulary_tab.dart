import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../vocab/flashcard_screen.dart';

class VocabularyTab extends StatefulWidget {
  const VocabularyTab({Key? key}) : super(key: key);

  @override
  State<VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends State<VocabularyTab> {
  // API Configuration
  static const String API_BASE_URL = 'http://10.0.5.88:3000/api';
  
  // Vocabulary Topics Data (loaded from API)
  List<Map<String, dynamic>> _vocabularyTopics = [];
  bool _isLoadingTopics = true;
  String? _topicsError;

  @override
  void initState() {
    super.initState();
    _loadVocabularyTopics();
  }

  Future<void> _loadVocabularyTopics() async {
    setState(() {
      _isLoadingTopics = true;
      _topicsError = null;
    });

    try {
      final response = await http.get(Uri.parse('$API_BASE_URL/topics'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topics = data['data'] as List;
        
        // Map API topics to UI format with colors
        final colors = [
          const Color(0xFF3DD598),
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
          const Color(0xFFFFB84D),
          const Color(0xFF9B59B6),
          const Color(0xFF3498DB),
        ];
        
        setState(() {
          _vocabularyTopics = topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;
            return {
              'title': topic['topic'],
              'level': _getTopicLevel(topic['count']),
              'progress': 0.0,
              'lessons': topic['count'],
              'color': colors[index % colors.length],
            };
          }).toList();
          _isLoadingTopics = false;
        });
      } else {
        setState(() {
          _topicsError = 'Failed to load topics: ${response.statusCode}';
          _isLoadingTopics = false;
        });
      }
    } catch (e) {
      setState(() {
        _topicsError = 'Error loading topics: $e';
        _isLoadingTopics = false;
      });
    }
  }
  
  String _getTopicLevel(int wordCount) {
    if (wordCount > 50) return 'Advanced';
    if (wordCount > 20) return 'Intermediate';
    return 'Beginner';
  }

  void _navigateToFlashcard(Map<String, dynamic> topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          topicTitle: topic['title'],
          topicLevel: topic['level'],
          totalLessons: topic['lessons'],
          progress: topic['progress'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoadingTopics) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF3DD598),
            ),
            SizedBox(height: 16),
            Text(
              'Loading topics...',
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
    if (_topicsError != null) {
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
              'Failed to load topics',
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
                _topicsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVocabularyTopics,
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
    if (_vocabularyTopics.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No topics available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    // Success state - display topics
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Vocabulary Topics',
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
            onRefresh: _loadVocabularyTopics,
            color: const Color(0xFF3DD598),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _vocabularyTopics.length,
              itemBuilder: (context, index) {
                final topic = _vocabularyTopics[index];
                return _buildTopicCard(topic);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () => _navigateToFlashcard(topic),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic['title'],
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
                    color: topic['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              topic['level'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
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
                  '${(topic['progress'] * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: topic['progress'],
                backgroundColor: const Color(0xFFE9ECEF),
                valueColor: AlwaysStoppedAnimation<Color>(topic['color']),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${topic['lessons']} lessons',
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
                    color: topic['color'],
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