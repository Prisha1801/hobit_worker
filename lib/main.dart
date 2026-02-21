// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hobit_worker/prefs/app_preference.dart';
// import 'package:hobit_worker/screens/splash_screen.dart';
// import 'language_selection/language_provider.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await AppPreference().initialAppPreference();
//   runApp(ProviderScope(child: const MyApp()));
// }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'Flutter Demo',
// //       home: SplashScreen(),
// //     );
// //   }
// // }
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final locale = ref.watch(localeProvider);
//
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       locale: locale, // 🔥 IMPORTANT
//       supportedLocales: const [
//         Locale('en'),
//         Locale('hi'),
//         Locale('mr'),
//       ],
//       localizationsDelegates: [
//         AppLocalizations.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       home: SplashScreen(),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'prefs/app_preference.dart';
import 'language_selection/language_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreference().initialAppPreference();
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
      home: SplashScreen(),
    );
  }
}
