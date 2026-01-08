import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showBack = false;
  final FlutterTts _flutterTts = FlutterTts();
  
  // Track learned cards
  final Set<int> _learnedCards = {};

  // Sample flashcard data
  final List<Map<String, String>> _flashcards = [
    {
      'word': 'Hello',
      'pronunciation': '/həˈloʊ/',
      'meaning': 'Xin chào',
      'exampleEn': 'Hello, how are you today?',
      'exampleVi': 'Xin chào, hôm nay bạn thế nào?',
    },
    {
      'word': 'Goodbye',
      'pronunciation': '/ˌɡʊdˈbaɪ/',
      'meaning': 'Tạm biệt',
      'exampleEn': 'Goodbye, see you tomorrow!',
      'exampleVi': 'Tạm biệt, hẹn gặp lại ngày mai!',
    },
    {
      'word': 'Thank you',
      'pronunciation': '/θæŋk juː/',
      'meaning': 'Cảm ơn',
      'exampleEn': 'Thank you for your help.',
      'exampleVi': 'Cảm ơn vì sự giúp đỡ của bạn.',
    },
    {
      'word': 'Please',
      'pronunciation': '/pliːz/',
      'meaning': 'Làm ơn',
      'exampleEn': 'Please pass me the salt.',
      'exampleVi': 'Làm ơn đưa tôi muối.',
    },
    {
      'word': 'Welcome',
      'pronunciation': '/ˈwelkəm/',
      'meaning': 'Chào mừng',
      'exampleEn': 'Welcome to our home!',
      'exampleVi': 'Chào mừng đến nhà chúng tôi!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showBack = false;
      });
    }
  }

  void _toggleCard() {
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _toggleLearned() {
    setState(() {
      if (_learnedCards.contains(_currentIndex)) {
        _learnedCards.remove(_currentIndex);
      } else {
        _learnedCards.add(_currentIndex);
        // Check if all cards are learned
        if (_learnedCards.length == _flashcards.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showCompletedScreen();
          });
        }
      }
    });
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
    return _learnedCards.length / _flashcards.length;
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _flashcards[_currentIndex];
    final isLearned = _learnedCards.contains(_currentIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.topicTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(_progressValue * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3DD598)),
                      minHeight: 8,
                    ),
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
                        '${_learnedCards.length} learned',
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

            // Flashcard
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: _toggleCard,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showBack) ...[
                            // Front of card - Word
                            Text(
                              currentCard['word']!,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentCard['pronunciation']!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // Play button
                            GestureDetector(
                              onTap: () => _speak(currentCard['word']!),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3DD598),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Tap to flip card',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            // Dot indicator
                            const SizedBox(height: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3DD598),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ] else ...[
                            // Back of card - Meaning
                            Text(
                              currentCard['meaning']!,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 50,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3DD598),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Example sentences
                            Column(
                              children: [
                                Text(
                                  currentCard['exampleEn']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentCard['exampleVi']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Tap to flip back',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            // Dot indicator
                            const SizedBox(height: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3DD598),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: _currentIndex > 0
                            ? Colors.black
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),

                  // Learned button
                  GestureDetector(
                    onTap: _toggleLearned,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isLearned ? const Color(0xFF3DD598) : Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3DD598),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLearned ? 'Learned' : 'Mark as Learned',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLearned ? Colors.white : const Color(0xFF3DD598),
                            ),
                          ),
                          if (isLearned) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Next button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _currentIndex < _flashcards.length - 1
                          ? _nextCard
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: _currentIndex < _flashcards.length - 1
                            ? Colors.black
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_flashcards.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? const Color(0xFF3DD598)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}