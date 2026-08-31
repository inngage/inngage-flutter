import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'home_page.dart';
import 'main.dart' show isInngageMessage;

String get kAppToken => dotenv.env['APP_TOKEN'] ?? '';
String get kIdentifier => dotenv.env['IDENTIFIER'] ?? '';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      appToken: kAppToken,
      customFields: {
        "nome": "User 01",
        "dt_nascimento": "01/09/1970",
        "genero": "M",
        "cartao": "N",
        "ultimo_abastecimento": "10/09/2018",
        "total_abastecido": "290,00"
      },
      friendlyIdentifier: kIdentifier,
      phoneNumber: '5511999999999',
      email: 'user01@inngage.com.br',
      blockDeepLink: false,
      firebaseListenCallback: (data) =>
          debugPrint('Callback: ${data['inngageData']}'),
      navigatorKey: navigatorKey,
      inngageWebViewProperties: inngageWebViewProperties,
      requestAdvertiserId: false,
      requestGeoLocator: true,
      initFirebase: false,
    );

    // Wire up the push notification handlers manually, as described in the docs
    // (https://dev.inngage.com.br/docs/flutter-sdk#possíveis-implementações).
    await _setupNotificationHandlers();

    InngageEvent.setDebugMode(true);
    InngageEvent.setUserPhone("5511999999999");
    await InngageEvent.sendEvent(
      eventName: 'MyOtherEventWithoutEventValues',
      appToken: kAppToken,
      identifier: InngageProperties.identifier,
      eventValues: {
        'location': '12312312312',
      },
    );
    await InngageEvent.sendEvent(
      eventName: 'send_test',
      appToken: kAppToken,
      identifier: kIdentifier,
    );
    InngageInApp.blockDeepLink = false;
    InngageInApp.deepLinkCallback = (link) {
      log('link:${link ?? ''}');
    };
  }

  /// Registers the subscriber (sends the FCM token to Inngage) and binds every
  /// Firebase Messaging state to the matching Inngage handler.
  Future<void> _setupNotificationHandlers() async {
    // 1. Sends the FCM token to Inngage and configures local notifications.
    await InngageNotificationMessage.registerSubscriber();

    // 2. App in foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (isInngageMessage(message)) {
        InngageNotificationMessage.handlerNotificationForeground(
          remoteMessage: message,
          backgroundColor: Colors.red,
        );
      }
    });

    // 3. Notification tapped with the app in background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (isInngageMessage(message)) {
        InngageNotificationMessage.handlerNotificationClick(
          remoteMessage: message,
        );
      }
    });

    // 4. Notification tapped with the app completely closed / terminated.
    FirebaseMessaging.instance.getInitialMessage().then((remoteMessage) {
      if (remoteMessage == null) return;
      if (isInngageMessage(remoteMessage)) {
        InngageNotificationMessage.handlerNotificationClosed(remoteMessage);
      }
    }).catchError((error) {
      debugPrint('Error on getInitialMessage: $error');
    });
  }

  @override
  void initState() {
    super.initState();

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
