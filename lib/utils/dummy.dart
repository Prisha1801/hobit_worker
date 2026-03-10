// import 'package:flutter/material.dart';
// import 'package:hobit_worker/auth/signup_page.dart';
// import 'package:hobit_worker/colors/appcolors.dart';
// import '../api_services/api_services.dart';
// import '../l10n/app_localizations.dart';
// import 'otp_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   bool keepSignedIn = true;
//   bool isLoading = false;
//
//
//   Future<void> sendOtp() async {
//     final loc = AppLocalizations.of(context)!;
//     final phone = _phoneController.text.trim();
//
//     if (phone.length != 10) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(loc.invalidPhone)),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final res = await ApiService.postRequest(
//         "/api/worker/login/send-otp",
//         {
//           "phone": phone,
//         },
//       );
//
//       final data = res.data;
//
//       if (data != null && data["status"] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data["message"] ?? loc.otpSent)),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => OtpVerificationScreen(phone: phone),
//           ),
//         );
//       }
//     }  catch (e) {
//       String message = loc.somethingWentWrong;
//       if (e is ApiException) {
//         message = e.message;
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message ,   textAlign: TextAlign.center, )),
//       );
//     }
//     finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;
//     return Scaffold(
//       backgroundColor: Colors.white,
//
//       /// 🔹 APP BAR (NO BACK BUTTON)
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: false, // ✅ removes back button
//       ),
//
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 32),
//
//             /// TITLE
//             Center(
//               child: Text(
//                 loc.login,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// PHONE LABEL
//             Text(
//               loc.phoneNumber,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             /// PHONE INPUT
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   const Text("+91", style: TextStyle(fontSize: 14)),
//                   const SizedBox(width: 6),
//                   const Text("|", style: TextStyle(color: Colors.grey)),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: TextField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10,
//                       decoration: InputDecoration(
//                         counterText: "",
//                         border: InputBorder.none,
//                         hintText: loc.enterPhone,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             /// 🔹 BLACK CHECKBOX
//             Row(
//               children: [
//                 Checkbox(
//                   value: keepSignedIn,
//                   activeColor: Colors.black,
//                   checkColor: Colors.white,
//                   side: const BorderSide(
//                     color: Colors.black,
//                     width: 1.5,
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       keepSignedIn = value!;
//                     });
//                   },
//                 ),
//                 Text(
//                   loc.keepSignedIn,
//                   style: const TextStyle(fontSize: 14, color: Colors.black),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             /// LOGIN BUTTON
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kkblack,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onPressed: isLoading ? null : sendOtp,
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                   loc.sendOtp,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             /// SIGN UP LINK
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(loc.dontHaveAccount),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const SignupScreen(),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     loc.signUpHere,
//                     style: const TextStyle(
//                       color: Colors.black, // black & white theme
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
// Future<void> logout(BuildContext context, WidgetRef ref) async {
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
//     await AppPreference().clearSharedPreferences();
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Logged out successfully")),
//     );
//     await Future.delayed(const Duration(milliseconds: 200));
//     /// 🔥 RESET BOTTOM NAV INDEX
//     ref.read(bottomNavIndexProvider.notifier).state = 0;
//
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
//
//
//
// void showLogoutDialog(BuildContext context ,  WidgetRef ref) {
//   final loc = AppLocalizations.of(context)!;
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return Dialog(
//         backgroundColor: kWhite,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               /// ICON
//               const CircleAvatar(
//                 radius: 28,
//                 backgroundColor: Color(0xFFF6F7FF),
//                 child: Icon(
//                   Icons.logout,
//                   size: 28,
//                   color: Colors.black,
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               /// TITLE
//               Text(
//                 loc.logout,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               /// MESSAGE
//               Text(
//                 loc.logoutConfirmMessage,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Colors.black54,
//                   height: 1.4,
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               /// BUTTONS
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: Colors.black),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context); // close dialog
//                       },
//                       child: Text(
//                         loc.cancel,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                       // onPressed: () => logout(context),
//                       onPressed: () async {
//                         await AppPreference().clearSharedPreferences();
//
//                         /// 🔥 RESET PROVIDER
//                         ref.invalidate(bottomNavIndexProvider);
//
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LoginScreen(),
//                           ),
//                               (_) => false,
//                         );
//                       },
//                       child: Text(
//                         loc.logout,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
//
//
//
//
// import 'package:hobit_worker/prefs/preference_key.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AppPreference {
//   static final AppPreference _appPreference = AppPreference._internal();
//
//   factory AppPreference() {
//     return _appPreference;
//   }
//
//   AppPreference._internal();
//
//   SharedPreferences? _preferences;
//
//   Future<void> initialAppPreference() async {
//     _preferences = await SharedPreferences.getInstance();
//   }
//
//   Future setString(String key, String value) async {
//     await _preferences?.setString(key, value);
//   }
//
//   String getString(String key, {String defValue = ''}) {
//     return _preferences?.getString(key) != null
//         ? (_preferences?.getString(key) ?? '')
//         : defValue;
//   }
//
//   Future setInt(String key, int value) async {
//     await _preferences?.setInt(key, value);
//   }
//
//   int getInt(String key, {int defValue = 0}) {
//     return _preferences?.getInt(key) != null
//         ? (_preferences?.getInt(key) ?? 0)
//         : defValue;
//   }
//
//   Future setBool(String key, bool value) async {
//     await _preferences?.setBool(key, value);
//   }
//
//   bool getBool(String key, {bool defValue = false}) {
//     return _preferences?.getBool(key) ?? defValue;
//   }
//
//   Future<void> clearSharedPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     print("✅ SharedPreferences cleared");
//   }
//
//   Future<void> remove(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(key);
//   }
//
//   String get uName => getString(PreferencesKey.userId);
// }
//
//
// class PreferencesKey {
//   static String userId = "userId";
//   static String name = "name";
//   static  String phone = 'phone';
//   static  String token = 'token';
//   static  String isLoggedIn = 'is_logged_in';
//
//   static String languageCode = 'language_code';
// }
//
//
