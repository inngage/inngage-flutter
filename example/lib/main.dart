import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

import 'my_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}
