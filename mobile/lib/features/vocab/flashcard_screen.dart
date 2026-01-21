import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lesson_completed_screen.dart';
import '../../core/services/vocabulary_api_service.dart';

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

  late List<int> _cardMemoryLevels;

  List<Map<String, String>> _flashcards = [];
  List<String> _wordKeys = []; // Lưu wordKey của từng từ để gửi lên server
  bool _isLoadingFlashcards = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

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

    _loadVocabularyWords();
  }

  Future<void> _loadVocabularyWords() async {
    setState(() {
      _isLoadingFlashcards = true;
      _loadError = null;
    });

    try {
      // Gọi API /api/vocabs/new-words với topic
      final data = await VocabularyApiService.getNewWords(
        topicName: widget.topicTitle,
        limit: 10,
      );

      print('API Response: $data');

      // Parse response structure: {statusCode: 200, message: "Success", data: [...]}
      if (data['statusCode'] == 200 && data['data'] != null) {
        final words = data['data'] as List;

        final flashcards = <Map<String, String>>[];
        final wordKeys = <String>[];

        for (var word in words) {
          // Lấy wordKey
          final wordKey = word['wordKey']?.toString() ?? '';
          wordKeys.add(wordKey);

          // Lấy entry đầu tiên (vì entries là array)
          final entries = word['entries'] as List?;
          final entry = entries != null && entries.isNotEmpty 
              ? entries[0] as Map<String, dynamic>
              : <String, dynamic>{};

          // Map dữ liệu theo cấu trúc mới
          flashcards.add({
            'word': word['word']?.toString() ?? '',
            'pronunciation': entry['phonetic']?.toString() ?? '',
            'meaning': entry['word_vi']?.toString() ?? '',
            'example': entry['example']?.toString() ?? '',
            'audio': entry['audio']?.toString() ?? '',
          });
        }

        setState(() {
          _flashcards = flashcards;
          _wordKeys = wordKeys;
          _cardMemoryLevels = List<int>.filled(_flashcards.length, 0);
          _isLoadingFlashcards = false;
        });
      } else {
        setState(() {
          _loadError = 'Không thể tải từ vựng: ${data['message'] ?? 'Unknown error'}';
          _isLoadingFlashcards = false;
        });
      }
    } catch (e) {
      print('Error loading vocabulary: $e');
      setState(() {
        _loadError = 'Lỗi: $e';
        _isLoadingFlashcards = false;
      });
    }
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
      final audioUrl = currentCard['audio'];

      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _audioPlayer.stop();
        // Check if it's a URL or local asset
        if (audioUrl.startsWith('http')) {
          await _audioPlayer.play(UrlSource(audioUrl));
        } else {
          await _audioPlayer.play(AssetSource(audioUrl));
        }
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

  void _setMemoryLevel(int quality) {
    setState(() {
      _cardMemoryLevels[_currentIndex] = quality;
    });

    // Gửi kết quả học lên server với quality (1-4)
    _submitAnswer(quality);

    if (_cardMemoryLevels.every((level) => level > 0)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showCompletedScreen();
      });
    }
  }

  Future<void> _submitAnswer(int quality) async {
    try {
      final wordKey = _wordKeys[_currentIndex];
      
      print('📤 Submitting answer - wordKey: $wordKey, quality: $quality');
      
      final result = await VocabularyApiService.submitAnswer(
        wordKey: wordKey,
        quality: quality,
      );
      
      print('✅ Answer submitted successfully');
      print('📊 Next review: ${result['data']?['nextReview']}');
      print('📈 Interval: ${result['data']?['interval']} days');
    } catch (e) {
      print('❌ Error submitting answer: $e');
      // Không hiển thị lỗi cho user, chỉ log ra console
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
          flashcards: _flashcards,
          cardMemoryLevels: _cardMemoryLevels,
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
    // Show loading state
    if (_isLoadingFlashcards) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF3DD598)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Đang tải từ vựng...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadVocabularyWords,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3DD598),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (_flashcards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không có từ vựng nào',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                                  const EdgeInsets.all(20),
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
                                            height: 8),
                                        Text(
                                          currentCard[
                                              'pronunciation']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors
                                                .grey[600],
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 24),
                                        GestureDetector(
                                          onTap: _playAudio,
                                          child: Container(
                                            width: 60,
                                            height: 60,
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
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 16),
                                        const Text(
                                          'Tap to flip card',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const BoxDecoration(
                                                color: Color(
                                                    0xFF3DD598),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  BoxDecoration(
                                                color: Colors.grey
                                                    .withOpacity(
                                                        0.3),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                            ),
                                          ],
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
                                            height: 16),
                                        Text(
                                          currentCard[
                                              'example']!,
                                          textAlign:
                                              TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 16),
                                        const Text(
                                          'Tap to flip back',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  BoxDecoration(
                                                color: Colors.grey
                                                    .withOpacity(
                                                        0.3),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const BoxDecoration(
                                                color: Color(
                                                    0xFF3DD598),
                                                shape:
                                                    BoxShape.circle,
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
                        level: 1, // quality = 1
                        isSelected: currentMemoryLevel == 1,
                        borderColor: Colors.red,
                        backgroundColor: Colors.white,
                        textColor: Colors.red,
                      ),
                      _buildRatingButton(
                        label: 'Hơi nhớ',
                        sublabel: 'Cần ôn tập',
                        emoji: '🙂',
                        level: 2, // quality = 2
                        isSelected: currentMemoryLevel == 2,
                        borderColor: Colors.orange,
                        backgroundColor: Colors.white,
                        textColor: Colors.orange,
                      ),
                      _buildRatingButton(
                        label: 'Nhớ khá',
                        sublabel: 'Đã nắm vững',
                        emoji: '😊',
                        level: 3, // quality = 3
                        isSelected: currentMemoryLevel == 3,
                        borderColor: Colors.lightGreen,
                        backgroundColor: Colors.white,
                        textColor: Colors.lightGreen,
                      ),
                      _buildRatingButton(
                        label: 'Nhớ rất tốt',
                        sublabel: 'Thước lường',
                        emoji: '😄',
                        level: 4, // quality = 4
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