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
  
  // User answers for submission
  Map<int, String> _partAnswers = {}; // part_id -> answer string
  Map<String, dynamic>? _submitResult; // Kết quả sau khi submit
  
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
      // Gọi API mới - lấy toàn bộ lesson với parts và questions trong 1 lần
      final lessonData = await VocabularyPracticeApiService.getLessonWithParts(
        lessonId: widget.lessonId,
      );

      print('📚 Vocabulary lesson response: 200');

      final lesson = lessonData['data'] as Map<String, dynamic>;
      final parts = lesson['parts'] as List? ?? [];
      
      _parts = parts.map((p) => p as Map<String, dynamic>).toList();

      final allQuestions = <Map<String, dynamic>>[];
      
      // Duyệt qua từng part để lấy questions
      for (var part in _parts) {
        final partId = part['part_id'];
        final partDescription = part['description'];
        final correctAnswerPath = part['correct_answer_path'];
        final questions = part['questions'] as List? ?? [];

        // Load correct answers cho part này
        if (correctAnswerPath != null && correctAnswerPath.toString().isNotEmpty) {
          await _loadCorrectAnswers(partId, correctAnswerPath, partDescription);
        }

        // Thêm questions vào danh sách
        for (var question in questions) {
          final questionWithPart = Map<String, dynamic>.from(question);
          questionWithPart['part_id'] = partId;
          questionWithPart['part_description'] = partDescription;
          allQuestions.add(questionWithPart);
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
        final wrongPairs = _matchingWrongPairs[questionId] ?? {};
        final displayOrders = currentQuestion['displayOrders'] as List;
        final totalPairs = (displayOrders.length / 2).floor();
        
        final totalMatched = correctPairs.length + wrongPairs.length;
        if (totalMatched < totalPairs) {
          return;
        }
      }
      
      setState(() {
        _currentStep++;
        _learnedSteps = _currentStep;
      });
    } else if (_currentStep == _allQuestions.length - 1) {
      // Hoàn thành lesson, submit answers
      _submitLesson();
    }
  }

  Future<void> _submitLesson() async {
    // Collect answers for each part
    _collectPartAnswers();
    
    // Submit to API
    try {
      final answers = _partAnswers.entries.map((entry) {
        return {
          'part_id': entry.key,
          'answer': entry.value,
        };
      }).toList();
      
      print('📤 Submitting lesson ${widget.lessonId} with ${answers.length} parts');
      
      final result = await VocabularyPracticeApiService.submitLesson(
        lessonId: widget.lessonId,
        answers: answers,
      );
      
      setState(() {
        _submitResult = result['data'];
        _currentStep = _allQuestions.length;
      });
      
      print('✅ Lesson submitted successfully. Score: ${_submitResult!['total_score']}');
    } catch (e) {
      print('❌ Error submitting lesson: $e');
      // Still show complete screen even if submit fails
      setState(() {
        _currentStep = _allQuestions.length;
      });
    }
  }

  void _collectPartAnswers() {
    // Group questions by part_id
    Map<int, List<Map<String, dynamic>>> questionsByPart = {};
    for (var question in _allQuestions) {
      final partId = question['part_id'] as int;
      if (!questionsByPart.containsKey(partId)) {
        questionsByPart[partId] = [];
      }
      questionsByPart[partId]!.add(question);
    }
    
    // Build answer string for each part
    for (var entry in questionsByPart.entries) {
      final partId = entry.key;
      final questions = entry.value;
      
      if (questions.isEmpty) continue;
      
      final partDescription = questions[0]['part_description'];
      
      if (partDescription == 'MULTIPLE_CHOICE') {
        // Format: A,B,C,D
        final answers = questions.map((q) {
          final questionId = q['question_id'];
          return _selectedAnswers[questionId] ?? '';
        }).toList();
        
        final answer = answers.join(',');
        _partAnswers[partId] = answer;
        print('📝 Part $partId (MULTIPLE_CHOICE) answer: $answer');
      } else if (partDescription == 'MATCHING') {
        // Format: word1-nghĩa1,word2-nghĩa2
        final pairs = <String>[];
        final questionId = questions[0]['question_id']; // MATCHING chỉ có 1 question
        final wrongDetails = _matchingWrongDetails[questionId] ?? {};
        
        // wrongDetails structure: {vietnamese: english}
        for (var entry in wrongDetails.entries) {
          final vietnamese = entry.key.trim();
          final english = entry.value.trim();
          pairs.add('$english-$vietnamese');
        }
        
        final answer = pairs.join(',');
        _partAnswers[partId] = answer;
        print('📝 Part $partId (MATCHING) answer: $answer');
      } else if (partDescription == 'FILL_IN_BLANK') {
        // Format: word1,word2
        final answers = questions.map((q) {
          final questionId = q['question_id'];
          return _fillInAnswers[questionId]?.trim() ?? '';
        }).toList();
        
        final answer = answers.join(',');
        _partAnswers[partId] = answer;
        print('📝 Part $partId (FILL_IN_BLANK) answer: $answer');
      }
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
                            isCorrect == true ? 'Chính xác!' : 'Chưa đúng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350),
                            ),
                          ),
                          if (isCorrect == false && correctAnswerText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Đáp án đúng: $correctAnswerText',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOption(String label, String text, String? selectedAnswer, bool enabled, Function(String) onSelect, bool? isCorrect) {
    final isSelected = selectedAnswer == label;
    
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    
    if (isCorrect == true) {
      borderColor = const Color(0xFF3DD598);
      backgroundColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF3DD598);
    } else if (isCorrect == false) {
      borderColor = const Color(0xFFEF5350);
      backgroundColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFEF5350);
    } else if (isSelected) {
      borderColor = const Color(0xFF3DD598);
      backgroundColor = const Color(0xFFF0FFF4);
      textColor = Colors.black;
    } else {
      borderColor = const Color(0xFFE0E0E0);
      backgroundColor = Colors.white;
      textColor = Colors.black;
    }

    return InkWell(
      onTap: enabled ? () => onSelect(label) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect != null ? (isCorrect ? const Color(0xFF3DD598) : const Color(0xFFEF5350)) : (isSelected ? const Color(0xFF3DD598) : Colors.transparent),
                border: Border.all(color: isCorrect != null ? (isCorrect ? const Color(0xFF3DD598) : const Color(0xFFEF5350)) : (isSelected ? const Color(0xFF3DD598) : const Color(0xFFBDBDBD)), width: 2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCorrect != null ? Colors.white : (isSelected ? Colors.white : const Color(0xFFBDBDBD)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ),
            if (isCorrect != null)
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? const Color(0xFF3DD598) : const Color(0xFFEF5350),
              ),
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
    
    if (!_textControllers.containsKey(questionId)) {
      _textControllers[questionId] = TextEditingController();
    }
    
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
            Text(questionText, style: const TextStyle(fontSize: 18, color: Colors.black), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _textControllers[questionId],
              enabled: !isChecked,
              onChanged: (value) {
                setState(() {
                  _fillInAnswers[questionId] = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời của bạn...',
                filled: true,
                fillColor: isChecked ? (isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3DD598), width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350),
                    width: 2,
                  ),
                ),
              ),
            ),
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
                            isCorrect == true ? 'Chính xác!' : 'Chưa đúng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCorrect == true ? const Color(0xFF3DD598) : const Color(0xFFEF5350),
                            ),
                          ),
                          if (isCorrect == false && correctAnswer != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Đáp án đúng: $correctAnswer',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingQuestion(Map<String, dynamic> question) {
    final questionId = question['question_id'] as int;
    final displayOrders = question['displayOrders'] as List;
    
    if (displayOrders.length < 2) {
      return const Center(child: Text('Insufficient data for matching'));
    }

    final englishWords = <String>[];
    final vietnameseWords = <String>[];
    
    for (int i = 0; i < displayOrders.length; i++) {
      final content = _extractContent(displayOrders[i]['content_path']);
      if (i % 2 == 0) {
        englishWords.add(content);
      } else {
        vietnameseWords.add(content);
      }
    }

    final selectedEnglish = _matchingSelectedEnglish[questionId];
    final correctPairs = _matchingCorrectPairs[questionId] ?? {};
    final wrongPairs = _matchingWrongPairs[questionId] ?? {};
    final wrongDetails = _matchingWrongDetails[questionId] ?? {};

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nối từ với nghĩa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              'Chọn từ và nghĩa tương ứng',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột tiếng Anh
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIẾNG ANH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      ...englishWords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        final label = String.fromCharCode(65 + index); // A, B, C, D, E
                        final isSelected = selectedEnglish == word;
                        final isCorrectPair = correctPairs.contains(word);
                        final isWrongPair = wrongPairs.contains(word);
                        
                        Color backgroundColor;
                        Color borderColor;
                        Color textColor;
                        
                        if (isCorrectPair) {
                          backgroundColor = const Color(0xFFE8F5E9);
                          borderColor = const Color(0xFF3DD598);
                          textColor = const Color(0xFF3DD598);
                        } else if (isWrongPair) {
                          backgroundColor = const Color(0xFFFFEBEE);
                          borderColor = const Color(0xFFEF5350);
                          textColor = Colors.black;
                        } else if (isSelected) {
                          backgroundColor = const Color(0xFFF0FFF4);
                          borderColor = const Color(0xFF3DD598);
                          textColor = Colors.black;
                        } else {
                          backgroundColor = Colors.white;
                          borderColor = const Color(0xFFE0E0E0);
                          textColor = Colors.black;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: (isCorrectPair || isWrongPair) ? null : () {
                              setState(() {
                                _matchingSelectedEnglish[questionId] = word;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrectPair ? const Color(0xFF3DD598) : (isSelected ? const Color(0xFF3DD598) : Colors.transparent),
                                      border: Border.all(
                                        color: isCorrectPair ? const Color(0xFF3DD598) : (isSelected ? const Color(0xFF3DD598) : const Color(0xFFBDBDBD)),
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isCorrectPair || isSelected ? Colors.white : const Color(0xFFBDBDBD),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      word,
                                      style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Cột tiếng Việt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIẾNG VIỆT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      ...vietnameseWords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        final label = '${index + 1}'; // 1, 2, 3, 4, 5
                        final matchedEnglish = wrongDetails[word];
                        final isCorrectPair = matchedEnglish != null && correctPairs.contains(matchedEnglish);
                        final isWrongPair = matchedEnglish != null && wrongPairs.contains(matchedEnglish);
                        
                        Color backgroundColor = Colors.white;
                        Color borderColor = const Color(0xFFE0E0E0);
                        Color textColor = Colors.black;
                        
                        if (isCorrectPair) {
                          backgroundColor = const Color(0xFFE8F5E9);
                          borderColor = const Color(0xFF3DD598);
                          textColor = const Color(0xFF3DD598);
                        } else if (isWrongPair) {
                          backgroundColor = const Color(0xFFFFEBEE);
                          borderColor = const Color(0xFFEF5350);
                          textColor = Colors.black;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: (selectedEnglish == null || isCorrectPair || isWrongPair) ? null : () {
                              _checkMatchingPair(questionId, selectedEnglish!, word);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrectPair ? const Color(0xFF3DD598) : Colors.transparent,
                                      border: Border.all(
                                        color: isCorrectPair ? const Color(0xFF3DD598) : const Color(0xFFBDBDBD),
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isCorrectPair ? Colors.white : const Color(0xFFBDBDBD),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      word,
                                      style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Tap to match',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkMatchingPair(int questionId, String english, String vietnamese) {
    final question = _allQuestions.firstWhere((q) => q['question_id'] == questionId);
    final partId = question['part_id'];
    final correctAnswersData = _correctAnswers[partId] as Map<String, String>?;

    if (correctAnswersData == null) return;

    final isCorrect = correctAnswersData[english] == vietnamese;

    setState(() {
      if (isCorrect) {
        // Đúng: Thêm vào correctPairs, hiển thị màu xanh vĩnh viễn
        _matchingCorrectPairs[questionId] = (_matchingCorrectPairs[questionId] ?? {})..add(english);
        _matchingWrongDetails[questionId] = (_matchingWrongDetails[questionId] ?? {})..[vietnamese] = english;
      } else {
        // Sai: Thêm vào wrongPairs, hiển thị nền đỏ vĩnh viễn
        _matchingWrongPairs[questionId] = (_matchingWrongPairs[questionId] ?? {})..add(english);
        _matchingWrongDetails[questionId] = (_matchingWrongDetails[questionId] ?? {})..[vietnamese] = english;
      }
      _matchingSelectedEnglish[questionId] = null;
    });
  }

  Widget _buildTheoryContent(Map<String, dynamic> question) {
    return VocabularyTheoryContentWidget(
      question: question,
      vocabularyTitle: widget.vocabularyTitle,
    );
  }

  Widget _buildCompleteScreen() {
    // Calculate score from API result
    double totalScore = 0;
    double maxScore = _parts.length * 100.0;
    
    if (_submitResult != null && _submitResult!['part_results'] != null) {
      final partResults = _submitResult!['part_results'] as List;
      for (var result in partResults) {
        totalScore += (result['score'] as num).toDouble();
      }
    }
    
    final scorePercent = maxScore > 0 ? ((totalScore / maxScore) * 100).round() : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 48, color: Color(0xFF3DD598)),
            ),
            const SizedBox(height: 24),
            const Text('Hoàn thành!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành bài học',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_parts.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text('Parts', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Column(
                    children: [
                      Text(
                        '$scorePercent%',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF3DD598)),
                      ),
                      const SizedBox(height: 4),
                      Text('Score', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            if (_submitResult != null && _submitResult!['part_results'] != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết từng phần:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ...(_submitResult!['part_results'] as List).map((result) {
                      final partNumber = result['part_number'];
                      final correctAnswers = result['correct_answers'];
                      final totalQuestions = result['total_questions'];
                      final score = (result['score'] as num).toDouble().toStringAsFixed(0);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Part $partNumber:',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            Text(
                              '$correctAnswers/$totalQuestions ($score/100)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD598),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hoàn thành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep >= _allQuestions.length) {
      return const SizedBox.shrink();
    }

    final currentQuestion = _allQuestions[_currentStep];
    final questionId = currentQuestion['question_id'];
    final partDescription = currentQuestion['part_description'];
    
    bool canGoNext = false;
    bool isChecked = false;
    String buttonText = 'Kiểm tra';
    VoidCallback? buttonAction;
    
    if (partDescription == 'MULTIPLE_CHOICE') {
      isChecked = _checkedQuestions[questionId] == true;
      final hasAnswer = _selectedAnswers[questionId] != null;
      
      if (!isChecked && hasAnswer) {
        buttonText = 'Kiểm tra';
        buttonAction = () => _checkAnswer(questionId, 'MULTIPLE_CHOICE');
      } else if (isChecked) {
        buttonText = 'Continue';
        canGoNext = true;
        buttonAction = _nextStep;
      }
    } else if (partDescription == 'FILL_IN_BLANK') {
      isChecked = _checkedQuestions[questionId] == true;
      final hasAnswer = (_fillInAnswers[questionId]?.trim().isNotEmpty ?? false);
      
      if (!isChecked && hasAnswer) {
        buttonText = 'Kiểm tra';
        buttonAction = () => _checkAnswer(questionId, 'FILL_IN_BLANK');
      } else if (isChecked) {
        // Cho next khi đã kiểm tra (không quan tâm đúng/sai)
        buttonText = 'Continue';
        canGoNext = true;
        buttonAction = _nextStep;
      }
    } else if (partDescription == 'MATCHING') {
      final correctPairs = _matchingCorrectPairs[questionId] ?? {};
      final wrongPairs = _matchingWrongPairs[questionId] ?? {};
      final displayOrders = currentQuestion['displayOrders'] as List;
      final totalPairs = (displayOrders.length / 2).floor();
      
      final totalMatched = correctPairs.length + wrongPairs.length;
      canGoNext = totalMatched >= totalPairs;
      
      if (canGoNext) {
        buttonText = 'Continue';
        buttonAction = _nextStep;
      }
    } else {
      // Theory or other types
      canGoNext = true;
      buttonText = 'Continue';
      buttonAction = _nextStep;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _previousStep,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: buttonAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD598),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractContent(String contentPath) {
    // Nếu không phải URL, trả về trực tiếp
    if (!contentPath.startsWith('http')) {
      return contentPath;
    }
    
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
        // Nếu không phải URL, sử dụng trực tiếp
        if (!contentPath.startsWith('http')) {
          _textContents[displayOrderId] = contentPath;
        } else {
          try {
            final content = await VocabularyPracticeApiService.fetchContent(contentPath);
            _textContents[displayOrderId] = content;
          } catch (e) {
            _textContents[displayOrderId] = 'Error: $e';
          }
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
              Text(_textContents[displayOrderId] ?? contentPath, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black)),
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