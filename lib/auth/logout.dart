import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/bottom_nav_bar.dart';
import 'login_page.dart';


// Future<void> logout(BuildContext context) async {
//   try {
//     final token = AppPreference().getString(PreferencesKey.token);
//
//     await ApiService.postRequest(
//       logoutUrl,
//       {},
//       options: Options(
//         headers: {
//           "Authorization": "Bearer $token",
//         },
//       ),
//     );
//
//     /// 🔐 CLEAR SHARED PREFERENCES
//     await AppPreference().clearSharedPreferences();
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Logged out successfully")),
//     );
//
//     /// 🔁 GO TO LOGIN SCREEN
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//           (_) => false,
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(e.toString())),
//     );
//   }
// }

Future<void> logout(BuildContext context, WidgetRef ref) async {
  try {
    final token = AppPreference().getString(PreferencesKey.token);

    await ApiService.postRequest(
      logoutUrl,
      {},
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );

    await AppPreference().clearSharedPreferences();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
    await Future.delayed(const Duration(milliseconds: 200));
    /// 🔥 RESET BOTTOM NAV INDEX
    ref.read(bottomNavIndexProvider.notifier).state = 0;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}



void showLogoutDialog(BuildContext context ,  WidgetRef ref) {
  final loc = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ICON
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFF6F7FF),
                child: Icon(
                  Icons.logout,
                  size: 28,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              /// TITLE
              Text(
                loc.logout,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              /// MESSAGE
              Text(
              loc.logoutConfirmMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                      },
                      child: Text(
                        loc.cancel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      // onPressed: () => logout(context),
                      onPressed: () async {
                        await AppPreference().clearSharedPreferences();

                        /// 🔥 RESET PROVIDER
                        ref.invalidate(bottomNavIndexProvider);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                              (_) => false,
                        );
                      },
                      child: Text(
                        loc.logout,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
