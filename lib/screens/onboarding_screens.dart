import 'package:flutter/material.dart';
import 'package:hobit_worker/colors/appcolors.dart';

import '../auth/permission_screen.dart';
import '../auth/login_page.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  //
  // final List<Map<String, String>> onboardingData = [
  //   {"image": "assets/images/onboard.png", "title": "We are here for you!"},
  //   {"image": "assets/images/onboard.png", "title": "All services at one tap"},
  //   {
  //     "image": "assets/images/onboard.png",
  //     "title": "Trusted professionals nearby",
  //   },
  // ];
  late List<Map<String, String>> onboardingData;





  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    onboardingData = [
      {"image": "assets/images/onboard.png", "title": loc.onboardTitle1},
      {"image": "assets/images/onboard.png", "title": loc.onboardTitle2},
      {"image": "assets/images/onboard.png", "title": loc.onboardTitle3},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// 🔹 ONBOARDING PAGES
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    /// IMAGE WITH ROUNDED BOTTOM
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                      child: Image.asset(
                        onboardingData[index]["image"]!,
                        height: 550,
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// TITLE
                    Text(
                      onboardingData[index]["title"]!,
                      style: TextStyle(
                        fontSize: 20,
                        color: kBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          /// 🔹 DOT INDICATOR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => buildDot(index),
            ),
          ),

          const SizedBox(height: 24),

          /// 🔹 GET STARTED BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kkblack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () {
                  if (currentIndex < onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    final bool isLoggedIn = AppPreference().getBool(
                      PreferencesKey.isLoggedIn,
                    );

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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  }
                },

                // {
                //   if (currentIndex < onboardingData.length - 1) {
                //     _pageController.nextPage(
                //       duration: const Duration(milliseconds: 300),
                //       curve: Curves.easeInOut,
                //     );
                //   } else {
                //     // Navigate to the next screen after onboarding
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => const LoginScreen(),
                //       ),
                //     );
                //   }
                // },
                child: Text(
                  loc.getStarted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 🔹 DOT WIDGET
  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: currentIndex == index ? 20 : 8,
      decoration: BoxDecoration(
        color: currentIndex == index ? kkblack : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
