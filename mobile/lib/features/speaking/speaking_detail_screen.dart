import 'package:flutter/material.dart';
import '../../core/services/speaking_api_service.dart';

class SpeakingDetailScreen extends StatefulWidget {
  final int activityId;
  final String title;

  const SpeakingDetailScreen({
    Key? key,
    required this.activityId,
    required this.title,
  }) : super(key: key);

  @override
  State<SpeakingDetailScreen> createState() => _SpeakingDetailScreenState();
}

class _SpeakingDetailScreenState extends State<SpeakingDetailScreen> {
  late Future<Map<String, dynamic>> _materialFuture;

  @override
  void initState() {
    super.initState();
    _materialFuture =
        SpeakingApiService.getLearningMaterials(widget.activityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _materialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final symbols = snapshot.data!['symbols'];

          return ListView.builder(
            itemCount: symbols.length,
            itemBuilder: (context, index) {
              final symbol = symbols[index];

              return ExpansionTile(
                title: Text(
                  symbol['symbol'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(symbol['note']),
                children: symbol['words'].map<Widget>((word) {
                  return ListTile(
                    title: Text(word['word']),
                    subtitle: Text(
                      '${word['word_transcription']} - ${word['word_mean']}',
                    ),
                    trailing: const Icon(Icons.volume_up),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
