import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/auth/permission_screen.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/bottom_nav_bar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  const OtpVerificationScreen({Key? key, required this.phone}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  bool isLoading = false;
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get otp =>
      _controllers.map((e) => e.text).join();


  Future<void> verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid 6 digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await ApiService.postRequest(
        verifyOtpUrl,
        {
          "phone": widget.phone,
          "otp": otp,
        },
      );

      final data = res.data;

      if (data != null && data["status"] == true) {
        final token = data["token"];
        final user = data["data"];

        /// 🔐 SAVE DATA IN SHARED PREFERENCE
        await AppPreference().setString(
          PreferencesKey.token,
          token ?? "",
        );

        await AppPreference().setString(
          PreferencesKey.userId,
          user["id"].toString(),
        );

        await AppPreference().setString(
          PreferencesKey.name,
          user["name"] ?? "",
        );

        await AppPreference().setString(
          PreferencesKey.phone,
          user["phone"] ?? "",
        );

        await AppPreference().setBool(
          PreferencesKey.isLoggedIn,
          true,
        );
        debugPrint("✅ TOKEN SAVEDdddddddddddddddddddddddddddddddddddddd: ${AppPreference().getString(PreferencesKey.token)}");
        debugPrint("✅ WORKING IDddddddddddddddddddddddddddddddddddddddd: ${AppPreference().getString(PreferencesKey.userId)}");
        debugPrint("✅ worker nameeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee: ${AppPreference().getString(PreferencesKey.name)}");
        debugPrint("✅ Worker numberrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr: ${AppPreference().getString(PreferencesKey.phone)}");

        debugPrint("LOGIN TOKENnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn: $token");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Login Successful")),
        );

        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => const MainScreen()),
        //       (_) => false,
        // );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderScope(
              overrides: [
                bottomNavIndexProvider.overrideWith((ref) => 0),
              ],
              child: const LocationPermissionScreen(),
            ),
          ),
              (_) => false,
        );

      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 150),

            /// 🔹 TITLE
            Center(
              child: const Text(
                "OTP Verification",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),
            /// 🔹 SUBTITLE
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                children: [
                  const TextSpan(
                    text: "We've sent an OTP for the above phone number,\n",
                  ),
                  TextSpan(
                    text: "please check number  +91 ${widget.phone}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 24),

            /// 🔹 ENTER CODE TEXT
            const Text(
              "Enter Code",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 OTP BOXES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F3CC9),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            /// 🔹 SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kkblack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading ? null : verifyOtp,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 RESEND
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Didn't see your email? ",
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "Resend",
                      style: const TextStyle(
                        color: Color(0xFF4F3CC9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
