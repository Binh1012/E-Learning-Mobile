import 'package:flutter/material.dart';
import 'speaking_fake_data.dart';
import 'speaking_word_list_screen.dart';

class SpeakingHomeScreen extends StatefulWidget {
  const SpeakingHomeScreen({super.key});

  @override
  State<SpeakingHomeScreen> createState() => _SpeakingHomeScreenState();
}

class _SpeakingHomeScreenState extends State<SpeakingHomeScreen> {
  bool showConsonant = true;
  bool showVowel = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            title: 'Consonant Sound (24)',
            expanded: showConsonant,
            onToggle: () =>
                setState(() => showConsonant = !showConsonant),
            data: consonantSounds,
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Vowel Sound (20)',
            expanded: showVowel,
            onToggle: () => setState(() => showVowel = !showVowel),
            data: vowelSounds,
          ),
        ],
      ),
    );
  }

  /// 🔹 Section lớn
  Widget _buildSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List data,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Header
            InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ),
                ],
              ),
            ),

            if (expanded) ...[
              const SizedBox(height: 16),

              /// List sound cards
              ...data.map((sound) => _soundCard(sound)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// 🔹 Card chi tiết từng âm (GIỐNG HÌNH)
  Widget _soundCard(Map sound) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpeakingWordListScreen(
                soundName: sound['name'],
                words: sound['words'],
              ),
            ),
          );
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title + status dot
                Row(
                  children: [
                    Text(
                      sound['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Progress label
                Row(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      '${(sound['progress'] * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// Progress bar
                LinearProgressIndicator(
                  value: sound['progress'],
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 6,
                ),

                const SizedBox(height: 12),

                /// Footer
                Row(
                  children: [
                    Text(
                      'Number word: ${sound['words'].length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
