import 'package:flutter/material.dart';
import 'package:hobit_worker/auth/signup_page.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../api_services/api_services.dart';
import '../l10n/app_localizations.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool keepSignedIn = true;
  bool isLoading = false;


  Future<void> sendOtp() async {
    final loc = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidPhone)),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await ApiService.postRequest(
        "/api/worker/login/send-otp",
        {
          "phone": phone,
        },
      );

      final data = res.data;

      if (data != null && data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? loc.otpSent)),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(phone: phone),
          ),
        );
      }
    }  catch (e) {
      String message = loc.somethingWentWrong;
      if (e is ApiException) {
        message = e.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ,   textAlign: TextAlign.center, )),
      );
    }
  finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔹 APP BAR (NO BACK BUTTON)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ removes back button
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            /// TITLE
            Center(
              child: Text(
               loc.login,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// PHONE LABEL
            Text(
             loc.phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            /// PHONE INPUT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text("+91", style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  const Text("|", style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText: loc.enterPhone,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 BLACK CHECKBOX
            Row(
              children: [
                Checkbox(
                  value: keepSignedIn,
                  activeColor: Colors.black,
                  checkColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.black,
                    width: 1.5,
                  ),
                  onChanged: (value) {
                    setState(() {
                      keepSignedIn = value!;
                    });
                  },
                ),
                Text(
                 loc.keepSignedIn,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// LOGIN BUTTON
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
                onPressed: isLoading ? null : sendOtp,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                loc.sendOtp,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// SIGN UP LINK
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.dontHaveAccount),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Text(
                    loc.signUpHere,
                    style: const TextStyle(
                      color: Colors.black, // black & white theme
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
