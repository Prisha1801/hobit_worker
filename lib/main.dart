import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hobit_worker/utils/internet_connectivity/connectivity.dart';
import 'api_services/notification_services.dart';
import 'auth/fcm_service.dart';
import 'l10n/app_localizations.dart';
import 'prefs/app_preference.dart';
import 'language_selection/language_provider.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ IMPORTANT: Do NOT call requestNotificationsPermission here (NullPointerException)
  await Firebase.initializeApp();
  print("🌙 BACKGROUND HANDLER — Processing message");
  print("📦 DATA 👉 ${message.data}");

  // ✅ Init WITHOUT permission request (avoids NPE)
  await LocalNotificationService.init(isBackground: true);
  
  // ✅ Explicitly show the notification
  await LocalNotificationService.showFromMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await AppPreference().initialAppPreference();
  
  // ✅ Foreground init (requests permission safely)
  await LocalNotificationService.init(isBackground: false);

  // ✅ Detect if the app was cold-started by tapping a notification
  await LocalNotificationService.checkLaunchedFromNotification();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: ConnectivityWrapper(child: const SplashScreen()),
      builder: (context, child) => ConnectivityWrapper(child: child!),
    );
  }
}
