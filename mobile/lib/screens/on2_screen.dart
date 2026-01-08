import 'package:flutter/material.dart';
import 'package:mobile/screens/option_screen.dart';
import 'on3_screen.dart';
import 'package:mobile/widgets/dot_indicator.dart';

class On2Screen extends StatelessWidget {
  const On2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // Illustration
                      Image.asset(
                        'assets/images/on2.png',
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 60),
                      // Title
                      const Text(
                        'Embark on Your',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3DD598),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'Learning Adventure',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3DD598),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Description
                      const Text(
                        'Explore Interactive Lessons, Quizzes, And\nMultimedia Content To Enhance Your Understanding.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      // Pagination Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DotWidget(isActive: false),
                          const SizedBox(width: 8),
                          const DotWidget(isActive: true),
                          const SizedBox(width: 8),
                          const DotWidget(isActive: false),
                          const SizedBox(width: 8),
                          const DotWidget(isActive: false),         
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const On3Screen(),
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
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Skip Button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OptionScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
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
