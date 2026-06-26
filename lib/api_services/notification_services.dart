import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../utils/notification.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ✅ Incremented version to hobit_booking_call_v6 to force refresh channel settings
  static const String _channelId = 'hobit_booking_call_v6';
  static const String _channelName = 'Urgent Booking Alerts';

  /// ✅ Set to true when the app was cold-started by tapping a notification.
  /// MainScreen reads this once it is built and opens the NotificationScreen.
  static bool launchedFromNotification = false;
  static String? launchPayload;

  /// Opens the in-app Notifications page on top of whatever is showing.
  /// Used for foreground / background notification taps.
  static void openNotificationsPage() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  /// ✅ Call once from main() AFTER init() — detects if the app was launched
  /// from a terminated state by tapping a notification.
  static Future<void> checkLaunchedFromNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        launchedFromNotification = true;
        launchPayload = details?.notificationResponse?.payload;
        print("🚀 [LocalNotificationService] App launched from notification tap. payload=$launchPayload");
      }
    } catch (e) {
      print("⚠️ [LocalNotificationService] launch details error: $e");
    }
  }

  static Future<void> init({bool isBackground = false}) async {
    print("🔔 [LocalNotificationService] Initializing...");

    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("📲 [LocalNotificationService] Tap: actionId=${details.actionId}, payload=${details.payload}");

        // User explicitly dismissed — just let the notification cancel.
        if (details.actionId == 'dismiss_booking') return;

        // Body tap OR 'view_booking' action → open the Notifications page
        // on top of the running app (MainScreen stays underneath).
        openNotificationsPage();
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

    await showBookingCall(
      title: title,
      body: body,
      payload: data['booking_id']?.toString(),
    );
  }
}
