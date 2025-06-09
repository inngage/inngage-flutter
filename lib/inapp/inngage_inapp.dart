import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/dialogs/app_dialog.dart';
import 'package:inngage_plugin/data/model/inapp/innapp_model.dart';

class InngageInApp {
  static bool blockDeepLink = false;
  static Function deepLinkCallback = () {};

  static show() async {
    const storage = FlutterSecureStorage();

    String? data = await storage.read(key: "inapp");
    if (data != null) {
      try {
        var xdata = json.decode(data.toString());

        var inappMessage = xdata['inapp_message'];

        if (inappMessage) {
          var inAppModel = InAppModel.fromJson(xdata);
          InngageDialog.showInAppDialog(inAppModel);
        }
      } catch (e) {
        log(e.toString());
      }
    }
  }
}
