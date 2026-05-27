import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../utils/bottom_nav_bar.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ✅ Incremented version to hobit_booking_call_v6 to force refresh channel settings
  static const String _channelId = 'hobit_booking_call_v6';
  static const String _channelName = 'Urgent Booking Alerts';

  static Future<void> init({bool isBackground = false}) async {
    print("🔔 [LocalNotificationService] Initializing...");

    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        print("📲 [LocalNotificationService] Action Clicked: ${details.actionId}");

        if (details.actionId == 'view_booking') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        } else if (details.actionId == 'dismiss_booking') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      if (!isBackground) {
        await androidPlugin.requestNotificationsPermission();
      }

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Continuous ringing for new bookings.',
          importance: Importance.max, 
          enableVibration: true,
          playSound: true,
          // ✅ Matches your actual file: android/app/src/main/res/raw/alarm_clock.mp3
          sound: RawResourceAndroidNotificationSound('alarm_clock'), 
          showBadge: true,
        ),
      );
    }
    print("✅ [LocalNotificationService] Initialization Complete");
  }

  static Future<void> showBookingCall({
    required String title,
    required String body,
    String? payload,
  }) async {
    print("📢 [LocalNotificationService] TRIGGERING CONTINUOUS RINGING: $title");
    
    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // ✅ Matches your actual file
      sound: const RawResourceAndroidNotificationSound('alarm_clock'),
      enableVibration: true,
      fullScreenIntent: true,
      ongoing: true, 
      autoCancel: false, 
      category: AndroidNotificationCategory.call, 
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_booking',
          'View Booking',
          showsUserInterface: true, 
          cancelNotification: true, 
        ),
        const AndroidNotificationAction(
          'dismiss_booking',
          'Dismiss',
          showsUserInterface: false, 
          cancelNotification: true,  
        ),
      ],
    );

    try {
      await _plugin.show(
        2024, 
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
      print("🚀 [LocalNotificationService] Notification shown with alarm_clock sound");
    } catch (e) {
      print("❌ [LocalNotificationService] Error showing notification: $e");
    }
  }

  static Future<void> showFromMessage(RemoteMessage message) async {
    final data = message.data;
    final title = data['title'] ?? message.notification?.title ?? "New Booking Arrived! 🔔";
    final body = data['body'] ?? message.notification?.body ?? "Check dashboard for details.";

    await showBookingCall(title: title, body: body);
  }
}
