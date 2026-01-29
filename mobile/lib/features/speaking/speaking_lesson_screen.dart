import 'package:flutter/material.dart';
import '../../core/services/speaking_api_service.dart';
import '../../core/services/speaking_progress_service.dart';
import 'speaking_detail_screen.dart';

class SpeakingLessonScreen extends StatefulWidget {
  const SpeakingLessonScreen({super.key});

  @override
  State<SpeakingLessonScreen> createState() =>
      _SpeakingLessonScreenState();
}

class _SpeakingLessonScreenState
    extends State<SpeakingLessonScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = SpeakingApiService.getTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final topics = snap.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (_, i) {
              final t = topics[i];

              return FutureBuilder(
                future: Future.wait([
                  SpeakingProgressService.getLearned(
                      t['id']),
                  SpeakingProgressService.getTotal(
                      t['id']),
                ]),
                builder: (_, s) {
                  if (!s.hasData) {
                    return const SizedBox();
                  }

                  final learned =
                      (s.data![0] as Set).length;
                  final total = s.data![1] as int;

                  final percent = total == 0
                      ? 0.0
                      : learned / total;

                  final completed =
                      total > 0 && learned >= total;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(t['title']),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(completed
                              ? 'Completed'
                              : '$learned / $total cards'),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: percent,
                            color:
                            const Color(0xFF4CD080),
                          ),
                        ],
                      ),
                      trailing: completed
                          ? const Icon(
                        Icons.check_circle,
                        color:
                        Color(0xFF4CD080),
                      )
                          : const Text(
                        'Continue',
                        style: TextStyle(
                            color:
                            Color(0xFF4CD080)),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SpeakingDetailScreen(
                                  activityId: t['id'],
                                  title: t['title'],
                                ),
                          ),
                        );
                        setState(() {});
                      },
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
