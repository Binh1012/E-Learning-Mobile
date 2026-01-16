import 'package:flutter/material.dart';

class SpeakingCardScreen extends StatefulWidget {
  final String soundName;
  final List<Map<String, String>> words;
  final int startIndex;

  const SpeakingCardScreen({
    super.key,
    required this.soundName,
    required this.words,
    required this.startIndex,
  });

  @override
  State<SpeakingCardScreen> createState() => _SpeakingCardScreenState();
}

class _SpeakingCardScreenState extends State<SpeakingCardScreen> {
  late PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex;
    _controller = PageController(initialPage: widget.startIndex);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.words.length;
    final progress = (currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(widget.soundName),
        actions: const [
          Icon(Icons.refresh),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          /// 🔹 Progress header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Progress',
                        style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Text('${(progress * 100).toInt()}%'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Card ${currentIndex + 1} of $total',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    const Text('1 learned',
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// 🔹 Card slider
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemBuilder: (_, i) {
                return Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Word
                          Text(
                            widget.words[i]['word']!,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          /// IPA
                          Text(
                            widget.words[i]['ipa']!,
                            style: const TextStyle(
                              fontSize: 20,
                              letterSpacing: 4,
                            ),
                          ),

                          const SizedBox(height: 28),

                          /// Action buttons
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              _icon(Icons.volume_up),
                              _icon(Icons.mic),
                              _icon(Icons.more_horiz),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                _nav(Icons.arrow_back_ios_new),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Mark as Learned'),
                  ),
                ),
                const SizedBox(width: 12),
                _nav(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 UI helpers
  Widget _icon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Icon(icon),
    );
  }

  Widget _nav(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18),
    );
  }
}
