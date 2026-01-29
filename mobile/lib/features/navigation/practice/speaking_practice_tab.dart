import 'package:flutter/material.dart';
import '../../../core/services/speaking_api_service.dart';
import '../../speaking_practice/speaking_practice_screen.dart';
import '../../listening_practice/listening_practice_screen.dart';
class SpeakingPracticeTab extends StatefulWidget {
  const SpeakingPracticeTab({Key? key}) : super(key: key);

  @override
  State<SpeakingPracticeTab> createState() => _SpeakingPracticeTabState();
}

class _SpeakingPracticeTabState extends State<SpeakingPracticeTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _activities = await SpeakingApiService.getTopics();
      _loading = false;
      setState(() {});
    } catch (e) {
      _error = e.toString();
      _loading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3DD598)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActivities,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Speaking Practice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              return _buildSpeakingCard(_activities[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingCard(dynamic activity) {
    final title = activity['title'] ?? 'Speaking Lesson';
    final activityId = activity['id'];

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pronounce the words correctly and submit your recording.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          /// Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Practice Now'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpeakingPracticeScreen(
                      activityId: activityId,
                      title: title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DD598),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
