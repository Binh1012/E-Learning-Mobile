import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/auth_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../auth/option_screen.dart';
import '../onboarding/on1_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Giữ splash 2–3 giây cho đẹp
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final token = await AuthService.getStoredToken();

    if (token != null && token.isNotEmpty) {
      // ✅ Đã đăng nhập → vào app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } else {
      // ❌ Chưa đăng nhập → Option / Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const On1Screen(),
          // hoặc: const On1Screen()
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        size: 100,
                        color: Color(0xFF3DD598),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'e-Learning',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3DD598),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
