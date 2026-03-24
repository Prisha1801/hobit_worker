import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api_services/api_services.dart';
import '../api_services/notification_services.dart';
import '../api_services/urls.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
class FCMService {

  static Future<void> init({required bool isLoggedIn}) async {

    // Permission
    await FirebaseMessaging.instance.requestPermission();

    // iOS foreground show
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Token
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN 👉 $token");
    if (isLoggedIn && token != null) {
      await sendTokenToBackend(token);
    }

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("NEW TOKEN 👉 $newToken");
      if (isLoggedIn) {
        await sendTokenToBackend(newToken);
      }
    });

    // ✅ Foreground listener — FCM is silent in foreground without this
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 FOREGROUND MESSAGE 👉 ${message.notification?.title}");
      if (message.notification != null) {
        LocalNotificationService.show(message);
      }
    });

    // ✅ App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 OPENED FROM BACKGROUND 👉 ${message.notification?.title}");
      // Add navigation here if needed
    });

    // ✅ App opened from terminated state via notification tap
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 OPENED FROM TERMINATED 👉 ${initialMessage.notification?.title}");
      // Add navigation here if needed
    }
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      final authToken = AppPreference().getString(PreferencesKey.token);

      print("🔥 AUTH TOKENnnnnnnnnnnnnnnnnnnnnnnn 👉 $authToken");
      print("🔥 FCM TOKENnnnnnnnnnnnnnnnnnnnnnnn 👉 $token");

      final res = await ApiService.postRequest(
        fcmTokenUrl,
        {"fcm_token": token},
        options: Options(
          headers: {
            "Authorization": "Bearer $authToken",
            "Content-Type": "application/json",
          },
        ),
      );

      print("✅ FCM API SUCCESSsssssssssssssssssssssssssssss 👉 ${res.data}");
    } catch (e) {
      print("❌ FCM API ERROR 👉 $e");
    }
  }
}
// class FCMService {
//
//   static Future<void> init({required bool isLoggedIn}) async {
//
//     // Permission
//     await FirebaseMessaging.instance.requestPermission();
//
//     // Token
//     String? token = await FirebaseMessaging.instance.getToken();
//
//     print("FCM TOKEN 👉 $token");
//
//     if (isLoggedIn && token != null) {
//       await sendTokenToBackend(token);
//     }
//
//     // Token refresh
//     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//       print("NEW TOKEN 👉 $newToken");
//
//       if (isLoggedIn) {
//         await sendTokenToBackend(newToken);
//       }
//     });
//   }
//   static Future<void> sendTokenToBackend(String token) async {
//     try {
//
//       final authToken =
//       AppPreference().getString(PreferencesKey.token);
//
//       print("🔥 AUTH TOKENnnnnnnnnnnnnnnnnnnnnnnn 👉 $authToken");
//       print("🔥 FCM TOKENnnnnnnnnnnnnnnnnnnnnnnn 👉 $token");
//
//       final res = await ApiService.postRequest(
//         fcmTokenUrl,
//         {
//           "fcm_token": token,
//         },
//         options: Options(
//           headers: {
//             "Authorization": "Bearer $authToken",
//             "Content-Type": "application/json",
//           },
//         ),
//       );
//
//       print("✅ FCM API SUCCESSsssssssssssssssssssssssssssss 👉 ${res.data}");
//
//     } catch (e) {
//       print("❌ FCM API ERROR 👉 $e");
//     }
//   }
//
// }