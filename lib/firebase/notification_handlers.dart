import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/firebase/notification_utils.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

import 'notifications_config.dart';

class InngageHandlersNotification {
  static Future<void> handleForegroundNotification({
    required RemoteMessage remoteMessage,
    Color? backgroundColor,
  }) async {
    try {
      final Map<String, dynamic> data = remoteMessage.data;
      final rawData = data['additional_data'];

      if (rawData != null) {
        try {
          final parsed = json.decode(rawData);
          final inapp = parsed['inapp_message'] == true;

          if (inapp) {
            const storage = FlutterSecureStorage();
            await storage.write(key: "inapp", value: rawData);
            final model = InAppModel.fromJson(parsed);
            InngageDialog.showInAppDialog(model);
          }
        } catch (e) {
          debugPrint('Failed to parse additional_data or handle inapp: $e');
        }
      }

      final notification = remoteMessage.notification;

      if (notification != null) {
        final String title = notification.title ?? '';
        final String body = notification.body ?? '';

        NotificationDetails details;

        if (Platform.isAndroid) {
          final androidDetails = AndroidNotificationDetails(
            'high_importance_channel',
            'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            color: backgroundColor ?? Colors.blue,
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

  static Future<void> handleBackgroundNotification(
      Map<String, dynamic> data) async {
    try {
      final rawData = data['additional_data'];
      final parsed = json.decode(rawData);
      final inapp = parsed['inapp_message'] == true;

      if (inapp) {
        const storage = FlutterSecureStorage();
        await storage.write(key: "inapp", value: rawData);
      }
    } catch (e) {
      debugPrint('handleBackgroundNotification error: $e');
    }
  }
}
