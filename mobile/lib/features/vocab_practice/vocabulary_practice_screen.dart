import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/services/vocabulary_practice_api_service.dart';

class VocabularyPracticeScreen extends StatefulWidget {
  final String vocabularyTitle;
  final int lessonId;

  const VocabularyPracticeScreen({
    Key? key,
    required this.vocabularyTitle,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<VocabularyPracticeScreen> createState() => _VocabularyPracticeScreenState();
}

class _VocabularyPracticeScreenState extends State<VocabularyPracticeScreen> {
  bool _isLoading = true;
  String? _loadError;
  
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _allQuestions = [];
  
  Map<int, dynamic> _correctAnswers = {};
  
  int _currentStep = 0;
  int _learnedSteps = 0;
  bool _isReviewMode = false;
  
  Map<int, String> _selectedAnswers = {};
  Map<int, String> _fillInAnswers = {};
  Map<int, bool> _checkedQuestions = {};
  Map<int, bool> _answerResults = {};
  
  Map<int, String?> _matchingSelectedEnglish = {};
  Map<int, Set<String>> _matchingCorrectPairs = {};
  Map<int, Set<String>> _matchingWrongPairs = {};
  Map<int, Map<String, String>> _matchingWrongDetails = {};
  
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final partsData = await VocabularyPracticeApiService.getLessonParts(
        lessonId: widget.lessonId,
      );

      print('📚 Vocabulary parts response: 200');

      final parts = partsData['data'] as List;
      _parts = parts.map((p) => p as Map<String, dynamic>).toList();

      final allQuestions = <Map<String, dynamic>>[];
      
      for (var part in _parts) {
        final partId = part['part_id'];
        
        try {
          final partDetailData = await VocabularyPracticeApiService.getPartDetails(
            partId: partId,
          );

          final partDetail = partDetailData['data'] as Map<String, dynamic>;
          final questions = partDetail['questions'] as List? ?? [];
          final correctAnswerPath = partDetail['correct_answer_path'];
          final partDescription = part['description'];

          if (correctAnswerPath != null && correctAnswerPath.toString().isNotEmpty) {
            await _loadCorrectAnswers(partId, correctAnswerPath, partDescription);
          }

          for (var question in questions) {
            final questionWithPart = Map<String, dynamic>.from(question);
            questionWithPart['part_id'] = partId;
            questionWithPart['part_description'] = partDescription;
            allQuestions.add(questionWithPart);
          }
        } catch (e) {
          print('Error loading part $partId: $e');
          continue;
        }
      }

      setState(() {
        _allQuestions = allQuestions;
        _isLoading = false;
      });

      print('✅ Loaded ${_parts.length} parts with ${_allQuestions.length} questions');
    } catch (e) {
      print('❌ Error loading lesson data: $e');
      setState(() {
        _loadError = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCorrectAnswers(int partId, String correctAnswerPath, String partDescription) async {
    try {
      final content = await VocabularyPracticeApiService.fetchCorrectAnswers(correctAnswerPath);
      
      if (partDescription == 'MULTIPLE_CHOICE') {
        final answers = VocabularyPracticeApiService.parseMultipleChoiceAnswers(content);
        _correctAnswers[partId] = answers;
        print('✅ Loaded ${answers.length} MULTIPLE_CHOICE answers for part $partId');
      } else if (partDescription == 'MATCHING') {
        final matchMap = VocabularyPracticeApiService.parseMatchingAnswers(content);
        _correctAnswers[partId] = matchMap;
        print('✅ Loaded ${matchMap.length} MATCHING pairs for part $partId');
      } else if (partDescription == 'FILL_IN_BLANK') {
        final answers = VocabularyPracticeApiService.parseFillInBlankAnswers(content);
        _correctAnswers[partId] = answers;
        print('✅ Loaded ${answers.length} FILL_IN_BLANK answers for part $partId');
      }
    } catch (e) {
      print('❌ Error loading correct answers for part $partId: $e');
    }
  }

  double get _progressValue {
    if (_isReviewMode) return 0.0;
    if (_allQuestions.isEmpty) return 0.0;
    return _currentStep / _allQuestions.length;
  }

  int get _accuracy {
    if (_answerResults.isEmpty) return 0;
    int correct = _answerResults.values.where((c) => c).length;
    return ((correct / _answerResults.length) * 100).round();
  }

  String get _stepText {
    if (_isReviewMode) return 'Step 1 of ${_allQuestions.length}';
    return 'Step ${_currentStep + 1} of ${_allQuestions.length}';
  }

  void _nextStep() {
    if (_currentStep < _allQuestions.length - 1) {
      final currentQuestion = _allQuestions[_currentStep];
      final questionId = currentQuestion['question_id'];
      final partDescription = currentQuestion['part_description'];
      
      if (partDescription == 'MULTIPLE_CHOICE' || partDescription == 'FILL_IN_BLANK') {
        if (_checkedQuestions[questionId] != true) {
          return;
        }
      } else if (partDescription == 'MATCHING') {
        final correctPairs = _matchingCorrectPairs[questionId] ?? {};
        final displayOrders = currentQuestion['displayOrders'] as List;
        final totalPairs = (displayOrders.length / 2).floor();
        
        if (correctPairs.length < totalPairs) {
          return;
        }
      }
      
      setState(() {
        _currentStep++;
        _learnedSteps = _currentStep;
      });
    } else if (_currentStep == _allQuestions.length - 1) {
      setState(() {
        _currentStep = _allQuestions.length;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0 && !_isReviewMode) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _checkAnswer(int questionId, String partDescription) {
    final question = _allQuestions.firstWhere((q) => q['question_id'] == questionId);
    final partId = question['part_id'];
    final correctAnswersData = _correctAnswers[partId];

    if (correctAnswersData == null) {
      setState(() {
        _checkedQuestions[questionId] = true;
        _answerResults[questionId] = true;
      });
      return;
    }

    bool isCorrect = false;
    String? correctAnswer;

    if (partDescription == 'MULTIPLE_CHOICE') {
      final selectedAnswer = _selectedAnswers[questionId];
      if (selectedAnswer == null) return;
      
      final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
      final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
      
      if (questionIndex >= 0 && questionIndex < correctAnswersData.length) {
        correctAnswer = correctAnswersData[questionIndex];
        isCorrect = selectedAnswer == correctAnswer;
      }
    } else if (partDescription == 'FILL_IN_BLANK') {
      final answer = _fillInAnswers[questionId]?.trim().toLowerCase();
      if (answer == null || answer.isEmpty) return;
      
      final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
      final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
      
      if (questionIndex >= 0 && questionIndex < correctAnswersData.length) {
        final correctAnswerStr = correctAnswersData[questionIndex];
        if (correctAnswerStr != null) {
          correctAnswer = correctAnswerStr;
          isCorrect = answer == correctAnswerStr.toLowerCase();
        }
      }
    }
    
    setState(() {
      _checkedQuestions[questionId] = true;
      _answerResults[questionId] = isCorrect;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF3DD598)),
                      const SizedBox(height: 16),
                      const Text('Loading vocabulary lesson...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadLessonData,
                        child: const Text('Retry'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgress(),
            Expanded(child: _buildContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _currentStep >= _allQuestions.length ? 'Lesson Complete!' : widget.vocabularyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isReviewMode ? 'Review Progress' : 'Progress', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
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
              Text(_stepText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                _isReviewMode ? 'All learned' : '$_learnedSteps learned',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3DD598)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentStep >= _allQuestions.length) {
      return _buildCompleteScreen();
    }

    final question = _allQuestions[_currentStep];
    final partDescription = question['part_description'];

    if (partDescription == 'MULTIPLE_CHOICE') {
      return _buildMultipleChoiceQuestion(question);
    } else if (partDescription == 'FILL_IN_BLANK') {
      return _buildFillInBlankQuestion(question);
    } else if (partDescription == 'MATCHING') {
      return _buildMatchingQuestion(question);
    } else {
      return _buildTheoryContent(question);
    }
  }

  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> question) {
    final questionId = question['question_id'] as int;
    final displayOrders = question['displayOrders'] as List;
    
    if (displayOrders.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    final questionText = _extractContent(displayOrders[0]['content_path']);
    final options = displayOrders.skip(1).toList();
    final selectedAnswer = _selectedAnswers[questionId];
    final isChecked = _checkedQuestions[questionId] == true;
    final isCorrect = _answerResults[questionId];
    
    String? correctAnswer;
    String? correctAnswerText;
    if (isChecked && isCorrect == false) {
      final partId = question['part_id'];
      final correctAnswersData = _correctAnswers[partId];
      if (correctAnswersData != null) {
        final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
        final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
        if (questionIndex >= 0 && questionIndex < correctAnswersData.length) {
          correctAnswer = correctAnswersData[questionIndex];
          final correctOptionIndex = correctAnswer!.codeUnitAt(0) - 65;
          if (correctOptionIndex >= 0 && correctOptionIndex < options.length) {
            correctAnswerText = _extractContent(options[correctOptionIndex]['content_path']);
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text('Bài tập trắc nghiệm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 24),
            Text(questionText, style: const TextStyle(fontSize: 18, color: Colors.black), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final label = String.fromCharCode(65 + index);
              final text = _extractContent(option['content_path']);
              
              bool? optionCorrect;
              if (isChecked) {
                if (label == correctAnswer) {
                  optionCorrect = true;
                } else if (label == selectedAnswer && isCorrect == false) {
                  optionCorrect = false;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMultipleChoiceOption(label, text, selectedAnswer, !isChecked, (value) {
                  if (!isChecked) setState(() => _selectedAnswers[questionId] = value);
                }, optionCorrect),
              );
            }).toList(),
            if (!isChecked && selectedAnswer != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(questionId, 'MULTIPLE_CHOICE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kiểm tra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (isChecked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(isCorrect == true ? Icons.check_circle : Icons.cancel, color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect == true ? 'Chính xác! Làm tốt lắm!' : 'Chưa chính xác!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350)),
                          ),
                          if (isCorrect == false && correctAnswerText != null) ...[
                            const SizedBox(height: 4),
                            Text('Đáp án đúng: $correctAnswer. $correctAnswerText', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            Text('Tap to continue', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildFillInBlankQuestion(Map<String, dynamic> question) {
    final questionId = question['question_id'] as int;
    final displayOrders = question['displayOrders'] as List;
    
    if (displayOrders.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    final questionText = _extractContent(displayOrders[0]['content_path']);
    final isChecked = _checkedQuestions[questionId] == true;
    final isCorrect = _answerResults[questionId];
    
    String? correctAnswer;
    if (isChecked && isCorrect == false) {
      final partId = question['part_id'];
      final correctAnswersData = _correctAnswers[partId];
      if (correctAnswersData != null) {
        final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
        final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
        if (questionIndex >= 0 && questionIndex < correctAnswersData.length) {
          correctAnswer = correctAnswersData[questionIndex];
        }
      }
    }
    
    if (!_textControllers.containsKey(questionId)) {
      _textControllers[questionId] = TextEditingController();
      _textControllers[questionId]!.addListener(() {
        setState(() => _fillInAnswers[questionId] = _textControllers[questionId]!.text);
      });
    }

    final controller = _textControllers[questionId]!;
    final hasAnswer = controller.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text('Bài tập điền từ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 24),
            const Text('Điền từ thích hợp:', style: TextStyle(fontSize: 16, color: Colors.black), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(questionText, style: const TextStyle(fontSize: 18, color: Colors.black), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              enabled: !isChecked,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (!isChecked && hasAnswer) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(questionId, 'FILL_IN_BLANK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kiểm tra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (isChecked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(isCorrect == true ? Icons.check_circle : Icons.cancel, color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect == true ? 'Chính xác! Làm tốt lắm!' : 'Chưa chính xác!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350)),
                          ),
                          if (isCorrect == false && correctAnswer != null) ...[
                            const SizedBox(height: 4),
                            Text('Đáp án đúng: $correctAnswer', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            Text('Tap to continue', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingQuestion(Map<String, dynamic> question) {
    final questionId = question['question_id'] as int;
    final displayOrders = question['displayOrders'] as List;
    
    if (displayOrders.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    final englishWords = <String, String>{};
    final vietnameseWords = <String, String>{};
    
    try {
      for (var i = 0; i < displayOrders.length; i++) {
        final contentPath = displayOrders[i]['content_path']?.toString() ?? '';
        
        String content;
        if (contentPath.startsWith('http')) {
          try {
            final uri = Uri.parse(contentPath);
            final segments = uri.pathSegments;
            if (segments.isNotEmpty) {
              content = segments.last;
              try {
                content = Uri.decodeComponent(content);
              } catch (e) {}
            } else {
              content = contentPath;
            }
          } catch (e) {
            content = contentPath.split('/').last;
          }
        } else {
          content = contentPath;
        }
        
        if (i % 2 == 0) {
          final label = String.fromCharCode(65 + (i ~/ 2));
          englishWords[label] = content;
        } else {
          final label = ((i ~/ 2) + 1).toString();
          vietnameseWords[label] = content;
        }
      }
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading question: $e'),
          ],
        ),
      );
    }

    if (!_matchingCorrectPairs.containsKey(questionId)) {
      _matchingCorrectPairs[questionId] = {};
    }
    if (!_matchingWrongPairs.containsKey(questionId)) {
      _matchingWrongPairs[questionId] = {};
    }
    if (!_matchingWrongDetails.containsKey(questionId)) {
      _matchingWrongDetails[questionId] = {};
    }

    final selectedEnglish = _matchingSelectedEnglish[questionId];
    final correctPairs = _matchingCorrectPairs[questionId]!;
    final wrongPairs = _matchingWrongPairs[questionId]!;
    final wrongDetails = _matchingWrongDetails[questionId]!;
    final totalPairs = englishWords.length;
    final foundPairs = correctPairs.length;
    
    final partId = question['part_id'];
    final correctAnswersData = _correctAnswers[partId] as Map<String, String>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text('Nối từ với nghĩa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 8),
            Text('Đã tìm được $foundPairs/$totalPairs cặp', style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: Text('TIẾNG ANH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('TIẾNG VIỆT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: englishWords.entries.map((entry) {
                      final label = entry.key;
                      final word = entry.value;
                      final isCorrect = correctPairs.contains(label);
                      final isWrong = wrongPairs.contains(label);
                      final isSelected = selectedEnglish == label;
                      
                      if (isCorrect) return const SizedBox(height: 56);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMatchingOptionNew(
                          label: label,
                          text: word,
                          isSelected: isSelected,
                          isCorrect: isCorrect,
                          isWrong: isWrong,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _matchingSelectedEnglish[questionId] = null;
                              } else {
                                _matchingSelectedEnglish[questionId] = label;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    children: vietnameseWords.entries.map((entry) {
                      final label = entry.key;
                      final word = entry.value;
                      
                      bool isCorrect = false;
                      
                      if (correctAnswersData != null) {
                        for (var engLabel in correctPairs) {
                          final engWord = englishWords[engLabel];
                          if (engWord != null) {
                            final correctVietnamese = correctAnswersData[engWord.toLowerCase()];
                            if (correctVietnamese == word) {
                              isCorrect = true;
                              break;
                            }
                          }
                        }
                      }
                      
                      if (isCorrect) return const SizedBox(height: 56);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMatchingOptionNew(
                          label: label,
                          text: word,
                          isSelected: false,
                          isCorrect: false,
                          isWrong: false,
                          onTap: () async {
                            if (selectedEnglish == null) return;
                            
                            final englishWord = englishWords[selectedEnglish];
                            if (englishWord == null) return;
                            
                            if (correctAnswersData != null) {
                              final correctVietnamese = correctAnswersData[englishWord.toLowerCase()];
                              final isMatchCorrect = correctVietnamese == word;
                              
                              if (isMatchCorrect) {
                                setState(() {
                                  correctPairs.add(selectedEnglish);
                                  wrongPairs.remove(selectedEnglish);
                                  wrongDetails.remove(selectedEnglish);
                                  _matchingSelectedEnglish[questionId] = null;
                                });
                                
                                await Future.delayed(const Duration(seconds: 1));
                                setState(() {});
                                
                                if (correctPairs.length == totalPairs) {
                                  _answerResults[questionId] = true;
                                  _checkedQuestions[questionId] = true;
                                }
                              } else {
                                setState(() {
                                  wrongPairs.add(selectedEnglish);
                                  wrongDetails[selectedEnglish] = word;
                                  _matchingSelectedEnglish[questionId] = null;
                                });
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (foundPairs < totalPairs)
              Text('Chọn 1 từ tiếng Anh và 1 nghĩa tiếng Việt', style: TextStyle(fontSize: 14, color: Colors.grey[400]))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF3DD598)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hoàn thành! Bạn đã nối đúng tất cả các cặp.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3DD598)),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (wrongDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFEF5350), size: 20),
                        SizedBox(width: 8),
                        Text('Các cặp đã chọn sai:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF5350))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...wrongDetails.entries.map((entry) {
                      final englishLabel = entry.key;
                      final wrongVietnamese = entry.value;
                      final englishWord = englishWords[englishLabel] ?? '';
                      final correctVietnamese = correctAnswersData?[englishWord.toLowerCase()] ?? '';
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $englishWord → $wrongVietnamese (Đáp án đúng: $correctVietnamese)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingOptionNew({
    required String label,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    VoidCallback? onTap,
  }) {
    Color backgroundColor;
    Color borderColor;
    
    if (isCorrect) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF3DD598);
    } else if (isWrong) {
      backgroundColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF3DD598);
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFE0E0E0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: (isSelected || isCorrect || isWrong) ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: (isSelected || isCorrect || isWrong) ? borderColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: (isSelected || isCorrect || isWrong) ? borderColor : const Color(0xFF9E9E9E), width: 2),
              ),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: (isSelected || isCorrect || isWrong) ? Colors.white : const Color(0xFF9E9E9E))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle, color: Color(0xFF3DD598), size: 20)
            else if (isWrong)
              const Icon(Icons.cancel, color: Color(0xFFEF5350), size: 20)
            else if (isSelected)
              const Icon(Icons.check, color: Color(0xFF3DD598), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoryContent(Map<String, dynamic> question) {
    return VocabularyTheoryContentWidget(
      question: question,
      vocabularyTitle: widget.vocabularyTitle,
    );
  }

  Widget _buildCompleteScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: Color(0xFF3DD598), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 32),
          const Text('Congratulations!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 16),
          Text('You\'ve completed the ${widget.vocabularyTitle}', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${_allQuestions.length}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Color(0xFF3DD598))),
                    Text('Questions', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                Container(width: 1, height: 60, color: Colors.grey[300]),
                Column(
                  children: [
                    Text('$_accuracy%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.black)),
                    Text('Accuracy', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOption(String label, String text, String? selectedAnswer, bool enabled, Function(String) onTap, bool? isCorrect) {
    final isSelected = selectedAnswer == label;
    Color backgroundColor;
    Color borderColor;

    if (isCorrect == true) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF3DD598);
    } else if (isCorrect == false) {
      backgroundColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF3DD598);
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFE0E0E0);
    }

    return GestureDetector(
      onTap: enabled ? () => onTap(label) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected || isCorrect != null ? borderColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected || isCorrect != null ? borderColor : const Color(0xFF9E9E9E), width: 2),
              ),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected || isCorrect != null ? Colors.white : const Color(0xFF9E9E9E))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep >= _allQuestions.length) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DD598),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue Learning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    bool canGoNext = true;
    if (_currentStep < _allQuestions.length) {
      final question = _allQuestions[_currentStep];
      final questionId = question['question_id'];
      final partDescription = question['part_description'];
      
      if (partDescription == 'MULTIPLE_CHOICE' || partDescription == 'FILL_IN_BLANK') {
        canGoNext = _checkedQuestions[questionId] == true;
      } else if (partDescription == 'MATCHING') {
        final correctPairs = _matchingCorrectPairs[questionId] ?? {};
        final displayOrders = question['displayOrders'] as List;
        final totalPairs = (displayOrders.length / 2).floor();
        canGoNext = correctPairs.length >= totalPairs;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: _previousStep),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canGoNext ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD598),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text('Continue Learning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractContent(String contentPath) {
    try {
      final uri = Uri.parse(contentPath);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (e) {
      print('Error extracting content: $e');
    }
    return contentPath;
  }
}

// Theory Content Widget for Vocabulary
class VocabularyTheoryContentWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final String vocabularyTitle;

  const VocabularyTheoryContentWidget({
    Key? key,
    required this.question,
    required this.vocabularyTitle,
  }) : super(key: key);

  @override
  State<VocabularyTheoryContentWidget> createState() => _VocabularyTheoryContentWidgetState();
}

class _VocabularyTheoryContentWidgetState extends State<VocabularyTheoryContentWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  Map<int, String> _textContents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAllContents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllContents() async {
    final displayOrders = widget.question['displayOrders'] as List;
    
    for (var order in displayOrders) {
      final contentType = order['content_type'];
      final contentPath = order['content_path'];
      final displayOrderId = order['display_order_id'];
      
      if (contentType == 'text') {
        try {
          final content = await VocabularyPracticeApiService.fetchContent(contentPath);
          _textContents[displayOrderId] = content;
        } catch (e) {
          _textContents[displayOrderId] = 'Error: $e';
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayOrders = widget.question['displayOrders'] as List;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF3DD598)),
            const SizedBox(height: 16),
            const Text('Loading content...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(displayOrders.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF3DD598) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: displayOrders.length,
            itemBuilder: (context, index) => _buildContentPage(displayOrders[index]),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _currentPage < displayOrders.length - 1 ? 'Swipe to continue' : 'Tap button to continue',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildContentPage(Map<String, dynamic> order) {
    final contentType = order['content_type'];
    final contentPath = order['content_path'];
    final displayOrderId = order['display_order_id'];
    final description = order['description'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.vocabularyTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
            
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
            
            const SizedBox(height: 24),
            
            if (contentType == 'text') ...[
              Text(_textContents[displayOrderId] ?? 'Loading...', style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black)),
            ] else if (contentType == 'image') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  contentPath,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                          color: const Color(0xFF3DD598),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}