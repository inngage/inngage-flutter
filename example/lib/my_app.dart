import 'dart:developer';
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

  initSdk() async {
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
      phoneNumber: '5511999999999',
      email: 'user01@inngage.com.br',
      blockDeepLink: false,
      firebaseListenCallback: (data) => log(data['additional_data']),
      navigatorKey: navigatorKey,
      inngageWebViewProperties: inngageWebViewProperties,
      requestAdvertiserId: false,
      requestGeoLocator: true,
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
