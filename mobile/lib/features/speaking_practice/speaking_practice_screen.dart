import 'package:flutter/material.dart';
import '../../../core/services/speaking_practice_api_service.dart';

class SpeakingPracticeScreen extends StatefulWidget {
  final int activityId;
  final String title;

  const SpeakingPracticeScreen({
    Key? key,
    required this.activityId,
    required this.title,
  }) : super(key: key);

  @override
  State<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final result =
    await SpeakingPracticeApiService.getTestMaterials(widget.activityId);
    _data = result;
    _loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: _buildSymbols(),
      ),
    );
  }

  List<Widget> _buildSymbols() {
    final symbols = _data!['symbols'] as List;

    return symbols.map((symbol) {
      final words = symbol['words'] as List;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ...words.map((word) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                title: Text(word['word']),
                subtitle: Text(
                  '${word['word_transcription']} • ${word['word_mean']}',
                ),
                trailing: const Icon(Icons.volume_up),
                onTap: () {
                  // TODO: play audio
                },
              ),
            );
          }).toList()
        ],
      );
    }).toList();
  }
}
