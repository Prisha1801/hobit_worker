import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:hobit_worker/auth/permission_screen.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/bottom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fcm_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String otpType;

  const OtpVerificationScreen({Key? key, required this.phone, required this.otpType})
      : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool isLoading = false;

  /// 🔥 SMS auto-fetch (User Consent API — no SMS permission needed)
  final SmartAuth _smartAuth = SmartAuth.instance;

  /// OTP String
  String get otp => _controllers.map((e) => e.text).join();

  @override
  void initState() {
    super.initState();
    // Start listening for the incoming OTP SMS as soon as the screen opens.
    _listenForOtpSms();
  }

  /// 🔥 Auto-read the OTP from an incoming SMS via the SMS User Consent API.
  /// NOTE: auto-fetch works only for SMS. WhatsApp OTPs cannot be auto-read,
  /// so we skip listening when the worker chose WhatsApp.
  Future<void> _listenForOtpSms() async {
    if (widget.otpType != "sms") {
      debugPrint("📩 [OTP] Auto-fetch skipped (type = ${widget.otpType})");
      return;
    }

    debugPrint("📩 [OTP] Waiting for OTP SMS (User Consent)...");

    try {
      final res = await _smartAuth.getSmsWithUserConsentApi();
      if (!mounted) return;

      if (res.hasData) {
        final code = res.requireData.code;
        debugPrint("📩 [OTP] SMS received → extracted code: $code");
        if (code != null && code.isNotEmpty) {
          _fillOtp(code);
        }
      } else if (res.isCanceled) {
        debugPrint("📩 [OTP] Auto-fetch canceled by user");
      } else {
        debugPrint("📩 [OTP] Auto-fetch failed / no code");
      }
    } catch (e) {
      debugPrint("📩 [OTP] Auto-fetch error: $e");
    }
  }

  /// 🔥 Fill the 6 boxes from an auto-fetched code, then auto-submit.
  void _fillOtp(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint("📩 [OTP] Filling boxes with: $digits");

    if (digits.length < 6) {
      debugPrint("📩 [OTP] Code shorter than 6 digits — ignored");
      return;
    }

    final otp6 = digits.substring(0, 6);
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = otp6[i];
    }
    setState(() {});

    // Auto-verify once the code is filled.
    verifyOtp();
  }

  /// Clear OTP Fields
  void clearOtpFields() {
    for (var c in _controllers) {
      c.clear();
    }

    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  /// RESEND OTP
  Future<void> resendOtp() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final res = await ApiService.postRequest(
        "/api/worker/login/send-otp",
        {
          "phone": widget.phone,
          "type": widget.otpType, // Added type here
        },
      );

      final data = res.data;

      if (data != null && data["status"] == true) {
        clearOtpFields();

        // 🔥 Re-arm the SMS auto-fetch listener for the new OTP.
        _listenForOtpSms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? loc.otpSent),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.somethingWentWrong)),
      );
    }
  }

  /// VERIFY OTP
  Future<void> verifyOtp() async {
    final loc = AppLocalizations.of(context)!;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidOtp)),
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

        await AppPreference().setString(
          PreferencesKey.role,
          user["role"] ?? "",
        );

        await AppPreference().setBool(
          PreferencesKey.isLoggedIn,
          true,
        );

        debugPrint("✅ TOKEN SAVED: ${AppPreference().getString(PreferencesKey.token)}");
        debugPrint("✅ TOKEN SAVEDdddddddddddddddddddddddddddddddddddddd: ${AppPreference().getString(PreferencesKey.token)}");
        debugPrint("✅ WORKING IDddddddddddddddddddddddddddddddddddddddd: ${AppPreference().getString(PreferencesKey.userId)}");
        debugPrint("✅ worker nameeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee: ${AppPreference().getString(PreferencesKey.name)}");
        debugPrint("✅ Worker numberrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr: ${AppPreference().getString(PreferencesKey.phone)}");
        debugPrint("LOGIN TOKENnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn: $token");


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? loc.loginSuccessful),
          ),
        );

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await FCMService.sendTokenToBackend(fcmToken);
        }

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
        SnackBar(content: Text(loc.invalidOtp)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    // 🔥 Stop the SMS User Consent listener.
    _smartAuth.removeUserConsentApiListener();

    for (var c in _controllers) {
      c.dispose();
    }

    for (var f in _focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [

              const SizedBox(height: 120),

              /// TITLE
              Text(
                loc.otpVerification,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              /// SUBTITLE
              Text(
                "${loc.otpSubtitle} +91 ${widget.phone}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              /// ENTER CODE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.enterCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// OTP INPUT BOXES
              LayoutBuilder(
                builder: (context, constraints) {
                  double boxWidth = constraints.maxWidth / 7;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: boxWidth,
                        height: 60,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          maxLength: 1,

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),

                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: Colors.grey.shade50,

                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: kkblack,
                                width: 2,
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
                  );
                },
              ),

              const SizedBox(height: 40),

              /// SUBMIT BUTTON
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
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    loc.submit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// RESEND
              RichText(
                text: TextSpan(
                  text: loc.didntReceiveOtp,
                  style: const TextStyle(color: Colors.black),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: resendOtp,
                        child: Text(
                          loc.resend,
                          style: const TextStyle(
                            color: Color(0xFF4F3CC9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
