import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_sdk.dart';

import 'my_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
  final json = {
    "nome": "User 01",
    "dt_nascimento": "01/09/1970",
    "genero": "M",
    "cartao": "N",
    "ultimo_abastecimento": "10/09/2018",
    "total_abastecido": "290,00"
  };

  final inngageWebViewProperties = InngageWebViewProperties(
    appBarColor: Colors.pink,
    appBarText: Text(
      'AppTitle',
    ),
    backgroundColor: Colors.white,
    loaderColor: Colors.pink,
    debuggingEnabled: true,
    withJavascript: true,
    withLocalStorage: true,
    withZoom: true,
  );
  await InngageSDK.subscribe(
    appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
    friendlyIdentifier: 'user23@gmail.com',
    customFields: json,
    phoneNumber: '11-959821612',
    navigatorKey: navigatorKey,
    inngageWebViewProperties: inngageWebViewProperties,
  );
  InngageSDK.setDebugMode(true);
  InngageSDK.setUserPhone("67587787");
  await InngageSDK.sendEvent(
    eventName: 'MyOtherEventWithoutEventValues',
    appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
    identifier: 'user01@gmail.com',
    eventValues: {
      'location': '12312312312',
    },
  );
  await InngageSDK.sendEvent(
    eventName: 'send_test',
    appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
    identifier: 'user23@gmail.com',
  );
  runApp(MyApp());
}
