import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final storage = const FlutterSecureStorage();

  void initFirebaseHandlers() async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_handlerCustomNotificationBackground);

    InngageEvent.setDebugMode(true);

    await InngageSDK.subscribe(
      appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
      customFields: {
        "nome": "User 01",
        "dt_nascimento": "01/09/1970",
        "genero": "M",
        "cartao": "N",
        "ultimo_abastecimento": "10/09/2018",
        "total_abastecido": "290,00"
      },
      friendlyIdentifier: "moura.bsaulo@gmail.com",
      phoneNumber: '5511999999999',
      email: 'user01@inngage.com.br',
      blockDeepLink: false,
      firebaseListenCallback: (data) async {
        final notId = data['notId'];
        if (notId != null) {
          await storage.write(key: 'conversionNotId', value: notId);
        }
      },
      navigatorKey: navigatorKey,
      requestAdvertiserId: false,
      requestGeoLocator: true,
      initFirebase: false,
    );

    _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();

    InngageSDK.registerSubscriber(fcmToken!);

    debugPrint(fcmToken);

    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.notificationResponseType ==
                NotificationResponseType.selectedNotification &&
            response.payload != null) {
          InngageSDK.updateStatusMessage(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.hasInngageData) {
        InngageHandlersNotification.handleForegroundNotification(
            remoteMessage: message);
      } else {
        _handlerCustomNotificationForeground(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.hasInngageData) {
        InngageHandlersNotification.handleClickNotification(
            remoteMessage: message);
      } else {
        _handlerCustomNotificationClick(message);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((remoteMessage) {
      if (remoteMessage == null) return;

      if (remoteMessage.hasInngageData) {
        InngageHandlersNotification.handleTerminatedNotification(
            remoteMessage: remoteMessage);
      } else {
        _handlerCustomNotificationClick(remoteMessage);
      }
    }).catchError((error) {
      debugPrint("Error on getInitialMessage: $error");
    });
  }

  Future<void> _handlerCustomNotificationBackground(
      RemoteMessage message) async {
    await InngageHandlersNotification.handleBackgroundNotification(
        message.data);
  }

  void _handlerCustomNotificationForeground(RemoteMessage message) {
    debugPrint(
        "Title: ${message.notification!.title} and Body: ${message.notification!.body}");
  }

  void _handlerCustomNotificationClick(RemoteMessage message) {
    debugPrint(
        "Title: ${message.notification!.title} and Body: ${message.notification!.body}");
  }

  void initSdk() async {
    final inngageWebViewProperties = InngageWebViewProperties(
      appBarColor: Colors.pink,
      appBarText: const Text('AppTitle'),
      backgroundColor: Colors.white,
      loaderColor: Colors.pink,
      debuggingEnabled: true,
      withJavascript: true,
      withLocalStorage: true,
      withZoom: true,
    );
    await InngageSDK.subscribe(
      appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
      customFields: {
        "nome": "User 01",
        "dt_nascimento": "01/09/1970",
        "genero": "M",
        "cartao": "N",
        "ultimo_abastecimento": "10/09/2018",
        "total_abastecido": "290,00"
      },
      friendlyIdentifier: "moura.bsaulo@gmail.com",
      phoneNumber: '5511999999999',
      email: 'user01@inngage.com.br',
      blockDeepLink: false,
      firebaseListenCallback: (data) =>
          debugPrint('Callback: ${data['notId']}'),
      navigatorKey: navigatorKey,
      inngageWebViewProperties: inngageWebViewProperties,
      requestAdvertiserId: false,
      requestGeoLocator: true,
      initFirebase: false,
    );
    await InngageNotificationMessage.subscribe(backgroundIcon: Colors.red);
    InngageEvent.setDebugMode(true);
    InngageEvent.setUserPhone("5511999999999");
    await InngageEvent.sendEvent(
      eventName: 'MyOtherEventWithoutEventValues',
      appToken: InngageProperties.appToken,
      identifier: InngageProperties.identifier,
      eventValues: {
        'location': '12312312312',
      },
    );
    await InngageEvent.sendEvent(
      eventName: 'send_test',
      appToken: InngageProperties.appToken,
      identifier: InngageProperties.identifier,
    );
    InngageInApp.blockDeepLink = true;
    InngageInApp.deepLinkCallback = (link) {
      log('link:' + link);
    };
  }

  @override
  void initState() {
    super.initState();

    // initFirebaseHandlers();
    initSdk();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const InngageInAppWidget(child: HomePage()),
    );
  }
}
