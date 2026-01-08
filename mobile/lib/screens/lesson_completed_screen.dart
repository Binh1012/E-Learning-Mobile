import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class LessonCompletedScreen extends StatelessWidget {
  final String topicTitle;
  final int cardsLearned;
  final int accuracy;

  const LessonCompletedScreen({
    Key? key,
    required this.topicTitle,
    required this.cardsLearned,
    required this.accuracy,
  }) : super(key: key);

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Lesson Complete!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3DD598),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Congratulations text
                    const Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'You\'ve completed the $topicTitle lesson',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 24),

                    // Stats card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Cards & Accuracy
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$cardsLearned',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3DD598),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cards Learned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$accuracy%',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accuracy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[300], height: 1),
                          const SizedBox(height: 12),
                          // Next Lesson info
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Next Lesson',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Advanced Greetings',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '5 new cards to learn',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3DD598),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Space for buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16, 
          12, 
          16, 
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewLessonScreen(
                          topicTitle: topicTitle,
                          totalCards: cardsLearned,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Review Lesson',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue Learning',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Review Lesson Screen
class ReviewLessonScreen extends StatefulWidget {
  final String topicTitle;
  final int totalCards;

  const ReviewLessonScreen({
    Key? key,
    required this.topicTitle,
    required this.totalCards,
  }) : super(key: key);

  @override
  State<ReviewLessonScreen> createState() => _ReviewLessonScreenState();
}

class _ReviewLessonScreenState extends State<ReviewLessonScreen> {
  int _currentIndex = 0;
  bool _showBack = false;
  final Set<int> _learnedCards = {};

  final List<Map<String, String>> _flashcards = [
    {
      'word': 'Hello',
      'pronunciation': '/həˈloʊ/',
      'meaning': 'Xin chào',
      'exampleEn': 'Hello, how are you today?',
      'exampleVi': 'Xin chào, hôm nay bạn thế nào?',
    },
    {
      'word': 'Please',
      'pronunciation': '/pliːz/',
      'meaning': 'Làm ơn',
      'exampleEn': 'Please pass me the salt.',
      'exampleVi': 'Làm ơn đưa tôi muối.',
    },
    {
      'word': 'Thank you',
      'pronunciation': '/θæŋk juː/',
      'meaning': 'Cảm ơn',
      'exampleEn': 'Thank you for your help.',
      'exampleVi': 'Cảm ơn vì sự giúp đỡ của bạn.',
    },
    {
      'word': 'Goodbye',
      'pronunciation': '/ˌɡʊdˈbaɪ/',
      'meaning': 'Tạm biệt',
      'exampleEn': 'Goodbye, see you tomorrow!',
      'exampleVi': 'Tạm biệt, hẹn gặp lại ngày mai!',
    },
    {
      'word': 'Welcome',
      'pronunciation': '/ˈwelkəm/',
      'meaning': 'Chào mừng',
      'exampleEn': 'Welcome to our home!',
      'exampleVi': 'Chào mừng đến nhà chúng tôi!',
    },
  ];

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
      }
    });
  }

  bool get _allLearned => _learnedCards.length == _flashcards.length;

  double get _progressValue => _learnedCards.length / _flashcards.length;

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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Review Lesson',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                        'Review Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_allLearned)
                        const Text(
                          'All learned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3DD598),
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
                  Text(
                    'Card ${_currentIndex + 1} of ${_flashcards.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showBack) ...[
                            Flexible(
                              child: Text(
                                currentCard['word']!,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentCard['pronunciation']!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3DD598),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Tap to flip card',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ] else ...[
                            Flexible(
                              child: Text(
                                currentCard['meaning']!,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                            const SizedBox(height: 30),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentCard['exampleEn']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentCard['exampleVi']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

            const SizedBox(height: 20),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: _currentIndex > 0 ? Colors.black : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: _toggleLearned,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isLearned ? const Color(0xFF3DD598) : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF3DD598),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLearned ? 'Learned' : 'Mark as Learned',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isLearned ? Colors.white : const Color(0xFF3DD598),
                                ),
                              ),
                              if (isLearned) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check, color: Colors.white, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _currentIndex < _flashcards.length - 1
                          ? _nextCard
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: _currentIndex < _flashcards.length - 1
                            ? Colors.black
                            : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_flashcards.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
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

            // Finish Review button
            if (_allLearned)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 
                  0, 
                  20, 
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3DD598),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Finish Review',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.check, size: 18),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}