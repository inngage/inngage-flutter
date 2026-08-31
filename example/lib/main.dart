import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'my_app.dart';
import './firebase_options.dart';

/// Returns `true` when the message was sent by Inngage and therefore should be
/// handled by the SDK.
bool isInngageMessage(RemoteMessage message) {
  final data = message.data;
  return data.containsKey('inngageData') || data['provider'] == 'inngage';
}

/// Handles in-app / push messages while the app is in the background or
/// terminated. Must be a top-level (or static) function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (isInngageMessage(message)) {
    await InngageNotificationMessage.handlerNotificationBackground(
      remoteMessageData: message.data,
    );
  }
}

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background handler before the app starts.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(const MyApp());
}
