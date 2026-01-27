import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/services/grammar_api_service.dart';

class GrammarLessonScreen extends StatefulWidget {
  final String grammarTitle;
  final String grammarLevel;
  final int lessonId;

  const GrammarLessonScreen({
    Key? key,
    required this.grammarTitle,
    required this.grammarLevel,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  // --- BIẾN TRẠNG THÁI ---
  bool _isLoading = true;
  bool _isSubmitting = false; // Flag để đợi API trả về điểm số cuối cùng
  String? _loadError;
  
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _allQuestions = [];
  Map<int, dynamic> _correctAnswers = {}; 
  
  int _currentStep = 0;
  int _learnedSteps = 0;
  
  Map<int, String> _selectedAnswers = {};
  Map<int, bool> _checkedQuestions = {};
  Map<int, bool> _answerResults = {}; 
  
  Map<int, List<String>> _partAnswers = {}; 
  Map<int, dynamic> _submissionResults = {}; 
  Map<int, int> _theoryDisplayIndex = {}; 

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  // --- LOGIC TẢI DỮ LIỆU (Giữ nguyên gốc) ---
  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final partsData = await GrammarApiService.getLessonParts(lessonId: widget.lessonId);
      final parts = partsData['data'] as List;
      _parts = parts.map((p) => p as Map<String, dynamic>).toList();

      final allQuestions = <Map<String, dynamic>>[];
      for (var part in _parts) {
        final partId = part['part_id'];
        try {
          final partDetailData = await GrammarApiService.getPartDetails(partId: partId);
          final partDetail = partDetailData['data'] as Map<String, dynamic>;
          final questions = partDetail['questions'] as List? ?? [];
          final correctAnswerPath = partDetail['correct_answer_path'];
          final partDescription = part['description'];

          if (correctAnswerPath != null && correctAnswerPath.toString().isNotEmpty && partDescription == 'MULTIPLE_CHOICE') {
            await _loadCorrectAnswers(partId, correctAnswerPath);
          }

          for (var question in questions) {
            final questionWithPart = Map<String, dynamic>.from(question);
            questionWithPart['part_id'] = partId;
            questionWithPart['part_description'] = partDescription;
            allQuestions.add(questionWithPart);
          }
        } catch (e) { continue; }
      }

      setState(() {
        _allQuestions = allQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCorrectAnswers(int partId, String correctAnswerPath) async {
    try {
      final content = await GrammarApiService.fetchCorrectAnswers(correctAnswerPath);
      final answers = content.trim().split('').where((e) => e.trim().isNotEmpty).map((e) => e.trim().toUpperCase()).toList();
      _correctAnswers[partId] = answers;
    } catch (e) {
      print('❌ Error loading answers: $e');
    }
  }

  // --- LOGIC ĐIỀU HƯỚNG & XỬ LÝ ĐIỂM SỐ ---
  double get _progressValue => _allQuestions.isEmpty ? 0.0 : _currentStep / _allQuestions.length;

  void _nextStep() async {
    if (_currentStep < _allQuestions.length - 1) {
      final currentQuestion = _allQuestions[_currentStep];
      if (currentQuestion['part_description'] == 'MULTIPLE_CHOICE' && _checkedQuestions[currentQuestion['question_id']] != true) return;
      
      setState(() {
        _currentStep++;
        _learnedSteps = _currentStep;
        _theoryDisplayIndex.clear();
      });
    } else if (_currentStep == _allQuestions.length - 1) {
      // Khi ở câu cuối cùng và bấm Continue
      setState(() {
        _isSubmitting = true; 
        _currentStep = _allQuestions.length; // Chuyển sang màn hình kết quả
      });
      await _submitAllPartAnswers(); // Gọi API lấy điểm
    }
  }

  Future<void> _submitAllPartAnswers() async {
    try {
      for (var partId in _partAnswers.keys) {
        final answers = _partAnswers[partId]!.join('');
        if (answers.isNotEmpty) {
          final result = await GrammarApiService.submitPartAnswers(
            lessonId: widget.lessonId,
            partId: partId,
            answers: answers,
          );
          if (result != null && result['data'] != null && result['data']['data'] != null) {
            setState(() {
              _submissionResults[partId] = result['data']['data'];
            });
          }
        }
      }
    } catch (e) {
      print('❌ Submission error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _checkAnswer(int questionId) {
    final question = _allQuestions.firstWhere((q) => q['question_id'] == questionId);
    final partId = question['part_id'];
    final correctAnswersData = _correctAnswers[partId];
    final selectedAnswer = _selectedAnswers[questionId];

    if (selectedAnswer == null || correctAnswersData == null) return;
    
    final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
    final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
    
    if (questionIndex >= 0 && questionIndex < correctAnswersData.length) {
      bool isCorrect = selectedAnswer == correctAnswersData[questionIndex];
      
      if (!_partAnswers.containsKey(partId)) _partAnswers[partId] = [];
      while (_partAnswers[partId]!.length <= questionIndex) _partAnswers[partId]!.add('');
      _partAnswers[partId]![questionIndex] = selectedAnswer;
      
      // Submit từng câu lẻ cho analytics (API hiện tại của bạn)
      GrammarApiService.submitAnswer(
        partId: partId, 
        questionId: questionId, 
        selectedAnswer: selectedAnswer, 
        quality: isCorrect ? 3 : 1
      );
      
      setState(() {
        _checkedQuestions[questionId] = true;
        _answerResults[questionId] = isCorrect;
      });
    }
  }

  // --- CẤU TRÚC UI CHÍNH (Giữ nguyên giao diện của bạn) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(widget.grammarTitle, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3DD598)))
          : _loadError != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildProgressBar(),
                    Expanded(
                      child: _currentStep >= _allQuestions.length 
                          ? _buildCompleteScreen() 
                          : _buildCurrentContent(),
                    ),
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of ${_allQuestions.length}', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(fontSize: 14, color: Color(0xFF3DD598), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progressValue, backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3DD598)), minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI CÂU HỎI TRẮC NGHIỆM ---
  Widget _buildMultipleChoiceContent(Map<String, dynamic> question) {
    final questionId = question['question_id'];
    final displayOrders = question['displayOrders'] as List;
    if (displayOrders.isEmpty) return const Center(child: Text('No question available'));
    
    final questionText = displayOrders[0]['description'] ?? '';
    final options = displayOrders.sublist(1).take(4).toList();
    final selectedAnswer = _selectedAnswers[questionId];
    final isChecked = _checkedQuestions[questionId] == true;
    final isCorrect = _answerResults[questionId];

    final partId = question['part_id'];
    final correctAnswersData = _correctAnswers[partId];
    final questionsInPart = _allQuestions.where((q) => q['part_id'] == partId).toList();
    final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
    String? correctAnswer = (correctAnswersData != null && questionIndex >= 0) ? correctAnswersData[questionIndex] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            const Text('Bài tập trắc nghiệm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Text(questionText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ...options.asMap().entries.map((entry) {
              final label = String.fromCharCode(65 + entry.key);
              bool? optionCorrect;
              if (isChecked) {
                if (label == correctAnswer) optionCorrect = true;
                else if (label == selectedAnswer && isCorrect == false) optionCorrect = false;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMultipleChoiceOption(label, entry.value['description'] ?? '', selectedAnswer, !isChecked, (v) => setState(() => _selectedAnswers[questionId] = v), optionCorrect),
              );
            }).toList(),
            if (isChecked) _buildFeedbackArea(isCorrect, correctAnswer),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackArea(bool? isCorrect, String? correctAnswer) {
    return Container(
      margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(isCorrect == true ? Icons.check_circle : Icons.cancel, color: isCorrect == true ? Colors.green : Colors.red),
        const SizedBox(width: 12),
        Text(isCorrect == true ? 'Chính xác!' : 'Sai rồi. Đáp án là $correctAnswer', style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect == true ? Colors.green : Colors.red)),
      ]),
    );
  }

  // --- UI LÝ THUYẾT (Khôi phục toàn bộ logic Card & Helper) ---
  Widget _buildTheoryContent(Map<String, dynamic> question) {
    final questionId = question['question_id'];
    final displayOrders = question['displayOrders'] as List;
    final currentIndex = _theoryDisplayIndex[questionId] ?? 0;
    if (displayOrders.isEmpty) return const Center(child: Text('No content'));
    return Center(child: _buildTheoryDisplayContent(displayOrders[currentIndex], currentIndex, displayOrders.length, questionId));
  }

  Widget _buildTheoryDisplayContent(Map<String, dynamic> displayOrder, int currentIndex, int totalDisplays, int questionId) {
    final description = displayOrder['description'] ?? '';
    final lines = description.split('\n');
    final subTitle = lines.isNotEmpty ? lines[0].trim() : ''; 
    final bodyContent = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(widget.grammarTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          Text(widget.grammarLevel, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: Text(subTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.fade)),
                  _buildSmallNavButton(icon: Icons.chevron_left, onTap: currentIndex > 0 ? () => setState(() => _theoryDisplayIndex[questionId] = currentIndex - 1) : null, isActive: currentIndex > 0),
                  const SizedBox(width: 8),
                  _buildSmallNavButton(icon: Icons.chevron_right, onTap: currentIndex < totalDisplays - 1 ? () => setState(() => _theoryDisplayIndex[questionId] = currentIndex + 1) : null, isActive: currentIndex < totalDisplays - 1, isPrimary: true),
                ]),
                const SizedBox(height: 20),
                _buildTheoryTextContent(bodyContent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheoryTextContent(String content) {
    final lines = content.split('\n');
    return Column(children: lines.map((line) {
      if (line.trim().isEmpty) return const SizedBox.shrink();
      bool isFormula = line.contains('+') || line.contains('V(');
      return isFormula ? _buildFormulaBox(line.trim()) : _buildBulletLine(line.trim());
    }).toList());
  }

  Widget _buildFormulaBox(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)), textAlign: TextAlign.center),
    );
  }

