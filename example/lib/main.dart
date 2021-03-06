import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_sdk.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();

  final json = {
    "nome": "Leonardo",
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
    appToken: 'MyAppToken',
    friendlyIdentifier: 'user@gmail.com',
    customFields: json,
    navigatorKey: navigatorKey,
    inngageWebViewProperties: inngageWebViewProperties,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Inngage SDK '),
        ),
      ),
    );
  }
}
