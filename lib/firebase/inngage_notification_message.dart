import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'notification_handlers.dart';
import 'notifications_config.dart';
import 'notification_utils.dart';

class InngageNotificationMessage {
  static void Function(Map<String, dynamic>) onNotificationClick = (_) {};

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  static Future<void> subscribe({
    String? notificationIcon,
    Color? backgroundIcon,
  }) async {
    // Cancel any previous subscriptions to avoid duplicate listeners
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await requestPermissions();
    await registerFCMToken();

    configureLocalNotifications();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
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

    _onMessageOpenedAppSub =
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

  /// Prepares the device to receive push and in-app messages: requests
  /// notification permissions, configures local notifications and sends the
  /// FCM token to the Inngage API.
  ///
  /// Call this right after [InngageSDK.subscribe] when wiring the Firebase
  /// Messaging handlers manually (see [handlerNotificationForeground],
  /// [handlerNotificationClick], [handlerNotificationClosed] and
  /// [handlerNotificationBackground]).
  static Future<void> registerSubscriber({String? notificationIcon}) async {
    await requestPermissions();
    await configureLocalNotifications(notificationIcon: notificationIcon);
    await registerFCMToken();
  }

  /// Handles a notification received while the app is in the **foreground**.
  ///
  /// Wire it into `FirebaseMessaging.onMessage.listen`.
  static Future<void> handlerNotificationForeground({
    required RemoteMessage remoteMessage,
    Color? backgroundColor,
  }) {
    return InngageHandlersNotification.handleForegroundNotification(
      remoteMessage: remoteMessage,
      backgroundColor: backgroundColor,
    );
  }

  /// Handles the user tapping a notification while the app is in the
  /// **background**.
  ///
  /// Wire it into `FirebaseMessaging.onMessageOpenedApp.listen`.
  static Future<void> handlerNotificationClick({
    required RemoteMessage remoteMessage,
  }) {
    return InngageHandlersNotification.handleClickNotification(
      remoteMessage: remoteMessage,
      onNotificationClick: onNotificationClick,
    );
  }

  /// Handles the user tapping a notification that launched the app from a
  /// **terminated/closed** state.
  ///
  /// Wire it into `FirebaseMessaging.instance.getInitialMessage()`.
  static Future<void> handlerNotificationClosed(RemoteMessage remoteMessage) {
    return InngageHandlersNotification.handleTerminatedNotification(
      remoteMessage: remoteMessage,
      onNotificationClick: onNotificationClick,
    );
  }

  /// Handles in-app messages delivered while the app is in the **background**
  /// (persists the payload so it can be shown when the app is resumed).
  ///
  /// Wire it into a top-level `FirebaseMessaging.onBackgroundMessage` handler.
  static Future<void> handlerNotificationBackground({
    required Map<String, dynamic> remoteMessageData,
  }) {
    return InngageHandlersNotification.handleBackgroundNotification(
      remoteMessageData,
    );
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
