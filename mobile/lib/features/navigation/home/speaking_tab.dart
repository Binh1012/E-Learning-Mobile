import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';

class SpeakingTab extends StatefulWidget {
  const SpeakingTab({Key? key}) : super(key: key);

  @override
  State<SpeakingTab> createState() => _SpeakingTabState();
}

class _SpeakingTabState extends State<SpeakingTab> {
  static const String API_BASE_URL = 'http://api.e-learning.click/api';

  bool _isLoading = true;
  String? _error;
  List<dynamic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadSpeakingTopics();
  }

  Future<void> _loadSpeakingTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getValidToken();

      var response = await http.get(
        Uri.parse('$API_BASE_URL/speaking/learning/topics'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await AuthService.clearTokens();
        final newToken = await AuthService.login();

        response = await http.get(
          Uri.parse('$API_BASE_URL/speaking/learning/topics'),
          headers: {
            'accept': '*/*',
            'Authorization': 'Bearer $newToken',
          },
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load speaking topics');
      }

      final data = jsonDecode(response.body);
      setState(() {
        _topics = data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), // giống Vocabulary
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Speaking Topics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CD080),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Không thể tải Speaking\nVui lòng thử lại',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (_topics.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có nội dung Speaking',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF4CD080),
      onRefresh: _loadSpeakingTopics,
      child: ListView.builder(
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          final topic = _topics[index];
          return _buildSpeakingCard(topic);
        },
      ),
    );
  }

  Widget _buildSpeakingCard(dynamic topic) {
    final bool isCompleted = topic['is_completed'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title + status dot
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Progress bar (Speaking chưa có % → dùng completed)
            LinearProgressIndicator(
              value: isCompleted ? 1.0 : 0.0,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF4CD080),
              minHeight: 6,
            ),

            const SizedBox(height: 8),

            /// Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted ? 'Completed' : 'Not completed',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: điều hướng sang màn materials
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Color(0xFF4CD080),
                      fontWeight: FontWeight.w600,
                    ),
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
