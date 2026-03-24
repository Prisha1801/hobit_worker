import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'hobit_high_importance';
  static const String _channelName = 'Hobit Notifications';

  static Future<void> init() async {
    // ✅ Request permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // ✅ Create high-importance channel (required for heads-up on Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap — navigate if needed
      },
    );
  }

  static Future<void> show(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,        // ✅ Must match channel created above
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: message.notification?.title,
      // ✅ These make it look like Gate-style full popup
      fullScreenIntent: true,   // pops over lock screen too
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: false,
        contentTitle: message.notification?.title,
        summaryText: 'Hobit',
      ),
    );

    final NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _plugin.show(
      message.hashCode,          // ✅ Unique ID so notifications don't replace each other
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }
}


// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//   FlutterLocalNotificationsPlugin();
//
//   static Future<void> init() async {
//     const AndroidInitializationSettings android =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings settings =
//     InitializationSettings(android: android);
//
//     await _plugin.initialize(settings);
//   }
//
//   static Future<void> show(RemoteMessage message) async {
//     const AndroidNotificationDetails androidDetails =
//     AndroidNotificationDetails(
//       'channel_id',
//       'channel_name',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails details =
//     NotificationDetails(android: androidDetails);
//
//     await _plugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       details,
//     );
//   }
// }