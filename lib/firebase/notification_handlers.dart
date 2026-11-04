import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:inngage_plugin/firebase/notification_utils.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class InngageHandlersNotification {
  static Future<void> handleForegroundNotification({
    required RemoteMessage remoteMessage,
    Color? backgroundColor,
  }) async {
    try {
      final Map<String, dynamic> data = remoteMessage.data;

      final notification = remoteMessage.notification;

      if (notification != null) {
        final String title = notification.title ?? '';
        final String body = notification.body ?? '';

        NotificationDetails details;

        if (Platform.isAndroid) {
          final String? imageUrl = notification.android?.imageUrl;
          Uint8List? imageBytes;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(imageUrl));
              if (response.statusCode == 200) {
                imageBytes = response.bodyBytes;
              }
            } catch (e) {
              debugPrint('Failed to download notification image: $e');
            }
          }

          final styleInformation = imageBytes != null
              ? BigPictureStyleInformation(
                  ByteArrayAndroidBitmap(imageBytes),
                  largeIcon: ByteArrayAndroidBitmap(imageBytes),
                )
              : null;

          final androidDetails = AndroidNotificationDetails(
            'high_importance_channel',
            'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            color: backgroundColor ?? Colors.blue,
            styleInformation: styleInformation,
          );
          details = NotificationDetails(android: androidDetails);
        } else if (Platform.isIOS) {
          const iOSDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
          details = const NotificationDetails(iOS: iOSDetails);
        } else {
          details = const NotificationDetails();
        }

        if (title.isNotEmpty && body.isNotEmpty) {
          await flutterLocalNotificationsPlugin.show(
            0,
            title,
            body,
            details,
            payload: json.encode(data),
          );
        }
      }
    } catch (e) {
      debugPrint('handleForegroundNotification error: $e');
    }
  }

  static Future<void> handleTerminatedNotification(
      {required RemoteMessage? remoteMessage, onNotificationClick}) async {
    if (remoteMessage != null) {
      openNotification(remoteMessage.data, inBack: true);
      if (onNotificationClick != null) {
        onNotificationClick(remoteMessage.data);
      }
    }
  }

  static Future<void> handleClickNotification(
      {required RemoteMessage remoteMessage, onNotificationClick}) async {
    openNotification(remoteMessage.data);
    if (onNotificationClick != null) {
      onNotificationClick(remoteMessage.data);
    }
  }

  /// Since 4.0.0 In-App messages are no longer delivered through push
  /// payloads (see `InngageInApp.show`), so background data messages need no
  /// processing. Kept as a no-op so existing background handlers keep working.
  static Future<void> handleBackgroundNotification(
      Map<String, dynamic> data) async {}
}
