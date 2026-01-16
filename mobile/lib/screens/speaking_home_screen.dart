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
    final double progress = sound['progress'];
    final Color color = progressColor(progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Progress',
                      style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Number word: ${sound['words'].length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Color progressColor(double progress) {
  if (progress >= 0.7) {
    return Colors.green;
  } else if (progress >= 0.3) {
    return Colors.orange;
  } else {
    return Colors.red;
  }
}
