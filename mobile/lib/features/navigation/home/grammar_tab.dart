import 'package:flutter/material.dart';
import '../../grammar/grammar_lesson_screen.dart';

class GrammarTab extends StatelessWidget {
  const GrammarTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Grammar Points Data
    final List<Map<String, dynamic>> grammarPoints = [
      {
        'title': 'Present Simple Tense',
        'description': 'Learn basic present tense usage',
        'level': 'Beginner',
        'progress': 0.85,
        'lessons': 10,
        'color': const Color(0xFF3DD598),
      },
      {
        'title': 'Past Simple Tense',
        'description': 'Understanding past actions',
        'level': 'Beginner',
        'progress': 0.60,
        'lessons': 12,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'title': 'Future Tense',
        'description': 'Express future plans',
        'level': 'Intermediate',
        'progress': 0.40,
        'lessons': 14,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Present Continuous',
        'description': 'Actions happening now',
        'level': 'Beginner',
        'progress': 0.75,
        'lessons': 8,
        'color': const Color(0xFFFFB84D),
      },
      {
        'title': 'Modal Verbs',
        'description': 'Can, could, should, must',
        'level': 'Intermediate',
        'progress': 0.50,
        'lessons': 15,
        'color': const Color(0xFF9B59B6),
      },
      {
        'title': 'Conditional Sentences',
        'description': 'If clauses and conditions',
        'level': 'Advanced',
        'progress': 0.30,
        'lessons': 18,
        'color': const Color(0xFF3498DB),
      },
    ];

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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: grammarPoints.length,
            itemBuilder: (context, index) {
              final point = grammarPoints[index];
              return _buildGrammarCard(context, point);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrammarCard(BuildContext context, Map<String, dynamic> point) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarLessonScreen(
              grammarTitle: point['title'],
              grammarLevel: point['level'],
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
                    point['title'],
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
                    color: point['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              point['description'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Level
            Text(
              point['level'],
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
                  '${(point['progress'] * 100).toInt()}%',
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
                value: point['progress'],
                backgroundColor: const Color(0xFFE9ECEF),
                valueColor: AlwaysStoppedAnimation<Color>(point['color']),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            
            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${point['lessons']} lessons',
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
                    color: point['color'],
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