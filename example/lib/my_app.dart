import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initFirebaseHandlers() async {
    final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

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
      firebaseListenCallback: (data) => log(data['additional_data']),
      navigatorKey: navigatorKey,
      requestAdvertiserId: false,
      requestGeoLocator: true,
      initFirebase: false,
    );

    _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();

    InngageNotificationMessage.registerSubscriber(fcmToken: fcmToken!);

    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      final messageData = message.data;
      final hasInngageData = messageData.containsKey("inngageData") || messageData["provider"] == "inngage";

      if(hasInngageData){
        InngageNotificationMessage.handlerNotificationForeground(remoteMessageData: messageData);
      } else {
        _handlerCustomNotificationForeground(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final messageData = message.data;
      final hasInngageData = messageData.containsKey("inngageData") || messageData["provider"] == "inngage";

      if(hasInngageData){
        InngageNotificationMessage.handlerNotificationClick(remoteMessage: message);
      } else {
        _handlerCustomNotificationClick(message);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((remoteMessage) {
      if (remoteMessage == null) return;

      final messageData = remoteMessage.data;
      final hasInngageData = messageData.containsKey("inngageData") || messageData["provider"] == "inngage";

      if (hasInngageData) {
        InngageNotificationMessage.handlerNotificationClosed(remoteMessage);
      } else {
        _handlerCustomNotificationClick(remoteMessage);
      }
    }).catchError((error) {
      debugPrint("Error on getInitialMessage: $error");
    });
  }

  Future<void> _handlerCustomNotificationBackground(RemoteMessage message) async {
    await InngageNotificationMessage.handlerNotificationBackground(remoteMessageData: message.data);
  }

  void _handlerCustomNotificationForeground(RemoteMessage message){
    debugPrint("Title: ${message.notification!.title} and Body: ${message.notification!.body}");
  }

  void _handlerCustomNotificationClick(RemoteMessage message){
    debugPrint("Title: ${message.notification!.title} and Body: ${message.notification!.body}");
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
      firebaseListenCallback: (data) => log(data['additional_data']),
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

    initFirebaseHandlers();
    // initSdk();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const InngageInAppWidget(child: HomePage()),
    );
  }
}
