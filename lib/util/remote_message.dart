import 'package:firebase_messaging/firebase_messaging.dart';

extension RemoteMessageX on RemoteMessage {
  bool get hasInngageData =>
      data.containsKey("inngageData") ||
      data["provider"] == "inngage";
}
