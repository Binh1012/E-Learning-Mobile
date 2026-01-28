import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/review_test_api_service.dart';

class ReviewTestScreen extends StatefulWidget {
  final String testTitle;
  final String testLevel;
  final int lessonId;
  final String lessonDescription;

  const ReviewTestScreen({
    Key? key,
    required this.testTitle,
    required this.testLevel,
    required this.lessonId,
    required this.lessonDescription,
  }) : super(key: key);

  @override
  State<ReviewTestScreen> createState() => _ReviewTestScreenState();
}

class _ReviewTestScreenState extends State<ReviewTestScreen> {
  static const String S3_BASE_URL = 'https://e-learn-backend.s3.ap-southeast-2.amazonaws.com/';
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _allQuestions = [];
  
  int _currentStep = 0;
  int _learnedSteps = 0;
  
  Map<int, String> _selectedAnswers = {};
  Map<int, List<String>> _partAnswers = {};
  Map<int, String> _partAnswerStrings = {}; // Lưu đáp án dạng "ABCBAADA" theo part_id
  
  // Exam results
  Map<String, dynamic>? _examResults;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _audioUrl;
  
  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLessonData();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _playPauseAudio() async {
    if (_audioUrl == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position == Duration.zero) {
        await _audioPlayer.play(UrlSource(_audioUrl!));
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final lessonData = await ReviewTestApiService.getLessonData(lessonId: widget.lessonId);
      final data = lessonData['data'] as Map<String, dynamic>;
      
      final parts = data['parts'] as List? ?? [];
      _parts = parts.map((p) => p as Map<String, dynamic>).toList();

      final allQuestions = <Map<String, dynamic>>[];
      String? audioUrlFound;
      
      for (var part in _parts) {
        final partId = part['part_id'];
        final partNumber = part['part_number'];
        final partDescription = part['description'] as String? ?? '';
        final questions = part['questions'] as List? ?? [];
        
        print('📦 Part $partNumber: $partDescription');
        
        // Part 1: Tìm audio file
        if (partNumber == 1) {
          for (var question in questions) {
            final displayOrders = question['displayOrders'] as List? ?? [];
            for (var display in displayOrders) {
              final contentType = (display['content_type'] as String? ?? '').toUpperCase();
              final contentPath = display['content_path'] as String?;
              
              if (contentType == 'AUDIO' && contentPath != null) {
                final cleanPath = contentPath.trim().replaceAll('\n', '');
                audioUrlFound = S3_BASE_URL + cleanPath;
                print('🎵 Found audio: $audioUrlFound');
                break;
              }
            }
            if (audioUrlFound != null) break;
          }
          continue;
        }
        
        // Part 2+: Hiển thị tất cả questions cùng lúc (virtual)
        if (questions.isNotEmpty) {
          final firstQuestion = questions.first;
          final virtualQuestion = Map<String, dynamic>.from(firstQuestion);
          virtualQuestion['part_id'] = partId;
          virtualQuestion['part_number'] = partNumber;
          virtualQuestion['part_description'] = partDescription;
          virtualQuestion['is_virtual'] = true;
          virtualQuestion['all_questions'] = questions;
          allQuestions.add(virtualQuestion);
        }
      }

      print('✅ Loaded ${allQuestions.length} parts (virtual)');

      setState(() {
        _allQuestions = allQuestions;
        _audioUrl = audioUrlFound;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _loadError = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    // Lưu đáp án dạng chuỗi trước khi chuyển step
    _savePartAnswerString();
    
    if (_currentStep < _allQuestions.length - 1) {
      setState(() {
        _currentStep++;
        _learnedSteps = _currentStep;
      });
      // Scroll lên đầu khi chuyển part
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _submitTest();
    }
  }
  
  void _savePartAnswerString() {
    final currentQuestion = _allQuestions[_currentStep];
    final partId = currentQuestion['part_id'] as int;
    final isVirtual = currentQuestion['is_virtual'] == true;
    
    if (isVirtual) {
      final allQuestions = currentQuestion['all_questions'] as List? ?? [];
      String answerString = '';
      
      for (var q in allQuestions) {
        final questionId = q['question_id'] as int;
        final selectedAnswer = _selectedAnswers[questionId];
        
        if (selectedAnswer != null) {
          // Lấy danh sách đáp án từ displayOrders
          final displayOrders = q['displayOrders'] as List? ?? [];
          final texts = <String>[];
          
          for (var display in displayOrders) {
            final contentType = (display['content_type'] as String? ?? '').toUpperCase();
            final description = display['description'] as String? ?? '';
            if (contentType == 'TEXT' && description.isNotEmpty) {
              texts.add(description);
            }
          }
          
          // TEXT đầu tiên là câu hỏi, các TEXT sau là đáp án
          final answerOptions = <String>[];
          if (texts.isNotEmpty) {
            for (int i = 1; i < texts.length; i++) {
              String answer = texts[i].replaceAll('(', '').replaceAll(')', '').trim();
              if (answer.isNotEmpty) {
                answerOptions.add(answer);
              }
            }
          }
          
          // Tìm index của đáp án đã chọn
          final answerIndex = answerOptions.indexOf(selectedAnswer);
          if (answerIndex >= 0 && answerIndex < 26) {
            // Convert index thành A, B, C, D...
            answerString += String.fromCharCode(65 + answerIndex);
          }
        }
      }
      
      if (answerString.isNotEmpty) {
        _partAnswerStrings[partId] = answerString;
        print('📝 Part $partId answers: $answerString');
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      // Scroll lên đầu khi quay lại part trước
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _submitTest() async {
    // Lưu đáp án của part cuối cùng
    _savePartAnswerString();
    
    setState(() => _isSubmitting = true);
    
    print('🎯 Submitting test...');
    print('📊 All answers by part:');
    _partAnswerStrings.forEach((partId, answers) {
      print('   Part $partId: $answers');
    });
    
    try {
      // Gọi API submit exam
      final result = await ReviewTestApiService.submitExam(
        lessonId: widget.lessonId,
        partAnswers: _partAnswerStrings,
      );
      
      setState(() {
        _examResults = result['data'];
        _currentStep = _allQuestions.length;
        _isSubmitting = false;
      });
      
      print('✅ Exam submitted successfully!');
    } catch (e) {
      print('❌ Error submitting exam: $e');
      setState(() => _isSubmitting = false);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to submit exam: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.testTitle,
          style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3DD598)))
          : _loadError != null
              ? _buildErrorState()
              : _currentStep >= _allQuestions.length
                  ? _buildCompleteScreen()
                  : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        if (_audioUrl != null) _buildStickyAudioPlayer(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: _buildCurrentContent(),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildCurrentContent() {
    final currentQuestion = _allQuestions[_currentStep];
    return _buildQuestionContent(currentQuestion);
  }

  Widget _buildStickyAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _playPauseAudio,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(_position),
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.grey[800],
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Colors.grey[800],
              ),
              child: Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble() > 0 
                    ? _duration.inSeconds.toDouble() 
                    : 1,
                onChanged: (value) {
                  _seekAudio(Duration(seconds: value.toInt()));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_duration),
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.volume_up, size: 20, color: Colors.grey[700]),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(Map<String, dynamic> question) {
    final isVirtual = question['is_virtual'] == true;
    
    if (isVirtual) {
      return _buildVirtualQuestionsList(question);
    }
    
    return const Center(child: Text('Invalid question type'));
  }

  Widget _buildVirtualQuestionsList(Map<String, dynamic> virtualQuestion) {
    final partNumber = virtualQuestion['part_number'];
    final partDescription = virtualQuestion['part_description'] as String? ?? '';
    final allQuestions = virtualQuestion['all_questions'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (partDescription.isNotEmpty)
          Text(
            partDescription,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        const SizedBox(height: 20),
        
        ...allQuestions.map((question) {
          final questionId = question['question_id'] as int;
          final questionNumber = question['question_number'];
          final displayOrders = question['displayOrders'] as List? ?? [];
          final selectedAnswer = _selectedAnswers[questionId];
          
          if (partNumber == 2) {
            return _buildPart2QuestionCard(
              questionId: questionId,
              questionNumber: questionNumber,
              displayOrders: displayOrders,
              selectedAnswer: selectedAnswer,
            );
          }
          
          return _buildPart3QuestionCard(
            questionId: questionId,
            questionNumber: questionNumber,
            displayOrders: displayOrders,
            selectedAnswer: selectedAnswer,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPart2QuestionCard({
    required int questionId,
    required int questionNumber,
    required List displayOrders,
    String? selectedAnswer,
  }) {
    // Phân loại displayOrders
    final images = <String>[];
    final texts = <String>[];
    
    for (var display in displayOrders) {
      final contentType = (display['content_type'] as String? ?? '').toUpperCase();
      final contentPath = display['content_path'] as String?;
      final description = display['description'] as String? ?? '';
      
      if (contentType == 'IMAGE' && contentPath != null) {
        // Thêm S3 URL vào trước nếu chưa có
        String fullPath = contentPath.trim();
        if (!fullPath.startsWith('http')) {
          fullPath = S3_BASE_URL + fullPath;
        }
        images.add(fullPath);
      } else if (contentType == 'TEXT' && description.isNotEmpty) {
        texts.add(description);
      }
    }
    
    // TEXT đầu tiên là câu hỏi, các TEXT sau là đáp án
    String questionText = '';
    final answerOptions = <String>[];
    
    if (texts.isNotEmpty) {
      questionText = texts[0];
      for (int i = 1; i < texts.length; i++) {
        // Lấy text đáp án và loại bỏ dấu ngoặc nếu có
        String answer = texts[i].replaceAll('(', '').replaceAll(')', '').trim();
        if (answer.isNotEmpty) {
          answerOptions.add(answer);
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị số câu hỏi
          if (questionText.isNotEmpty)
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          const SizedBox(height: 12),
          
          // Hiển thị hình ảnh nếu có
          ...images.map((imagePath) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          )),
          
          Column(
            children: answerOptions.take(4).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
              final isSelected = selectedAnswer == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _selectAnswer(questionId, option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3DD598) : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF3DD598) : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              optionLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF2D3142),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPart3QuestionCard({
    required int questionId,
    required int questionNumber,
    required List displayOrders,
    String? selectedAnswer,
  }) {
    // Phân loại displayOrders
    final images = <String>[];
    final texts = <String>[];
    
    for (var display in displayOrders) {
      final contentType = (display['content_type'] as String? ?? '').toUpperCase();
      final contentPath = display['content_path'] as String?;
      final description = display['description'] as String? ?? '';
      
      if (contentType == 'IMAGE' && contentPath != null) {
        // Thêm S3 URL vào trước nếu chưa có
        String fullPath = contentPath.trim();
        if (!fullPath.startsWith('http')) {
          fullPath = S3_BASE_URL + fullPath;
        }
        images.add(fullPath);
      } else if (contentType == 'TEXT' && description.isNotEmpty) {
        texts.add(description);
      }
    }
    
    // TEXT đầu tiên là câu hỏi, các TEXT sau là đáp án
    String questionText = '';
    final answerOptions = <String>[];
    
    if (texts.isNotEmpty) {
      questionText = texts[0];
      for (int i = 1; i < texts.length; i++) {
        // Lấy text đáp án và loại bỏ dấu ngoặc nếu có
        String answer = texts[i].replaceAll('(', '').replaceAll(')', '').trim();
        if (answer.isNotEmpty) {
          answerOptions.add(answer);
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị câu hỏi
          if (questionText.isNotEmpty)
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          const SizedBox(height: 12),
          
          // Hiển thị hình ảnh nếu có
          ...images.map((imagePath) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          )),
          
          Column(
            children: answerOptions.take(4).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
              final isSelected = selectedAnswer == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _selectAnswer(questionId, option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3DD598) : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF3DD598) : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              optionLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF2D3142),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int questionId, String answer) {
    setState(() {
      _selectedAnswers[questionId] = answer;
    });
  }

  Widget _buildBottomBar() {
    if (_currentStep >= _allQuestions.length) return const SizedBox.shrink();
    
    final currentQuestion = _allQuestions[_currentStep];
    final isVirtual = currentQuestion['is_virtual'] == true;
    bool isEnabled = false;
    
    if (isVirtual) {
      final allQuestions = currentQuestion['all_questions'] as List? ?? [];
      // Check nếu tất cả câu hỏi đã được trả lời hoặc không có đáp án
      isEnabled = allQuestions.every((q) {
        final questionId = q['question_id'];
        // Kiểm tra xem câu hỏi có đáp án không
        final displayOrders = q['displayOrders'] as List? ?? [];
        final texts = <String>[];
        for (var display in displayOrders) {
          final contentType = (display['content_type'] as String? ?? '').toUpperCase();
          final description = display['description'] as String? ?? '';
          if (contentType == 'TEXT' && description.isNotEmpty) {
            texts.add(description);
          }
        }
        // Nếu có ít hơn 2 TEXT (không có đáp án), cho phép skip
        if (texts.length < 2) return true;
        // Nếu có đáp án, phải chọn mới cho phép
        return _selectedAnswers[questionId] != null;
      });
    } else {
      final questionId = currentQuestion['question_id'];
      isEnabled = _selectedAnswers[questionId] != null;
    }
    
    bool isLastQuestion = _currentStep == _allQuestions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: _previousStep,
              ),
            Expanded(
              child: ElevatedButton(
                onPressed: isEnabled ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD598),
                  disabledBackgroundColor: Colors.grey[300],
                  fixedSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isLastQuestion ? 'Submit' : 'Continue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteScreen() {
    if (_examResults == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3DD598)));
    }
    
    final totalScore = _examResults!['total_score'] ?? 0;
    final levelUpgraded = _examResults!['level_upgraded'] ?? false;
    final newLevel = _examResults!['new_level'] ?? '';
    final status = _examResults!['status'] ?? 'COMPLETED';
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon và title
            Icon(
              levelUpgraded ? Icons.emoji_events : Icons.check_circle,
              size: 100,
              color: levelUpgraded ? const Color(0xFFFFD700) : const Color(0xFF3DD598),
            ),
            const SizedBox(height: 24),
            Text(
              levelUpgraded ? 'Congratulations!' : 'Test Completed!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Total Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Score',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3DD598),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Level upgrade message
            if (levelUpgraded && newLevel.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Level Up!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You are now at level $newLevel',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 32,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep practicing to level up!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Back button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DD598),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back to Lessons',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLessonData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  }

