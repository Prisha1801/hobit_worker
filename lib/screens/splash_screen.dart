import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/fcm_service.dart';
import '../auth/login_page.dart';
import '../auth/permission_screen.dart';
import '../main.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/notification.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    _initServices();

    Timer(const Duration(seconds: 5), _navigate);
  }

  Future<void> _initServices() async {
    final isLoggedIn = AppPreference().getBool(PreferencesKey.isLoggedIn);
    await FCMService.init(isLoggedIn: isLoggedIn);
  }

  void _navigate() {
    if (!mounted) return;

    final bool isLoggedIn =
    AppPreference().getBool(PreferencesKey.isLoggedIn);

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LocationPermissionScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo3.png',
              height: 170,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
