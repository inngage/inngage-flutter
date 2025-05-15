import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

import 'notifications_config.dart';

Future<void> handleForegroundNotification({
  required Map<String, dynamic> data,
  required Color? backgroundColor,
  required Function(Map<String, dynamic>) onData,
}) async {
  try {
    final rawData = data['additional_data'];
    final parsed = json.decode(rawData);
    final inapp = parsed['inapp_message'] == true;

    if (inapp) {
      const storage = FlutterSecureStorage();
      await storage.write(key: "inapp", value: rawData);
      final model = InAppModel.fromJson(parsed);
      InngageDialog.showInAppDialog(model);
    } else {
      if (Platform.isAndroid) {
        final androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          color: backgroundColor ?? Colors.blue,
        );
        final details = NotificationDetails(android: androidDetails);
        final title = data['title'] ?? '';
        final message = data['message'] ?? '';

        if (title.isNotEmpty && message.isNotEmpty) {
          await flutterLocalNotificationsPlugin.show(
            0,
            title,
            message,
            details,
            payload: json.encode(data),
          );
        }
      }
    }

    onData(data);
  } catch (e) {
    debugPrint('handleForegroundNotification error: $e');
  }
}

Future<void> handleBackgroundNotification(Map<String, dynamic> data) async {
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