import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/services/speaking_api_service.dart';
import '../../core/services/speaking_progress_service.dart';

class SpeakingCard {
  final String text;
  final String ipa;
  final String audio;
  bool learned;

  SpeakingCard({
    required this.text,
    required this.ipa,
    required this.audio,
    this.learned = false,
  });
}

class SpeakingDetailScreen extends StatefulWidget {
  final int activityId;
  final String title;

  const SpeakingDetailScreen({
    super.key,
    required this.activityId,
    required this.title,
  });

  @override
  State<SpeakingDetailScreen> createState() =>
      _SpeakingDetailScreenState();
}

class _SpeakingDetailScreenState
    extends State<SpeakingDetailScreen> {
  final _player = AudioPlayer();
  final _page = PageController();

  List<SpeakingCard> cards = [];
  int index = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final learned =
    await SpeakingProgressService.getLearned(
        widget.activityId);

    final data = await SpeakingApiService.getMaterials(
        widget.activityId);

    final List<SpeakingCard> result = [];

    for (final s in data['symbols']) {
      result.add(SpeakingCard(
        text: s['symbol'],
        ipa: s['example_word_transcription'] ?? '',
        audio: s['symbol_sound_url'],
        learned: learned.contains(s['symbol']),
      ));

      for (final w in s['words']) {
        result.add(SpeakingCard(
          text: w['word'],
          ipa: w['word_transcription'],
          audio: w['word_sound_url'],
          learned: learned.contains(w['word']),
        ));
      }
    }

    await SpeakingProgressService.saveTotal(
        widget.activityId, result.length);

    setState(() {
      cards = result;
      loading = false;
    });
  }

  Future<void> _play(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  void _markLearned() async {
    final card = cards[index];
    await SpeakingProgressService.markLearned(
        widget.activityId, card.text);

    setState(() {
      card.learned = true;
      cards.sort((a, b) =>
      a.learned == b.learned
          ? 0
          : a.learned
          ? 1
          : -1);
      index = 0;
      _page.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final learned =
        cards.where((e) => e.learned).length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: learned / cards.length,
                  color: const Color(0xFF4CD080),
                ),
                const SizedBox(height: 6),
                Text('$learned / ${cards.length} learned'),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: cards.length,
              onPageChanged: (i) =>
                  setState(() => index = i),
              itemBuilder: (_, i) {
                final c = cards[i];
                return Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.text,
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight:
                                  FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(c.ipa),
                          const SizedBox(height: 24),
                          IconButton(
                            icon: const Icon(
                                Icons.play_circle,
                                size: 64),
                            onPressed: () =>
                                _play(c.audio),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: c.learned
                                ? null
                                : _markLearned,
                            child: Text(c.learned
                                ? 'Đã học'
                                : 'Đánh dấu đã học'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
