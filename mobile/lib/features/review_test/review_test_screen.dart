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
  // --- BIẾN TRẠNG THÁI ---
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _allQuestions = [];
  
  int _currentStep = 0;
  int _learnedSteps = 0;
  
  Map<int, String> _selectedAnswers = {}; // questionId -> selected answer (A/B/C/D)
  Map<int, List<String>> _partAnswers = {}; // partId -> ["A", "B", "C", ...]
  Map<int, dynamic> _submissionResults = {};
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _audioUrl; // Lưu URL audio để phát liên tục

  @override
  void initState() {
    super.initState();
    _loadLessonData();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- SETUP AUDIO PLAYER ---
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

  Future<void> _playPauseAudio(String audioUrl) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position == Duration.zero) {
        await _audioPlayer.play(UrlSource(audioUrl));
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

  // --- LOGIC TẢI DỮ LIỆU (CHỈ 1 API CALL) ---
  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // CHỈ GỌI 1 API DUY NHẤT
      final lessonData = await ReviewTestApiService.getLessonData(lessonId: widget.lessonId);
      final data = lessonData['data'] as Map<String, dynamic>;
      
      // Parse parts từ response
      final parts = data['parts'] as List? ?? [];
      _parts = parts.map((p) => p as Map<String, dynamic>).toList();

      final allQuestions = <Map<String, dynamic>>[];
      String? audioUrlFound;
      
      // Duyệt qua từng part
      for (var part in _parts) {
        final partId = part['part_id'];
        final partNumber = part['part_number'];
        final partDescription = part['description'] as String? ?? '';
        final questions = part['questions'] as List? ?? [];
        
        print('📦 Processing part $partNumber: $partDescription (${questions.length} questions)');
        
        // Tìm audio URL từ bất kỳ part nào có AUDIO
        if (questions.isNotEmpty) {
          for (var question in questions) {
            final displayOrders = question['displayOrders'] as List? ?? [];
            for (var display in displayOrders) {
              final contentType = (display['content_type'] as String? ?? '').toUpperCase();
              if (contentType == 'AUDIO' && display['content_path'] != null) {
                audioUrlFound = display['content_path'];
                print('🎵 Found audio: $audioUrlFound');
                break;
              }
            }
            if (audioUrlFound != null) break;
          }
        }
        
        // Xử lý questions - BỎ QUA part chỉ có audio
        final descUpper = partDescription.toUpperCase();
        if (descUpper.contains('AUDIO') || descUpper.contains('MAIN AUDIO FILE')) {
          print('⏭️ Skipping audio-only part');
          continue;
        }
        
        // Thêm questions vào list
        for (var question in questions) {
          final questionWithPart = Map<String, dynamic>.from(question);
          questionWithPart['part_id'] = partId;
          questionWithPart['part_number'] = partNumber;
          questionWithPart['part_description'] = partDescription;
          allQuestions.add(questionWithPart);
        }
      }

      print('✅ Loaded ${allQuestions.length} questions from ${_parts.length} parts');
      print('🎵 Audio URL: ${audioUrlFound ?? "No audio"}');

      setState(() {
        _allQuestions = allQuestions;
        _audioUrl = audioUrlFound;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading lesson data: $e');
      setState(() {
        _loadError = 'Error: $e';
        _isLoading = false;
      });
    }
  }


  // --- LOGIC ĐIỀU HƯỚNG & XỬ LÝ ĐIỂM SỐ ---
  double get _progressValue => _allQuestions.isEmpty ? 0.0 : _currentStep / _allQuestions.length;

  void _nextStep() async {
    final currentQuestion = _allQuestions[_currentStep];
    final isVirtual = currentQuestion['is_virtual'] == true;
    
    if (isVirtual) {
      // Nếu là virtual question, skip hết đến question tiếp theo không phải virtual
      final partId = currentQuestion['part_id'];
      int nextIndex = _currentStep + 1;
      
      // Tìm question tiếp theo không cùng part hoặc không phải virtual
      while (nextIndex < _allQuestions.length) {
        final nextQ = _allQuestions[nextIndex];
        if (nextQ['part_id'] != partId || nextQ['is_virtual'] != true) {
          break;
        }
        nextIndex++;
      }
      
      if (nextIndex < _allQuestions.length) {
        setState(() {
          _currentStep = nextIndex;
          _learnedSteps = nextIndex;
        });
      } else {
        // Hết câu hỏi, submit
        await _audioPlayer.stop();
        setState(() {
          _isSubmitting = true;
          _currentStep = _allQuestions.length;
        });
        await _submitAllPartAnswers();
      }
    } else {
      // Question bình thường
      if (_currentStep < _allQuestions.length - 1) {
        setState(() {
          _currentStep++;
          _learnedSteps = _currentStep;
        });
      } else {
        await _audioPlayer.stop();
        setState(() {
          _isSubmitting = true;
          _currentStep = _allQuestions.length;
        });
        await _submitAllPartAnswers();
      }
    }
  }

  void _previousStep() async {
    final currentQuestion = _allQuestions[_currentStep];
    final isVirtual = currentQuestion['is_virtual'] == true;
    
    if (isVirtual) {
      // Nếu là virtual question, quay về question trước đó không phải virtual trong cùng group
      final partId = currentQuestion['part_id'];
      int prevIndex = _currentStep - 1;
      
      // Tìm question đầu tiên của group virtual này
      while (prevIndex >= 0) {
        final prevQ = _allQuestions[prevIndex];
        if (prevQ['part_id'] != partId || prevQ['is_virtual'] != true) {
          break;
        }
        prevIndex--;
      }
      
      // prevIndex giờ đang ở question trước group virtual
      if (prevIndex >= 0) {
        setState(() {
          _currentStep = prevIndex;
        });
      }
    } else {
      // Question bình thường
      if (_currentStep > 0) {
        setState(() {
          _currentStep--;
        });
      }
    }
  }

  Future<void> _submitAllPartAnswers() async {
    try {
      for (var partId in _partAnswers.keys) {
        final answers = _partAnswers[partId]!.join('');
        if (answers.isNotEmpty) {
          final result = await ReviewTestApiService.submitPartAnswers(
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

  void _selectAnswer(int questionId, String answer) {
    final question = _allQuestions.firstWhere((q) => q['question_id'] == questionId);
    final partId = question['part_id'];
    
    // Lưu đáp án đã chọn
    setState(() {
      _selectedAnswers[questionId] = answer;
    });

    // Cập nhật _partAnswers để nộp bài
    final questionsInPart = _allQuestions.where((q) => 
      q['part_id'] == partId && q['part_description'] == 'Question'
    ).toList();
    final questionIndex = questionsInPart.indexWhere((q) => q['question_id'] == questionId);
    
    if (questionIndex >= 0) {
      if (!_partAnswers.containsKey(partId)) {
        _partAnswers[partId] = List.filled(questionsInPart.length, '');
      }
      _partAnswers[partId]![questionIndex] = answer;
    }
  }

  // --- CẤU TRÚC UI CHÍNH ---
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
        // Sticky Audio Player (thay thế progress bar)
        if (_audioUrl != null) _buildStickyAudioPlayer(),
        
        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildCurrentContent(),
          ),
        ),
        // Bottom navigation bar
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildCurrentContent() {
    final currentQuestion = _allQuestions[_currentStep];
    return _buildQuestionContent(currentQuestion);
  }

  // --- BUILD STICKY AUDIO PLAYER ---
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
          // Play/Pause button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _playPauseAudio(_audioUrl!),
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
          
          // Time display
          Text(
            _formatDuration(_position),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Progress slider
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
          
          // Duration
          Text(
            _formatDuration(_duration),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Volume/More button
          Icon(
            Icons.volume_up,
            size: 20,
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }

  // --- BUILD QUESTION CONTENT (Question with images) ---
  Widget _buildQuestionContent(Map<String, dynamic> question) {
    final questionId = question['question_id'];
    final questionNumber = question['question_number'];
    final displayOrders = question['displayOrders'] as List? ?? [];
    final selectedAnswer = _selectedAnswers[questionId];
    final isVirtual = question['is_virtual'] == true;

    // Nếu là virtual question, hiển thị UI list
    if (isVirtual) {
      return _buildVirtualQuestionsList();
    }

    // Question bình thường với hình ảnh
    // Tìm các hình ảnh
    List<String> imageUrls = [];
    for (var display in displayOrders) {
      if (display['content_type'] == 'image' && display['content_path'] != null) {
        imageUrls.add(display['content_path']);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number
        Text(
          'Question $questionNumber',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 20),
        
        // Display images
        if (imageUrls.isNotEmpty)
          ...imageUrls.map((url) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          )).toList(),
        
        const SizedBox(height: 24),
        
        // Answer options (A, B, C, D)
        const Text(
          'Choose your answer:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 16),
        
        _buildAnswerOption('A', selectedAnswer),
        _buildAnswerOption('B', selectedAnswer),
        _buildAnswerOption('C', selectedAnswer),
        _buildAnswerOption('D', selectedAnswer),
      ],
    );
  }

  // --- BUILD VIRTUAL QUESTIONS LIST ---
  Widget _buildVirtualQuestionsList() {
    // Lấy tất cả virtual questions từ cùng part
    final currentQuestion = _allQuestions[_currentStep];
    final partId = currentQuestion['part_id'];
    
    final virtualQuestions = _allQuestions
        .where((q) => q['part_id'] == partId && q['is_virtual'] == true)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 20),
        
        // List tất cả câu hỏi
        ...virtualQuestions.map((q) {
          final qId = q['question_id'];
          final qNumber = q['question_number'];
          final selectedAnswer = _selectedAnswers[qId];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question label
                Text(
                  'Câu $qNumber:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Answer options trong 1 row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['A', 'B', 'C', 'D'].map((option) {
                    final isSelected = selectedAnswer == option;
                    return GestureDetector(
                      onTap: () => _selectAnswer(qId, option),
                      child: Container(
                        width: 60,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3DD598) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3DD598) : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAnswerOption(String label, String? selectedAnswer) {
    final isSelected = selectedAnswer == label;
    final questionId = _allQuestions[_currentStep]['question_id'];

    return GestureDetector(
      onTap: () => _selectAnswer(questionId, label),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF3DD598) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isSelected ? const Color(0xFF3DD598) : Colors.grey[200],
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF3DD598) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÀN HÌNH HOÀN THÀNH ---
  Widget _buildCompleteScreen() {
    if (_isSubmitting) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3DD598)),
      );
    }

    int totalScore = 0;
    _submissionResults.forEach((id, data) {
      if (data != null && data['score'] != null) {
        totalScore += int.parse(data['score'].toString());
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Color(0xFF3DD598),
            ),
            const SizedBox(height: 24),
            const Text(
              'Listening Test Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Score: $totalScore',
              style: const TextStyle(
                fontSize: 32,
                color: Color(0xFF3DD598),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 40),
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

  // --- THANH ĐIỀU HƯỚNG DƯỚI CÙNG ---
  Widget _buildBottomBar() {
    if (_currentStep >= _allQuestions.length) return const SizedBox.shrink();
    
    final currentQuestion = _allQuestions[_currentStep];
    final isVirtual = currentQuestion['is_virtual'] == true;
    
    bool isEnabled = false;
    
    if (isVirtual) {
      // Nếu là virtual, check tất cả questions trong group đã chọn đáp án chưa
      final partId = currentQuestion['part_id'];
      final virtualQuestions = _allQuestions
          .where((q) => q['part_id'] == partId && q['is_virtual'] == true)
          .toList();
      
      isEnabled = virtualQuestions.every((q) => _selectedAnswers[q['question_id']] != null);
    } else {
      // Question bình thường
      final questionId = currentQuestion['question_id'];
      isEnabled = _selectedAnswers[questionId] != null;
    }
    
    // Check xem có phải câu cuối không
    bool isLastQuestion = false;
    if (isVirtual) {
      final partId = currentQuestion['part_id'];
      // Tìm xem có question nào sau group virtual này không
      int nextIndex = _currentStep + 1;
      while (nextIndex < _allQuestions.length) {
        final nextQ = _allQuestions[nextIndex];
        if (nextQ['part_id'] != partId || nextQ['is_virtual'] != true) {
          break;
        }
        nextIndex++;
      }
      isLastQuestion = nextIndex >= _allQuestions.length;
    } else {
      isLastQuestion = _currentStep == _allQuestions.length - 1;
    }

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
            if (_currentStep > 0 || (isVirtual && _currentStep > 0))
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

  // --- HÀM BỔ TRỢ ---
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