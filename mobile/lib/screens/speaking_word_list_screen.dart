import 'package:flutter/material.dart';
import 'speaking_card_screen.dart';

class SpeakingWordListScreen extends StatelessWidget {
  final String soundName;
  final List words;

  const SpeakingWordListScreen({
    super.key,
    required this.soundName,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(soundName)),
      body: ListView.builder(
        itemCount: words.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(words[i]['word']),
          subtitle: Text(words[i]['ipa']),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpeakingCardScreen(
                  soundName: soundName,
                  words: List<Map<String, String>>.from(words),
                  startIndex: i,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
