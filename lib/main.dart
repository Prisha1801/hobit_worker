import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// ✅ Outside main(), outside any class — top-level only
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("─────────────────────────────────────────");
  print("🔥 [Background] MESSAGE RECEIVED IN BACKGROUND/TERMINATED");
  print("   ↳ Message ID  : ${message.messageId}");
  print("   ↳ From        : ${message.from}");
  print("   ↳ Sent time   : ${message.sentTime}");
  print("   ↳ Notif title : ${message.notification?.title}");
  print("   ↳ Notif body  : ${message.notification?.body}");
  print("   ↳ Data payload: ${message.data}");
  print("─────────────────────────────────────────");

  // ✅ Background-safe init — no permission/channel calls
  await LocalNotificationService.initBackground();

  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];

  if (title != null && body != null) {
    print("🔔 [Background] Triggering showCustom()");
    await LocalNotificationService.showCustom(title, body);
  } else {
    print("⚠️ [Background] Skipped — title or body is null");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ✅ Must be registered before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await AppPreference().initialAppPreference();
  final isLoggedIn = AppPreference().getBool(PreferencesKey.isLoggedIn);
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
      home: ConnectivityWrapper(child: SplashScreen()),
      builder: (context, child) => ConnectivityWrapper(child: child!),
    );
  }
}

