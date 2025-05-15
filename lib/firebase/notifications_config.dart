import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> configureLocalNotifications({
  required void Function(String payload) onPayload,
  required String? notificationIcon,
}) async {
  const iOS = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final android = AndroidInitializationSettings(
    notificationIcon ?? '@mipmap/ic_launcher',
  );

  final settings = InitializationSettings(
    android: android,
    iOS: iOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      if (response.notificationResponseType == NotificationResponseType.selectedNotification &&
          response.payload != null) {
        onPayload(response.payload!);
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  if (Platform.isIOS) {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Opcional: handle background notification tap
}