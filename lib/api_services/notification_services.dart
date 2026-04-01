import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'hobit_high_importance';
  static const String _channelName = 'Hobit Notifications';

  /// ✅ Full init — call this in main() only (has UI context)
  static Future<void> init() async {
    print("🔔 [LocalNotification] init() called — full init");

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    print("🔔 [LocalNotification] Permission requested");

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    print("🔔 [LocalNotification] Channel created: $_channelId");

    await _initializePlugin();
    print("🔔 [LocalNotification] Full init complete ✅");
  }
  /// ✅ Minimal init — safe to call in background isolate (no context ops)
  static Future<void> initBackground() async {
    print("🔔 [LocalNotification] initBackground() called — background-safe init");
    await _initializePlugin();
    print("🔔 [LocalNotification] Background init complete ✅");
  }

  /// Shared plugin initialization (safe in all contexts)
  static Future<void> _initializePlugin() async {
    print("🔔 [LocalNotification] _initializePlugin() called");

    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 [LocalNotification] Notification tapped 👉 payload: ${details.payload}");
        // Handle tap — navigate if needed
      },
    );
    print("🔔 [LocalNotification] Plugin initialized ✅");
  }

  /// Show notification from a RemoteMessage (foreground or background)
  static Future<void> show(RemoteMessage message) async {
    print("🔔 [LocalNotification] show() called");
    print("   ↳ Raw notification title: ${message.notification?.title}");
    print("   ↳ Raw notification body : ${message.notification?.body}");
    print("   ↳ Data payload          : ${message.data}");

    // Fallback to data payload for data-only messages
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];

    if (title == null || body == null) {
      print("⚠️ [LocalNotification] show() aborted — title or body is null");
      return;
    }

    print("🔔 [LocalNotification] Showing notification — title: $title | body: $body");

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: title,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: 'Hobit',
      ),
    );

    final NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _plugin.show(
      message.hashCode,
      title,
      body,
      details,
    );
    print("✅ [LocalNotification] show() displayed successfully");
  }

  /// Show a custom notification with explicit title and body
  static Future<void> showCustom(String title, String body) async {
    print("🔔 [LocalNotification] showCustom() called");
    print("   ↳ title: $title");
    print("   ↳ body : $body");

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: title,
    );

    final NotificationDetails details =
    NotificationDetails(android: androidDetails);

    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print("🔔 [LocalNotification] Notification ID: $id");

    await _plugin.show(id, title, body, details);
    print("✅ [LocalNotification] showCustom() displayed successfully");
  }
}