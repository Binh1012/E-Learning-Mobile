import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _materialFuture =
        SpeakingApiService.getLearningMaterials(widget.activityId);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _materialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD080)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải nội dung Speaking',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          final List symbols = snapshot.data?['symbols'] ?? [];

          if (symbols.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có dữ liệu phát âm',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: symbols.length,
            itemBuilder: (context, index) {
              final symbol = symbols[index];
              final List words = symbol['words'] ?? [];

              return Card(
                elevation: 2,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  maintainState: true,
                  tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    symbol['symbol'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    symbol['note'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up),
                    color: const Color(0xFF4CD080),
                    onPressed: () =>
                        _playAudio(symbol['symbol_sound_url']),
                  ),
                  children: words.map<Widget>((word) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          word['word'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${word['word_transcription']} • ${word['word_mean']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up),
                          color: const Color(0xFF4CD080),
                          onPressed: () =>
                              _playAudio(word['word_sound_url']),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
