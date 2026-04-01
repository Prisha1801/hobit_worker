import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../api_services/api_services.dart';
import '../api_services/notification_services.dart';
import '../api_services/urls.dart';
import '../main.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/appBar_for_home.dart';
import '../utils/notification.dart';

class FCMService {

  static Future<void> init({required bool isLoggedIn}) async {
    print("🚀 [FCMService] init() called — isLoggedIn: $isLoggedIn");

    // Permission
    final settings = await FirebaseMessaging.instance.requestPermission();
    print("🔐 [FCMService] Permission status: ${settings.authorizationStatus}");

    // iOS foreground show
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print("📱 [FCMService] iOS foreground options set");

    // Token
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔑 [FCMService] FCM TOKEN 👉 $token");

    if (isLoggedIn && token != null) {
      print("📤 [FCMService] User is logged in — sending token to backend");
      await sendTokenToBackend(token);
    } else {
      print("⚠️ [FCMService] Skipping token send — isLoggedIn: $isLoggedIn | token: $token");
    }

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("🔄 [FCMService] Token refreshed 👉 $newToken");
      if (isLoggedIn) {
        print("📤 [FCMService] Sending refreshed token to backend");
        await sendTokenToBackend(newToken);
      }
    });

    // ─── Foreground message ───────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("─────────────────────────────────────────");
      print("📩 [FCMService] FOREGROUND MESSAGE RECEIVED");
      print("   ↳ Message ID  : ${message.messageId}");
      print("   ↳ From        : ${message.from}");
      print("   ↳ Sent time   : ${message.sentTime}");
      print("   ↳ Notif title : ${message.notification?.title}");
      print("   ↳ Notif body  : ${message.notification?.body}");
      print("   ↳ Data payload: ${message.data}");
      print("─────────────────────────────────────────");

      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

      if (title != null && body != null) {
        print("🔔 [FCMService] Triggering showCustom() for foreground message");
        LocalNotificationService.showCustom(title, body);
        notificationCount.value++;
        print("🔴 [FCMService] Badge count incremented 👉 ${notificationCount.value}");
      } else {
        print("⚠️ [FCMService] Foreground message skipped — title or body is null");
      }
    });

    // ─── Background tap (app was in background) ───────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("─────────────────────────────────────────");
      print("📲 [FCMService] APP OPENED FROM BACKGROUND TAP");
      print("   ↳ Title: ${message.notification?.title ?? message.data['title']}");
      print("   ↳ Data : ${message.data}");
      print("─────────────────────────────────────────");

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    });

    // ─── Terminated state tap ─────────────────────────────────────────────────
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("─────────────────────────────────────────");
      print("🚀 [FCMService] APP OPENED FROM TERMINATED STATE TAP");
      print("   ↳ Title: ${initialMessage.notification?.title ?? initialMessage.data['title']}");
      print("   ↳ Data : ${initialMessage.data}");
      print("─────────────────────────────────────────");

      Future.delayed(const Duration(milliseconds: 500), () {
        print("🧭 [FCMService] Navigating to NotificationScreen (delayed)");
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const NotificationScreen(),
          ),
        );
      });
    } else {
      print("ℹ️ [FCMService] No initial message — app opened normally");
    }

    print("✅ [FCMService] init() complete");
  }

  static Future<void> sendTokenToBackend(String token) async {
    print("📡 [FCMService] sendTokenToBackend() called");
    try {
      final authToken = AppPreference().getString(PreferencesKey.token);
      print("   ↳ Auth token: $authToken");
      print("   ↳ FCM token : $token");

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

      print("✅ [FCMService] Token sent successfully 👉 ${res.data}");
    } catch (e) {
      print("❌ [FCMService] Failed to send token 👉 $e");
    }
  }
}