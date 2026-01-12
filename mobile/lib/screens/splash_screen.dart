import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'on1_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await AuthService.getToken();

    if (!mounted) return;

    // ✅ Có token → vào thẳng main
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    }
    // ❌ Không có token → flow bình thường
    else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const On1Screen(),
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
                    'assets/images/splash.png',
                    width: 180,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
