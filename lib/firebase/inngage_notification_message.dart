import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'notification_handlers.dart';
import 'notifications_config.dart';
import 'notification_utils.dart';

class InngageNotificationMessage {
  static void Function(Map<String, dynamic>) onNotificationClick = (_) {};

  static Future<void> subscribe({
    String? notificationIcon,
    Color? backgroundIcon,
  }) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await requestPermissions();
    await registerFCMToken();

    FirebaseMessaging.onMessage.listen((message) {
      handleForegroundNotification(
        data: message.data,
        backgroundColor: backgroundIcon,
        onData: onNotificationClick,
      );
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      openNotification(initialMessage.data, inBack: true);
      onNotificationClick(initialMessage.data);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      openNotification(message.data);
      onNotificationClick(message.data);
    });

    await configureLocalNotifications(
      onPayload: (payload) {
        try {
          final data = Map<String, dynamic>.from(json.decode(payload));
          openNotification(data);
          onNotificationClick(data);
        } catch (e) {
          debugPrint('Notification payload error: $e');
        }
      },
      notificationIcon: notificationIcon,
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await handleBackgroundNotification(message.data);
  }
}