import 'dart:convert';

import 'package:inngage_plugin/dialogs/app_dialog.dart';
import 'package:inngage_plugin/models/innapp_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InngageInapp {
  static show() async {
    final prefs = await SharedPreferences.getInstance();
    var data = prefs.getString("inapp");

    if (data != null) {
      try {
        var xdata = json.decode(data);

        var inappMessage = xdata['inapp_message'];

        if (inappMessage) {
          var inAppModel = InAppModel.fromJson(xdata);
          InngageDialog.showInAppDialog(inAppModel);
        }
      } catch (e) {}
    }
  }
}
