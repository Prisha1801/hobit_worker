import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hobit_worker/utils/internet_connectivity/connectivity.dart';
import 'l10n/app_localizations.dart';
import 'prefs/app_preference.dart';
import 'language_selection/language_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();   // 🔥 Firebase init
  await AppPreference().initialAppPreference();
  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    // return MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   locale: locale,
    //   supportedLocales: AppLocalizations.supportedLocales,
    //   localizationsDelegates: const [
    //     AppLocalizations.delegate,
    //     GlobalMaterialLocalizations.delegate,
    //     GlobalWidgetsLocalizations.delegate,
    //     GlobalCupertinoLocalizations.delegate,
    //   ],
    //   home: ConnectivityWrapper(child: SplashScreen()), // 👈 wrap here
    //   builder: (context, child) => ConnectivityWrapper(child: child!), // 👈 OR use builder for ALL routes
    // );
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

      // 🔥 ADD THIS
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),

      home: ConnectivityWrapper(child: SplashScreen()),
      builder: (context, child) => ConnectivityWrapper(child: child!),
    );
  }
}

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final locale = ref.watch(localeProvider);
//
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       locale: locale,
//       supportedLocales: AppLocalizations.supportedLocales,
//       localizationsDelegates: const [
//         AppLocalizations.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       home: SplashScreen(),
//     );
//   }
// }
