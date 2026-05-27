import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_services/api_services.dart';
import '../api_services/notification_services.dart';
import '../api_services/urls.dart';
import '../main.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/appBar_for_home.dart';
import '../utils/notification.dart';


class FCMService {
  // ✅ Added a notifier for new bookings to alert the UI
  static final ValueNotifier<Map<String, dynamic>?> newBookingNotifier = ValueNotifier(null);

  static Future<void> init({required bool isLoggedIn}) async {
    print("🚀 [FCMService] INIT START");

    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("🔐 [FCMService] Permission Status 👉 ${permission.authorizationStatus}");

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, 
        badge: true,
        sound: true,
      );

      // ✅ Graceful Token Retrieval with retry/delay
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
        print("📱 [FCMService] INITIAL TOKEN 👉 $token");
      } catch (e) {
        print("⚠️ [FCMService] Initial Token Retrieval Failed (SERVICE_NOT_AVAILABLE). Will rely on onTokenRefresh. Error: $e");
      }

      if (isLoggedIn && token != null) {
        await sendTokenToBackend(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print("🔄 [FCMService] TOKEN REFRESHED 👉 $newToken");
        if (isLoggedIn) await sendTokenToBackend(newToken);
      });

      // ✅ FOREGROUND — app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("📩 [FCMService] FOREGROUND MESSAGE RECEIVED: ${message.data}");

        final data = message.data;
        final type = data['type']?.toString();
        
        final role = AppPreference().getString(PreferencesKey.role).toLowerCase();
        print("👤 [FCMService] Current User Role: $role");
        
        final isCoordinator = role.contains('coordinator');

        // 🚨 Handle New Booking for Coordinator
        if (isCoordinator && type == 'new_booking') {
          print("🔔 [FCMService] NEW BOOKING DETECTED FOR COORDINATOR");
          newBookingNotifier.value = data;
          
          // Also show a heads-up notification in foreground
          await LocalNotificationService.showFromMessage(message);
          return;
        }

        final bookingId = data['booking_id']?.toString().trim();
        final isBookingCall = bookingId != null && bookingId.isNotEmpty && type != 'new_booking';

        if (isBookingCall) {
          print("🚨 [FCMService] BOOKING CALL — triggering native CallService");
          try {
            await const MethodChannel('incoming_call')
                .invokeMethod('showIncomingCall', {'booking_id': bookingId});
          } catch (e) {
            print("⚠️ [FCMService] MethodChannel Error 👉 $e");
            await LocalNotificationService.showFromMessage(message);
          }
        } else {
          print("🔔 [FCMService] SHOWING NORMAL LOCAL NOTIFICATION");
          await LocalNotificationService.showFromMessage(message);
          notificationCount.value++;
        }
      });

      // ✅ BACKGROUND TAP — user tapped notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("📲 [FCMService] APP OPENED FROM BACKGROUND TAP: ${message.data}");
        _handleNotificationTap(message.data);
      });

      // ✅ TERMINATED TAP
      RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        print("🚀 [FCMService] APP OPENED FROM TERMINATED STATE: ${initialMessage.data}");
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage.data);
        });
      }
    } catch (globalError) {
      print("❌ [FCMService] CRITICAL INIT ERROR: $globalError");
    }

    print("✅ [FCMService] INIT COMPLETE");
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    print("🎯 [FCMService] Handling Tap for Data: $data");
    final bookingId = data['booking_id']?.toString().trim();

    if (bookingId != null && bookingId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    } else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    print("🌙 [FCMService] BACKGROUND HANDLER TRIGGERED");
    print("📦 [FCMService] DATA 👉 ${message.data}");
  }

  static Future<void> sendTokenToBackend(String token) async {
    print("📤 [FCMService] SENDING TOKEN TO BACKEND: $token");
    try {
      final authToken = AppPreference().getString(PreferencesKey.token);
      if (authToken.isEmpty) {
        print("⚠️ [FCMService] Auth token is empty, skipping backend update.");
        return;
      }
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
      print("✅ [FCMService] TOKEN UPDATE STATUS 👉 ${res.statusCode}");
    } catch (e) {
      print("❌ [FCMService] TOKEN UPDATE ERROR 👉 $e");
    }
  }
}
