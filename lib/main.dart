import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hobit_worker/prefs/preference_key.dart';
import 'package:hobit_worker/utils/internet_connectivity/connectivity.dart';
import 'api_services/notification_services.dart';
import 'auth/fcm_service.dart';
import 'l10n/app_localizations.dart';
import 'prefs/app_preference.dart';
import 'language_selection/language_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();   // 🔥 Firebase init
  //await FCMService.init();
  await AppPreference().initialAppPreference();
  final isLoggedIn =
  AppPreference().getBool(PreferencesKey.isLoggedIn);
  await FCMService.init(isLoggedIn: isLoggedIn);
  await LocalNotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),

      home: ConnectivityWrapper(child: SplashScreen()),
      builder: (context, child) => ConnectivityWrapper(child: child!),
    );
  }
}

