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

    configureLocalNotifications();

    FirebaseMessaging.onMessage.listen((message) {
      InngageHandlersNotification.handleForegroundNotification(
        remoteMessage: message,
        backgroundColor: backgroundIcon,
      );
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      InngageHandlersNotification.handleTerminatedNotification(
          remoteMessage: initialMessage,
          onNotificationClick: onNotificationClick);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Mensagem recebida em onMessageOpenedApp: ${message.data}');
      openNotification(message.data);
      onNotificationClick(message.data);
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await InngageHandlersNotification.handleBackgroundNotification(
        message.data);
  }

  static Future<void> configureLocalNotifications(
      {String? notificationIcon}) async {
    await InngageConfigureLocalNotifications.configureLocalNotifications(
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
}
