import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/services/speaking_api_service.dart';

class SpeakingCard {
  final String text;
  final String ipa;
  final String audioUrl;
  bool learned;

  SpeakingCard({
    required this.text,
    required this.ipa,
    required this.audioUrl,
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
  State<SpeakingDetailScreen> createState() => _SpeakingDetailScreenState();
}

class _SpeakingDetailScreenState extends State<SpeakingDetailScreen> {
  final _player = AudioPlayer();
  final _pageController = PageController();

  List<SpeakingCard> cards = [];
  int currentIndex = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
      await SpeakingApiService.getMaterials(widget.activityId);

      final List<SpeakingCard> result = [];

      for (final symbol in data['symbols']) {
        // card symbol
        result.add(
          SpeakingCard(
            text: symbol['symbol'],
            ipa: symbol['example_word_transcription'] ?? '',
            audioUrl: symbol['symbol_sound_url'],
          ),
        );

        // card words
        for (final word in symbol['words']) {
          result.add(
            SpeakingCard(
              text: word['word'],
              ipa: word['word_transcription'],
              audioUrl: word['word_sound_url'],
            ),
          );
        }
      }

      setState(() {
        cards = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ Load speaking detail error: $e');
      loading = false;
    }
  }

  Future<void> _play(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  void _markLearned() {
    setState(() {
      cards[currentIndex].learned = true;

      // đẩy card đã học xuống cuối
      cards.sort((a, b) {
        if (a.learned == b.learned) return 0;
        return a.learned ? 1 : -1;
      });

      currentIndex = 0;
      _pageController.jumpToPage(0);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Card ${currentIndex + 1}/${cards.length}'),
                Text(
                  '${cards.where((e) => e.learned).length} learned',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (i) {
                setState(() => currentIndex = i);
              },
              itemBuilder: (context, index) {
                final card = cards[index];
                return Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.text,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            card.ipa,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          IconButton(
                            icon: const Icon(Icons.play_circle, size: 64),
                            onPressed: () => _play(card.audioUrl),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                            card.learned ? null : _markLearned,
                            child: Text(
                              card.learned
                                  ? 'Đã học'
                                  : 'Đánh dấu đã học',
                            ),
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
