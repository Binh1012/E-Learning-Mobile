import 'package:flutter/material.dart';
import '../../core/services/speaking_api_service.dart';
import 'speaking_detail_screen.dart';

class SpeakingLessonScreen extends StatefulWidget {
  const SpeakingLessonScreen({Key? key}) : super(key: key);

  @override
  State<SpeakingLessonScreen> createState() => _SpeakingLessonScreenState();
}

class _SpeakingLessonScreenState extends State<SpeakingLessonScreen> {
  late Future<List<dynamic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = SpeakingApiService.getLearningTopics();
  }

  Future<void> _reload() async {
    setState(() {
      _topicsFuture = SpeakingApiService.getLearningTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Speaking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _topicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD080)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải Speaking',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          final topics = snapshot.data ?? [];

          if (topics.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài Speaking',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF4CD080),
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                final bool completed = topic['is_completed'] == true;

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpeakingDetailScreen(
                            activityId: topic['id'],
                            title: topic['title'],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Title + status
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
                                  color:
                                  completed ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// Progress (fake theo completed)
                          LinearProgressIndicator(
                            value: completed ? 1.0 : 0.0,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF4CD080),
                          ),

                          const SizedBox(height: 12),

                          /// Continue
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              completed ? 'Completed' : 'Continue',
                              style: TextStyle(
                                color: const Color(0xFF4CD080),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
