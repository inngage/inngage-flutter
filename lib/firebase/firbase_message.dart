import 'dart:convert';
import 'dart:io';

import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
}
class InngageNotificationMessage {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void Function(dynamic data) firebaseListenCallback = (data) {};

  config() async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    FirebaseInAppMessaging m = FirebaseInAppMessaging.instance;
    _firebaseMessaging.getInitialMessage().then((value) {
      try {
        InngageNotification.openCommonNotification(
            data: value!.data,
            appToken: InngageProperties.appToken,
            inBack: true);
      } catch (e) {}
    });

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

   
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('launch_background');

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
        onDidReceiveBackgroundNotificationResponse:notificationTapBackground,

        /*        onSelectNotification: (String? payload) async {
       
      } */
      );
    
    FirebaseMessaging.onMessage.listen((message) async {
      if (InngageProperties.getDebugMode()) {
        print('onMessage ${message.data}');
      }

      var inappMessage = false;
      try {
        var data = json.decode(message.data['additional_data']);

        inappMessage = data['inapp_message'];

        var inAppModel = InAppModel.fromJson(data);

        if (inappMessage) {
          InngageDialog.showInAppDialog(inAppModel);
        }
      } catch (e) {}
      print('logx listen $inappMessage');
      if (inappMessage) {
      } else {
        if (Platform.isAndroid) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
                  'high_importance_channel', 'your channel name',
                  channelDescription: 'your channel description',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker');
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          final titleNotification = message.data['title'];
          final messageNotification = message.data['message'];
          await flutterLocalNotificationsPlugin.show(0, titleNotification,
              messageNotification, platformChannelSpecifics,
              payload: json.encode(message.data));
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      if (InngageProperties.getDebugMode()) {
        print('onMessageOpenedApp ${event.from}');
        print('onMessageOpenedApp ${event.messageType}');
      }
      print('logx ${event.from}');
      Future.delayed(Duration(seconds: 2)).then((value) {
        InngageInapp.show();
      });
      InngageNotification.openCommonNotification(
        data: event.data,
        appToken: InngageProperties.appToken,
      );
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

    //get device infos
    String? locale = await Devicelocale.currentLocale;
    List? languages = await Devicelocale.preferredLanguages;
    final deviceModel = await InngageUtils.getDeviceModel();
    final osDevice = await InngageUtils.getDeviceOS();
    final uuid = await InngageUtils.getUniqueId();
    final manufacturer = await InngageUtils.getDeviceManufacturer();
    final appVersion = await InngageUtils.getVersionApp();
    final advertiserId = await InngageUtils.getAdvertisingId();
    final idfa = await InngageUtils.getAdvertisingId();

    _firebaseMessaging.getToken().then(
      (String? registration) async {
        assert(registration != null);
        if (InngageProperties.getDebugMode()) {
          print("logx $registration");
        }
        final registerSubscriberRequest = RegisterSubscriberRequest(
            appInstalledIn: DateTime.now(),
            appToken: InngageProperties.appToken,
            appUpdatedIn: DateTime.now(),
            customField: InngageProperties.customFields,
            appVersion: appVersion,
            deviceModel: deviceModel,
            sdk: '1',
            phoneNumber: InngageProperties.phoneNumber,
            email: InngageProperties.email,
            deviceManufacturer: manufacturer,
            identifier: InngageProperties.identifier,
            osLanguage: languages![0] ?? '',
            osLocale: locale,
            osVersion: osDevice,
            registration: registration,
            uuid: uuid,
            platform: Platform.isAndroid ? 'Android' : 'iOS',
            advertiserId: advertiserId,
            idfa: idfa);

        //make request subscription to inngage backend
        await InngageProperties.inngageNetwork.subscription(
          subscription: SubscriptionRequest(
            registerSubscriberRequest: registerSubscriberRequest,
          ),
        );
      },
    );
  }

  /// Define a top-level named handler which background/terminated messages will
  /// call.
  ///
  /// To verify things are working, check out the native platform logs.
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    var inappMessage = false;
    try {
      final prefs = await SharedPreferences.getInstance();

      var data = json.decode(message.data['additional_data']);

      inappMessage = data['inapp_message'];

      if (inappMessage) {
        prefs.setString("inapp", message.data['additional_data']);
      }
    } catch (e) {
      print('logx listen $e');
    }
    print('logx listen $inappMessage');

    if (InngageProperties.getDebugMode()) {
      //print('_firebaseMessagingBackgroundHandler ${message.toString()}');
    }

    try {
      InngageNotification.openCommonNotification(
        data: message.data,
        appToken: InngageProperties.appToken,
      );
    } catch (e) {}

    try {
      firebaseListenCallback(message.data);
    } catch (e) {
      print('firebaseListenCallback error: $e');
    }
  }
}
