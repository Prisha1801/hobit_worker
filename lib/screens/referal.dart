import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api_services/api_services.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'package:share_plus/share_plus.dart';

class ReferralApi {

  static Future<String?> getReferralCode() async {

    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      "/api/referral/my-link",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final data = res.data;

    if (data != null) {
      return data["referral_code"];   // ✅ only referral code
    }

    return null;
  }
}

Future<void> shareReferralCode(BuildContext context) async {

  try {

    final code = await ReferralApi.getReferralCode();

    if (code != null) {

      await Share.share(
        "Use my Hobit referral code and earn rewards 🎁\n\nReferral Code: $code",
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Referral code not available")),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );

  }
}