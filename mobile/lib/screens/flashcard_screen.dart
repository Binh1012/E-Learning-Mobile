import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'lesson_completed_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final String topicTitle;
  final String topicLevel;
  final int totalLessons;
  final double progress;

  const FlashcardScreen({
    Key? key,
    required this.topicTitle,
    required this.topicLevel,
    required this.totalLessons,
    required this.progress,
  }) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showBack = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  late List<int> _cardMemoryLevels;

  final List<Map<String, String>> _flashcards = [
    {
      'word': 'Hello',
      'pronunciation': '/həˈloʊ/',
      'meaning': 'Xin chào',
      'exampleEn': 'Hello, how are you today?',
      'exampleVi': 'Xin chào, hôm nay bạn thế nào?',
      'audio': 'audios/hello.mp3',
    },
    {
      'word': 'Goodbye',
      'pronunciation': '/ˌɡʊdˈbaɪ/',
      'meaning': 'Tạm biệt',
      'exampleEn': 'Goodbye, see you tomorrow!',
      'exampleVi': 'Tạm biệt, hẹn gặp lại ngày mai!',
      'audio': 'audios/goodbye.mp3',
    },
    {
      'word': 'Thank you',
      'pronunciation': '/θæŋk juː/',
      'meaning': 'Cảm ơn',
      'exampleEn': 'Thank you for your help.',
      'exampleVi': 'Cảm ơn vì sự giúp đỡ của bạn.',
      'audio': 'audios/thank_you.mp3',
    },
    {
      'word': 'Please',
      'pronunciation': '/pliːz/',
      'meaning': 'Làm ơn',
      'exampleEn': 'Please pass me the salt.',
      'exampleVi': 'Làm ơn đưa tôi muối.',
      'audio': 'audios/please.mp3',
    },
    {
      'word': 'Welcome',
      'pronunciation': '/ˈwelkəm/',
      'meaning': 'Chào mừng',
      'exampleEn': 'Welcome to our home!',
      'exampleVi': 'Chào mừng đến nhà chúng tôi!',
      'audio': 'audios/welcome.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();

    _cardMemoryLevels = List<int>.filled(_flashcards.length, 0);

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      final currentCard = _flashcards[_currentIndex];
      final audioPath = currentCard['audio'];

      if (audioPath != null && audioPath.isNotEmpty) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(audioPath));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
      _flipController.reset();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showBack = false;
      });
      _flipController.reset();
    }
  }

  void _toggleCard() {
    if (_showBack) {
      _flipController.reverse().then((_) {
        setState(() {
          _showBack = false;
        });
      });
    } else {
      _flipController.forward().then((_) {
        setState(() {
          _showBack = true;
        });
      });
    }
  }

  void _setMemoryLevel(int level) {
    setState(() {
      _cardMemoryLevels[_currentIndex] = level;
    });

    if (_cardMemoryLevels.every((level) => level > 0)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showCompletedScreen();
      });
    }
  }

  void _showCompletedScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonCompletedScreen(
          topicTitle: widget.topicTitle,
          cardsLearned: _flashcards.length,
          accuracy: 100,
        ),
      ),
    );
  }

  double get _progressValue {
    int ratedCards =
        _cardMemoryLevels.where((level) => level > 0).length;
    return ratedCards / _flashcards.length;
  }

  Widget _buildRatingButton({
    required String label,
    required String sublabel,
    required String emoji,
    required int level,
    required bool isSelected,
    required Color borderColor,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () => _setMemoryLevel(level),
      child: Container(
        width: (MediaQuery.of(context).size.width - 50) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? borderColor.withOpacity(0.1)
              : backgroundColor,
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? borderColor : textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _flashcards[_currentIndex];
    final currentMemoryLevel = _cardMemoryLevels[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.topicTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// PROGRESS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${(_progressValue * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF3DD598),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card ${_currentIndex + 1} of ${_flashcards.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_cardMemoryLevels.where((level) => level > 0).length} learned',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3DD598),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// FLASHCARD
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _toggleCard,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      _previousCard();
                    } else if (details.primaryVelocity! < 0) {
                      _nextCard();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle =
                          _flipAnimation.value * math.pi;
                      final isShowingFront =
                          angle < (math.pi / 2);

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Transform(
                            transform: Matrix4.identity()
                              ..rotateY(
                                  isShowingFront ? 0 : math.pi),
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: isShowingFront
                                    ? [
                                        Text(
                                          currentCard['word']!,
                                          style:
                                              const TextStyle(
                                            fontSize: 48,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                        const SizedBox(
                                            height: 12),
                                        Text(
                                          currentCard[
                                              'pronunciation']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors
                                                .grey[600],
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 40),
                                        GestureDetector(
                                          onTap: _playAudio,
                                          child: Container(
                                            width: 64,
                                            height: 64,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Color(0xFF3DD598),
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color:
                                                  Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : [
                                        Text(
                                          currentCard['meaning']!,
                                          style:
                                              const TextStyle(
                                            fontSize: 48,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                        const SizedBox(
                                            height: 24),
                                        Text(
                                          currentCard[
                                              'exampleEn']!,
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                        const SizedBox(
                                            height: 8),
                                        Text(
                                          currentCard[
                                              'exampleVi']!,
                                          textAlign:
                                              TextAlign.center,
                                          style: TextStyle(
                                            color: Colors
                                                .grey[600],
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            /// RATING
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá mức độ ghi nhớ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildRatingButton(
                        label: 'Không nhớ',
                        sublabel: 'Cần học lại',
                        emoji: '😔',
                        level: 1,
                        isSelected: currentMemoryLevel == 1,
                        borderColor: Colors.red,
                        backgroundColor: Colors.white,
                        textColor: Colors.red,
                      ),
                      _buildRatingButton(
                        label: 'Hơi nhớ',
                        sublabel: 'Cần ôn tập',
                        emoji: '🙂',
                        level: 2,
                        isSelected: currentMemoryLevel == 2,
                        borderColor: Colors.orange,
                        backgroundColor: Colors.white,
                        textColor: Colors.orange,
                      ),
                      _buildRatingButton(
                        label: 'Nhớ khá',
                        sublabel: 'Đã nắm vững',
                        emoji: '😊',
                        level: 3,
                        isSelected: currentMemoryLevel == 3,
                        borderColor: Colors.lightGreen,
                        backgroundColor: Colors.white,
                        textColor: Colors.lightGreen,
                      ),
                      _buildRatingButton(
                        label: 'Nhớ rất tốt',
                        sublabel: 'Thước lường',
                        emoji: '😍',
                        level: 4,
                        isSelected: currentMemoryLevel == 4,
                        borderColor:
                             Colors.blue,
                        backgroundColor: Colors.white,
                        textColor:
                            Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
