import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/dialogs/app_dialog.dart';
import 'package:inngage_plugin/models/innapp_model.dart';

import '../firebase/firbase_message.dart';

class InngageInapp {

  static bool blockDeepLink = false;
  static Function deepLinkCallback = (){};


  static show() async {
    final storage =  FlutterSecureStorage();

    String? data = await storage.read(key: "inapp");
    if (data != null) {
      try {
        var xdata = json.decode(data.toString());

        var inappMessage = xdata['inapp_message'];

        if (inappMessage) {
          var inAppModel = InAppModel.fromJson(xdata);
          InngageDialog.showInAppDialog(inAppModel);
        }
      } catch (e) {}
    } 
  }
}
