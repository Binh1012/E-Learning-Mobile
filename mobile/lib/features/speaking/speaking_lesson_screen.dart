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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking')),
      body: FutureBuilder<List<dynamic>>(
        future: _topicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final topics = snapshot.data!;

          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];

              return ListTile(
                title: Text(topic['title']),
                trailing: const Icon(Icons.arrow_forward_ios),
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
              );
            },
          );
        },
      ),
    );
  }
}
