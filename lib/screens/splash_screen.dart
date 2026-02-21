// import 'dart:async';
// import 'package:flutter/material.dart';
//
// import 'onboarding_screens.dart';
//
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
//   void initState() {
//     super.initState();
//
//     /// ⏳ 5 SECONDS DELAY
//     Timer(const Duration(seconds: 5), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const OnboardingScreen(),
//         ),
//       );
//     });
//   }
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
//                 'assets/images/logo2.png',
//                 height: 90,
//                 width: 313,
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
import 'package:geolocator/geolocator.dart';
import 'onboarding_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {

    await Future.delayed(const Duration(seconds: 2));

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      /// 🔥 Directly open Location Settings
      await Geolocator.openLocationSettings();

      /// 🔁 Wait and re-check
      _checkLocation();
      return;
    }

    /// Permission check
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    /// ✅ All good → go next
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/Splash_screen.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
