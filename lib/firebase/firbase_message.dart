import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:inngage_plugin/services/inngage_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
}

class InngageNotificationMessage {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void Function(dynamic data) firebaseListenCallback = (data) {};

  static Future<void> subscribe(
      {String? notificationIcon, Color? backgroundIcon}) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    await InngageService.registerSubscriber(fcmToken);

    await receiveNotificationForeground(backgroundIcon);
    await receiveNotificationClosed();

    await _config(notificationIcon);
  }

  static Future<void> receiveNotificationForeground(
      Color? backgroundIcon) async {
    FirebaseMessaging.onMessage.listen((message) async {
      if (InngageProperties.getDebugMode()) {
        debugPrint('onMessage ${message.data}');
      }

      var inappMessage = false;
      try {
        var data = json.decode(message.data['additional_data']);

        inappMessage = data['inapp_message'];
      } catch (e) {
        debugPrint(e.toString());
      }
      debugPrint('logx listen $inappMessage');
      if (inappMessage) {
        try {
          const storage = FlutterSecureStorage();
          var rawData = message.data['additional_data'];
          var data = json.decode(rawData);

          inappMessage = data['inapp_message'];

          if (inappMessage) {
            storage.write(key: "inapp", value: rawData);
          }

          var inAppModel = InAppModel.fromJson(data);

          InngageDialog.showInAppDialog(inAppModel);
        } catch (e) {
          debugPrint('logx listen $e');
        }
      } else {
        if (Platform.isAndroid) {
          AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'high_importance_channel',
            'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            color: backgroundIcon ?? Colors.blue,
            styleInformation: const BigTextStyleInformation(''),
          );
          NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          final titleNotification = message.data['title'] ?? "";
          final messageNotification = message.data['message'] ?? "";
          if (titleNotification.toString().isNotEmpty &&
              messageNotification.toString().isNotEmpty) {
            await flutterLocalNotificationsPlugin.show(0, titleNotification,
                messageNotification, platformChannelSpecifics,
                payload: json.encode(message.data));
          }
        }
      }
    });
  }

  static Future<void> receiveNotificationClosed() async {
    RemoteMessage? remoteMessage = await _firebaseMessaging.getInitialMessage();
    if (remoteMessage != null) {
      InngageNotification.openCommonNotification(
          data: remoteMessage.data,
          appToken: InngageProperties.appToken,
          inBack: true);
      firebaseListenCallback(remoteMessage.data);
    }
  }

  static Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  static _config(String? notificationIcon) async {
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            notificationIcon ?? '@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            onDidReceiveLocalNotification: (
              int id,
              String? title,
              String? body,
              String? payload,
            ) async {});

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            if (notificationResponse.payload != null) {
              debugPrint(
                  'notification payload: ${notificationResponse.payload}');
              try {
                var data = json.decode(notificationResponse.payload ?? "");
                firebaseListenCallback(data);
              } catch (e) {
                debugPrint('firebaseListenCallback error: $e');
              }
              InngageNotification.openCommonNotification(
                data: json.decode(notificationResponse.payload ?? ""),
                appToken: InngageProperties.appToken,
              );
            }
            break;
          case NotificationResponseType.selectedNotificationAction:
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      if (InngageProperties.getDebugMode()) {
        debugPrint('onMessageOpenedApp ${event.from}');
        debugPrint('onMessageOpenedApp ${event.messageType}');
      }
      debugPrint('logx ${event.from}');
      Future.delayed(const Duration(seconds: 2)).then((value) {
        InngageInApp.show();
      });
      InngageNotification.openCommonNotification(
        data: event.data,
        appToken: InngageProperties.appToken,
      );
      try {
        firebaseListenCallback(event.data);
      } catch (e) {
        debugPrint('firebaseListenCallback error: $e');
      }
    });

    //request permission to iOS device
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true, // Required to display a heads up notification
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    var inappMessage = false;
    debugPrint('${message.data}');
    try {
      var rawData = message.data['additional_data'];
      var data = json.decode(rawData);

      inappMessage = data['inapp_message'];

      const storage = FlutterSecureStorage();
      await storage.write(key: "inapp", value: rawData);
    } catch (e) {
      debugPrint('logx listen $e');
    }
    debugPrint('logx listen $inappMessage');

    try {
      firebaseListenCallback(message.data);
    } catch (e) {
      debugPrint('firebaseListenCallback error: $e');
    }
  }
}
