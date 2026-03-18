// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../auth/login_page.dart';
// import '../auth/permission_screen.dart';
// import '../prefs/app_preference.dart';
// import '../prefs/preference_key.dart';
// import 'onboarding_screens.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//
//   @override
//   // void initState() {
//   //   super.initState();
//   //
//   //   /// ⏳ 5 SECONDS DELAY
//   //   Timer(const Duration(seconds: 5), () {
//   //     Navigator.pushReplacement(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => const OnboardingScreen(),
//   //       ),
//   //     );
//   //   });
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     _navigate();
//   }
//
//   void _navigate() {
//     Timer(const Duration(seconds: 5), () {
//
//       final bool isLoggedIn =
//       AppPreference().getBool(PreferencesKey.isLoggedIn);
//
//       if (isLoggedIn) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const LocationPermissionScreen(),
//           ),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const LoginScreen(),
//           ),
//         );
//       }
//
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black, // outer background
//       body: Center(
//         child: Container(
//           width: 375,
//           height: 750,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             image: const DecorationImage(
//               image: AssetImage('assets/images/Splash_screen.png'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               /// 🔹 LOGO
//               Image.asset(
//                 'assets/images/worker_logo.png',
//                 height: 220,
//                 width: 500,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../auth/permission_screen.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

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

    /// Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    /// Scale animation
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    /// Fade animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    /// Navigate after splash
    Timer(const Duration(seconds: 5), _navigate);
  }

  void _navigate() {
    final bool isLoggedIn =
    AppPreference().getBool(PreferencesKey.isLoggedIn);

    if (!mounted) return;

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