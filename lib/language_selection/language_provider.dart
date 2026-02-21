import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

final localeProvider =
StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier()
      : super(
    Locale(
      AppPreference().getString(
        PreferencesKey.languageCode,
        defValue: 'en',
      ),
    ),
  );

  void changeLanguage(String code) async {
    state = Locale(code);
    await AppPreference().setString(
      PreferencesKey.languageCode,
      code,
    );
  }
}
