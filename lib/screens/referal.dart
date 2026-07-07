import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api_services/api_services.dart';
import '../models/referal_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

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


  static Future<ReferralEarningModel?> getReferralEarnings() async {

    try {

      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        "/api/referral/earnings",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      return ReferralEarningModel.fromJson(res.data);

    } catch (e) {
      debugPrint("Referral earnings error: $e");
      return null;
    }
  }

}

Future<void> shareReferralCode(BuildContext context) async {

  final loc = AppLocalizations.of(context)!;

  try {

    final code = await ReferralApi.getReferralCode();

    if (code != null) {

      await Share.share(
        "${loc.refShareInvite}\n\n${loc.referCode}: $code",
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.refCodeNotAvailable)),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${loc.refError}: $e")),
    );

  }
}