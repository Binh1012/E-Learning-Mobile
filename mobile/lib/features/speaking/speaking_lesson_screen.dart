import 'package:flutter/material.dart';
import '../../core/services/speaking_api_service.dart';
import 'speaking_detail_screen.dart';

class SpeakingLessonScreen extends StatefulWidget {
  const SpeakingLessonScreen({super.key});

  @override
  State<SpeakingLessonScreen> createState() => _SpeakingLessonScreenState();
}

class _SpeakingLessonScreenState extends State<SpeakingLessonScreen> {
  bool loading = true;
  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SpeakingApiService.getTopics();
      setState(() {
        topics = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ Load topics error: $e');
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking Topics'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        itemCount: topics.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = topics[index];
          return ListTile(
            title: Text(item['title']),
            subtitle: Text(
              item['is_completed'] ? 'Đã hoàn thành' : 'Chưa hoàn thành',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpeakingDetailScreen(
                    activityId: item['id'],
                    title: item['title'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
