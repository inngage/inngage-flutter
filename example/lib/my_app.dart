import 'package:flutter/material.dart';
import 'package:inngage_plugin/inapp/inngage_inapp.dart';
import 'main.dart';
import 'home_page.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((value) {
      InngageInapp.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: HomePage(),
    );
  }
}
