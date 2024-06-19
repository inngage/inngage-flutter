import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin_example/firebase_options.dart';
import 'my_app.dart';

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