  Widget _buildBulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 8, right: 12), width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3DD598), shape: BoxShape.circle)),
        Expanded(child: Text(text.replaceFirst(RegExp(r'^[•\-]\s*'), ''), style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568), height: 1.5))),
      ]),
    );
  }

  Widget _buildSmallNavButton({required IconData icon, VoidCallback? onTap, bool isActive = true, bool isPrimary = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF3DD598) : (isActive ? Colors.white : Colors.grey[100]), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
        child: Icon(icon, size: 20, color: isPrimary ? Colors.white : (isActive ? Colors.black87 : Colors.grey[400])),
      ),
    );
  }

  // --- MÀN HÌNH HOÀN THÀNH ---
  Widget _buildCompleteScreen() {
    if (_isSubmitting) return const Center(child: CircularProgressIndicator(color: Color(0xFF3DD598)));
    
    int totalScore = 0;
    _submissionResults.forEach((id, data) {
      if (data != null && data['score'] != null) totalScore += int.parse(data['score'].toString());
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFF3DD598)),
        const SizedBox(height: 24),
        const Text('Lesson Completed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Total Score: $totalScore', style: const TextStyle(fontSize: 32, color: Color(0xFF3DD598), fontWeight: FontWeight.w800)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3DD598), padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Back to Lessons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ])),
    );
  }

  // --- THANH ĐIỀU HƯỚNG DƯỚI CÙNG (Fix lỗi height -> fixedSize) ---
  Widget _buildBottomBar() {
    if (_currentStep >= _allQuestions.length) return const SizedBox.shrink();
    final q = _allQuestions[_currentStep];
    final questionId = q['question_id'];
    bool isTheory = q['part_description'] == 'THEORY';
    bool isMultipleChoice = q['part_description'] == 'MULTIPLE_CHOICE';
    int currentIdx = _theoryDisplayIndex[questionId] ?? 0;
    int total = isTheory ? (q['displayOrders'] as List).length : 0;
    
    // Xác định text và action cho button
    String buttonText;
    VoidCallback? buttonAction;
    bool isEnabled = false;
    
    if (isTheory) {
      buttonText = 'Continue Learning';
      isEnabled = true;
      buttonAction = () {
        if (currentIdx < total - 1) {
          setState(() => _theoryDisplayIndex[questionId] = currentIdx + 1);
        } else {
          _nextStep();
        }
      };
    } else if (isMultipleChoice) {
      bool isChecked = _checkedQuestions[questionId] == true;
      String? selectedAnswer = _selectedAnswers[questionId];
      
      if (!isChecked) {
        // Chưa kiểm tra -> hiển thị button "Kiểm tra"
        buttonText = 'Kiểm tra';
        isEnabled = selectedAnswer != null;
        buttonAction = () => _checkAnswer(questionId);
      } else {
        // Đã kiểm tra -> hiển thị button "Continue Learning"
        buttonText = 'Continue Learning';
        isEnabled = true;
        buttonAction = () => _nextStep();
      }
    } else {
      buttonText = 'Continue Learning';
      isEnabled = true;
      buttonAction = () => _nextStep();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 45),
      child: Row(children: [
        if (_currentStep > 0 || (isTheory && currentIdx > 0))
          IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () {
            if (isTheory && currentIdx > 0) { setState(() => _theoryDisplayIndex[questionId] = currentIdx - 1); } 
            else { setState(() => _currentStep--); }
          }),
        Expanded(child: ElevatedButton(
          onPressed: isEnabled ? buttonAction : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3DD598), 
            fixedSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    );
  }

  // --- HÀM BỔ TRỢ KHÁC ---
  Widget _buildCurrentContent() => ( _allQuestions[_currentStep]['part_description'] == 'THEORY') ? _buildTheoryContent(_allQuestions[_currentStep]) : _buildMultipleChoiceContent(_allQuestions[_currentStep]);
  Widget _buildErrorState() => Center(child: Text(_loadError!));

  Widget _buildMultipleChoiceOption(String label, String text, String? selected, bool enabled, Function(String) onTap, bool? isCorrect) {
    final isSelected = selected == label;
    
    // Xác định màu viền
    Color borderColor;
    if (isCorrect == true) {
      borderColor = const Color(0xFF3DD598); // Đáp án đúng: viền xanh
    } else if (isCorrect == false) {
      borderColor = Colors.red; // Đáp án sai: viền đỏ
    } else if (isSelected) {
      borderColor = const Color(0xFF3DD598); // Được chọn nhưng chưa kiểm tra: viền xanh
    } else {
      borderColor = Colors.grey[300]!; // Không được chọn: viền xám
    }
    
    return GestureDetector(
      onTap: enabled ? () => onTap(label) : null,
      child: Container(
        padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCorrect == true ? const Color(0xFFE8F5E9) : (isCorrect == false ? const Color(0xFFFFEBEE) : Colors.white), 
          border: Border.all(color: borderColor, width: 2), 
          borderRadius: BorderRadius.circular(12)
        ),
        child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: isSelected || isCorrect != null ? (isCorrect == false ? Colors.red : const Color(0xFF3DD598)) : Colors.grey[200], child: Text(label, style: TextStyle(color: isSelected || isCorrect != null ? Colors.white : Colors.black))),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ]),
      ),
    );
  }
}