import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class GrammarLessonScreen extends StatefulWidget {
  final String grammarTitle;
  final String grammarLevel;

  const GrammarLessonScreen({
    Key? key,
    required this.grammarTitle,
    required this.grammarLevel,
  }) : super(key: key);

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  int _currentStep = 0; // 0-3: Theory, 4: Test1, 5: Test2, 6: Test3, 7: Review
  int _learnedSteps = 0;
  bool _isReviewMode = false;
  int _reviewStep = 0;

  // Test answers
  String? _test1SelectedAnswer;
  String? _test2SelectedAnswer;
  String _test3Answer = '';

  // Test states
  bool _test1Checked = false;
  bool _test2Checked = false;
  bool _test3Checked = false;

  // Track test results for accuracy
  bool _test1Correct = false;
  bool _test2Correct = false;
  bool _test3Correct = false;

  final TextEditingController _test3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to TextField to update state when text changes
    _test3Controller.addListener(() {
      setState(() {
        // Just trigger rebuild to show/hide button
      });
    });
  }

  @override
  void dispose() {
    _test3Controller.dispose();
    super.dispose();
  }

  double get _progressValue {
    if (_isReviewMode) {
      return 0.0; // Review starts at 0%
    }
    // 7 total steps: 4 Theory + 3 Tests
    if (_currentStep == 0) return 0.0;       // Theory 1: 0%
    if (_currentStep == 1) return 1/7;    // Theory 2: 6.25%
    if (_currentStep == 2) return 2/7;     // Theory 3: 12.5%
    if (_currentStep == 3) return 3/7;    // Theory 4: 18.75%
    if (_currentStep == 4) return 4/7;      // Test 1: 25%
    if (_currentStep == 5) return 5/7;      // Test 2: 50%
    if (_currentStep == 6) return 6/7;      // Test 3: 75%
    if (_currentStep == 7) return 1.0;       // Complete: 100%
    return 0.75;
  }

  int get _accuracy {
    int correct = 0;
    if (_test1Correct) correct++;
    if (_test2Correct) correct++;
    if (_test3Correct) correct++;
    return ((correct / 3) * 100).round();
  }

  String get _stepText {
    if (_isReviewMode) {
      return 'Step 1 of 7';
    }
    if (_currentStep <= 3) {
      return 'Step ${_currentStep + 1} of 7';
    } else if (_currentStep == 4) {
      return 'Step 4 of 7';
    } else if (_currentStep == 5) {
      return 'Step 5 of 7';
    } else if (_currentStep == 6) {
      return 'Step 6 of 7';
    } else {
      return 'Step 7 of 7';
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep <= 2) {
        // Theory pages 1-3: just move forward
        _currentStep++;
      } else if (_currentStep == 3) {
        // Theory page 4 → Test 1
        _currentStep = 4;
        _learnedSteps = 1;
      } else if (_currentStep == 4) {
        // Test 1 → Test 2 (only if checked)
        if (_test1Checked) {
          _test1Correct = _isTest1Correct;
          _currentStep = 5;
          _learnedSteps = 2;
          _test1Checked = false;
          _test1SelectedAnswer = null;
        }
      } else if (_currentStep == 5) {
        // Test 2 → Test 3 (only if checked)
        if (_test2Checked) {
          _test2Correct = _isTest2Correct;
          _currentStep = 6;
          _learnedSteps = 3;
          _test2Checked = false;
          _test2SelectedAnswer = null;
        }
      } else if (_currentStep == 6) {
        // Test 3 → Complete (only if checked)
        if (_test3Checked) {
          _test3Correct = _isTest3Correct;
          _currentStep = 7;
          _learnedSteps = 4;
        }
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0 && !_isReviewMode) {
      setState(() {
        _currentStep--;

        // Reset test states when going back
        if (_currentStep == 4) {
          _test1Checked = false;
          _test1SelectedAnswer = null;
        } else if (_currentStep == 5) {
          _test2Checked = false;
          _test2SelectedAnswer = null;
        } else if (_currentStep == 6) {
          _test3Checked = false;
          _test3Answer = '';
          _test3Controller.clear();
        }
      });
    }
  }

  void _startReview() {
    setState(() {
      _isReviewMode = true;
      _reviewStep = 0;
      _currentStep = 0;
    });
  }

  void _nextReviewStep() {
    if (_reviewStep < 6) { // 0-6 = 7 pages (4 theory + 3 tests)
      setState(() {
        _reviewStep++;
      });
    } else {
      // Finish review
      Navigator.pop(context);
    }
  }

  void _previousReviewStep() {
    if (_reviewStep > 0) {
      setState(() {
        _reviewStep--;
      });
    }
  }

  void _checkTest1Answer() {
    setState(() {
      _test1Checked = true;
    });
  }

  void _checkTest2Answer() {
    setState(() {
      _test2Checked = true;
    });
  }

  void _checkTest3Answer() {
    setState(() {
      _test3Answer = _test3Controller.text.trim();
      _test3Checked = true;
    });
  }

  bool get _isTest1Correct => _test1SelectedAnswer == 'C'; // goes is correct
  bool get _isTest2Correct => _test2SelectedAnswer == 'B'; // play is correct
  bool get _isTest3Correct => _test3Answer.toLowerCase() == 'watch';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Progress
            _buildProgress(),

            // Content
            Expanded(
              child: _buildContent(),
            ),

            // Navigation buttons
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
              _currentStep == 7 ? 'Lesson Complete!' : widget.grammarTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          if (_currentStep < 7) ...[
            IconButton(
              icon: const Icon(Icons.access_time, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              onPressed: () {},
            ),
          ],
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
          // Progress title + %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isReviewMode ? 'Review Progress' : 'Progress',
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

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF3DD598)),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 8),

          // Step text + learned text (same row)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _stepText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _isReviewMode ? 'All learned' : '$_learnedSteps learned',
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
    );
  }


  Widget _buildContent() {
    if (_isReviewMode) {
      // Review mode: 7 pages (4 theory + 3 test results)
      if (_reviewStep < 4) {
        return _buildTheoryPage(_reviewStep);
      } else if (_reviewStep == 4) {
        return _buildTest1Result();
      } else if (_reviewStep == 5) {
        return _buildTest2Result();
      } else {
        return _buildTest3Result();
      }
    } else if (_currentStep < 4) {
      return _buildTheoryPage(_currentStep);
    } else if (_currentStep == 4) {
      return _buildTest1();
    } else if (_currentStep == 5) {
      return _buildTest2();
    } else if (_currentStep == 6) {
      return _buildTest3();
    } else {
      return _buildCompleteScreen();
    }
  }

  Widget _buildTheoryPage(int pageIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            // Title
            const Text(
              'Present Simple',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thì hiện tại đơn',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            if (pageIndex == 0) _buildTheoryPage1(),
            if (pageIndex == 1) _buildTheoryPage2(),
            if (pageIndex == 2) _buildTheoryPage3(),
            if (pageIndex == 3) _buildTheoryPage4(),

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoryPage1() {
    return Column(
      children: [
        // Green box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Diễn tả thói quen, hành động lặp đi lặp lại ở hiện tại'),
              const SizedBox(height: 8),
              _buildBulletPoint('Diễn tả sự thật hiển nhiên, chân lý'),
              const SizedBox(height: 8),
              _buildBulletPoint('Lịch trình, thời gian biểu có cố định'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Yellow box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFE082),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFFFA000),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DẤU HIỆU NHẬN BIẾT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFA000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'always, usually, often, sometimes, rarely, never, every day/week/month',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTheoryPage2() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Khẳng định',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DD598),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'CÔNG THỨC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'S + V(s/es)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CHI TIẾT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: 'I/You/We/They: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '+ V (nguyên thể)\n'),
                TextSpan(
                  text: 'He/She/It: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '+ V(s/es)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'VÍ DỤ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('I work every day'),
          const SizedBox(height: 6),
          _buildBulletPoint('She works at a bank'),
          const SizedBox(height: 6),
          _buildBulletPoint('They play football'),
        ],
      ),
    );
  }

  Widget _buildTheoryPage3() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nghi vấn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DD598),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'CÔNG THỨC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do/Does + S + V?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CHI TIẾT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: 'Yes/No: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: 'Do/Does + S + V?\n'),
                TextSpan(
                  text: 'Wh-: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: 'Wh- + do/does + S + V?'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'VÍ DỤ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('Do you work here?'),
          const SizedBox(height: 6),
          _buildBulletPoint('Does she like music?'),
          const SizedBox(height: 6),
          _buildBulletPoint('Do they play games?'),
        ],
      ),
    );
  }

  Widget _buildTheoryPage4() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phủ định',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DD598),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'CÔNG THỨC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'S + do/does + not + V',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CHI TIẾT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: 'I/You/We/They: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '+ don\'t + V\n'),
                TextSpan(
                  text: 'He/She/It: ',
                  style: TextStyle(
                    color: Color(0xFF3DD598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '+ doesn\'t + V'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'VÍ DỤ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('I don\'t work on Sunday'),
          const SizedBox(height: 6),
          _buildBulletPoint('She doesn\'t like coffee'),
          const SizedBox(height: 6),
          _buildBulletPoint('They don\'t play tennis'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF3DD598),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTest1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập trắc nghiệm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'She _____ to school every day.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMultipleChoiceOption('A', 'go', _test1SelectedAnswer, !_test1Checked, (value) {
              if (!_test1Checked) {
                setState(() => _test1SelectedAnswer = value);
              }
            }, _test1Checked && _test1SelectedAnswer == 'A' ? false : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('B', 'going', _test1SelectedAnswer, !_test1Checked, (value) {
              if (!_test1Checked) {
                setState(() => _test1SelectedAnswer = value);
              }
            }, _test1Checked && _test1SelectedAnswer == 'B' ? false : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('C', 'goes', _test1SelectedAnswer, !_test1Checked, (value) {
              if (!_test1Checked) {
                setState(() => _test1SelectedAnswer = value);
              }
            }, _test1Checked && _test1SelectedAnswer == 'C' ? true : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('D', 'gone', _test1SelectedAnswer, !_test1Checked, (value) {
              if (!_test1Checked) {
                setState(() => _test1SelectedAnswer = value);
              }
            }, _test1Checked && _test1SelectedAnswer == 'D' ? false : null),

            if (_test1Checked) ...[
              const SizedBox(height: 24),
              _buildExplanation(
                _isTest1Correct
                    ? 'Đáp án đúng: goes\nWe use "goes" with third person singular (he/she/it) in Present Simple tense.'
                    : 'Sai rồi!\nĐáp án đã chọn: ${_getAnswerText(_test1SelectedAnswer!)}\nWe use "goes" with third person singular (he/she/it) in Present Simple tense.',
                isCorrect: _isTest1Correct,
              ),
            ],

            if (!_test1Checked && _test1SelectedAnswer != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _checkTest1Answer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAnswerText(String option) {
    if (_currentStep == 4) {
      // Test 1
      if (option == 'A') return 'go';
      if (option == 'B') return 'going';
      if (option == 'C') return 'goes';
      if (option == 'D') return 'gone';
    } else if (_currentStep == 5) {
      // Test 2
      if (option == 'A') return 'plays';
      if (option == 'B') return 'play';
      if (option == 'C') return 'playing';
      if (option == 'D') return 'played';
    }
    return '';
  }

  Widget _buildTest2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập trắc nghiệm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'They _____ football on weekends.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMultipleChoiceOption('A', 'plays', _test2SelectedAnswer, !_test2Checked, (value) {
              if (!_test2Checked) {
                setState(() => _test2SelectedAnswer = value);
              }
            }, _test2Checked && _test2SelectedAnswer == 'A' ? false : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('B', 'play', _test2SelectedAnswer, !_test2Checked, (value) {
              if (!_test2Checked) {
                setState(() => _test2SelectedAnswer = value);
              }
            }, _test2Checked && _test2SelectedAnswer == 'B' ? true : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('C', 'playing', _test2SelectedAnswer, !_test2Checked, (value) {
              if (!_test2Checked) {
                setState(() => _test2SelectedAnswer = value);
              }
            }, _test2Checked && _test2SelectedAnswer == 'C' ? false : null),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('D', 'played', _test2SelectedAnswer, !_test2Checked, (value) {
              if (!_test2Checked) {
                setState(() => _test2SelectedAnswer = value);
              }
            }, _test2Checked && _test2SelectedAnswer == 'D' ? false : null),

            if (_test2Checked) ...[
              const SizedBox(height: 24),
              _buildExplanation(
                _isTest2Correct
                    ? 'Chính xác!\nĐáp án đúng: play\nUse base form(play) with I/you/we/they in Present Simple tense.'
                    : 'Sai rồi!\nĐáp án đã chọn: ${_getAnswerText(_test2SelectedAnswer!)}\nUse base form(play) with I/you/we/they in Present Simple tense.',
                isCorrect: _isTest2Correct,
              ),
            ],

            if (!_test2Checked && _test2SelectedAnswer != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _checkTest2Answer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTest3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập điền từ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chia động từ trong ngoặc:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'I _____ (watch) TV every evening.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _test3Controller,
              enabled: !_test3Checked,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            if (!_test3Checked && _test3Controller.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _checkTest3Answer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            if (_test3Checked) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isTest3Correct
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTest3Correct
                        ? const Color(0xFF3DD598)
                        : const Color(0xFFEF5350),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isTest3Correct ? Icons.check_circle : Icons.cancel,
                      color: _isTest3Correct
                          ? const Color(0xFF3DD598)
                          : const Color(0xFFEF5350),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTest3Correct ? 'Chính xác!' : 'Sai rồi!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isTest3Correct
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isTest3Correct
                                ? 'Đáp án đúng: watch'
                                : 'Đáp án đúng: watch\nUse base form with I/you/we/they',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOption(
      String label,
      String text,
      String? selectedAnswer,
      bool enabled,
      Function(String) onTap,
      bool? isCorrect,
      ) {
    final isSelected = selectedAnswer == label;
    Color backgroundColor;
    Color borderColor;
    Color textColor = Colors.black;

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
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect == true
                    ? const Color(0xFF3DD598)
                    : isCorrect == false
                    ? const Color(0xFFEF5350)
                    : isSelected
                    ? const Color(0xFF3DD598)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCorrect == true
                      ? const Color(0xFF3DD598)
                      : isCorrect == false
                      ? const Color(0xFFEF5350)
                      : isSelected
                      ? const Color(0xFF3DD598)
                      : const Color(0xFF9E9E9E),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected || isCorrect != null ? Colors.white : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(String text, {bool isCorrect = true}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFF2196F3) : const Color(0xFFEF5350),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.info_outline : Icons.cancel_outlined,
            color: isCorrect ? const Color(0xFF1976D2) : const Color(0xFFC62828),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Giải thích' : 'Sai rồi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? const Color(0xFF1976D2) : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTest1Result() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập trắc nghiệm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'She _____ to school every day.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMultipleChoiceOption('A', 'go', null, false, (_) {}, false),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('B', 'going', null, false, (_) {}, false),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('C', 'goes', null, false, (_) {}, true),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('D', 'gone', null, false, (_) {}, false),

            const SizedBox(height: 24),
            _buildExplanation(
              _test1Correct
                  ? 'Chính xác!\nĐáp án đúng: goes\nWe use "goes" with third person singular (he/she/it) in Present Simple tense.'
                  : 'Sai rồi!\nĐáp án đúng: goes\nWe use "goes" with third person singular (he/she/it) in Present Simple tense.',
              isCorrect: _test1Correct,
            ),

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTest2Result() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập trắc nghiệm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'They _____ football on weekends.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMultipleChoiceOption('A', 'plays', null, false, (_) {}, false),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('B', 'play', null, false, (_) {}, true),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('C', 'playing', null, false, (_) {}, false),
            const SizedBox(height: 12),
            _buildMultipleChoiceOption('D', 'played', null, false, (_) {}, false),

            const SizedBox(height: 24),
            _buildExplanation(
              _test2Correct
                  ? 'Chính xác!\nĐáp án đúng: play\nUse base form with I/you/we/they'
                  : 'Sai rồi!\nĐáp án đúng: play\nUse base form with I/you/we/they',
              isCorrect: _test2Correct,
            ),

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTest3Result() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'Bài tập điền từ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chia động từ trong ngoặc:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'I _____ (watch) TV every evening.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'watch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _test3Correct
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _test3Correct
                      ? const Color(0xFF3DD598)
                      : const Color(0xFFEF5350),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _test3Correct ? Icons.check_circle : Icons.cancel,
                    color: _test3Correct
                        ? const Color(0xFF3DD598)
                        : const Color(0xFFEF5350),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _test3Correct ? 'Chính xác!' : 'Sai rồi!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _test3Correct
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _test3Correct
                              ? 'Đáp án đúng: watch'
                              : 'Đáp án đúng: watch\nUse base form with I/you/we/they',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF3DD598),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          // Congratulations text
          const Text(
            'Congratulations!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve completed the ${widget.grammarTitle}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Stats card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      '7',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3DD598),
                      ),
                    ),
                    Text(
                      'Steps Learned',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      '$_accuracy%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Accuracy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Next Lesson card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Lesson',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Past Simple Tense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '10 steps to learn',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DD598),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    // Complete screen - show Review and Continue buttons
    if (_currentStep == 7 && !_isReviewMode) {
      return Container(
        padding: const EdgeInsets.all(20.0),
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
                child: OutlinedButton.icon(
                  onPressed: _startReview,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'Review Lesson',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text(
                    'Continue Learning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Review mode - show Finish Review button
    if (_isReviewMode) {
      return Container(
        padding: const EdgeInsets.all(20.0),
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
            if (_reviewStep > 0)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: _previousReviewStep,
                ),
              ),
            if (_reviewStep > 0) const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'Finish Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD598),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: _nextReviewStep,
              ),
            ),
          ],
        ),
      );
    }

    // Normal lesson mode
    bool canGoNext = false;

    if (_currentStep <= 3) {
      // Theory pages - always can continue
      canGoNext = true;
    } else if (_currentStep == 4) {
      // Test 1 - need to check answer
      canGoNext = _test1Checked;
    } else if (_currentStep == 5) {
      // Test 2 - need to check answer
      canGoNext = _test2Checked;
    } else if (_currentStep == 6) {
      // Test 3 - need to check answer
      canGoNext = _test3Checked;
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
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
          if (_currentStep > 0)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canGoNext ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD598),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: canGoNext ? _nextStep : null,
            ),
          ),
        ],
      ),
    );
  }
}