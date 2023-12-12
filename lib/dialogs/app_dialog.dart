import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inapp/inapp_dialog.dart';
import 'package:inngage_plugin/models/innapp_model.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';

class InngageDialog {
  static showInAppDialog(InAppModel inAppModel) async {
    const storage = FlutterSecureStorage();
    final currentState = InngageProperties.navigatorKey.currentState;
    try {
      if (Navigator.canPop(currentState!.context)) {
        Navigator.pop(currentState.context);
        await storage.delete(key: 'inapp');
      }

      final dialog = await showDialog(
          context: currentState.context,
          builder: (context) {
            return InAppDialog(inAppModel: inAppModel);
          });

      if (dialog == null) {
        await storage.delete(key: 'inapp');
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
