import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inapp/inapp_dialog.dart';

import '../inngage_plugin.dart';

class InngageDialog {
  static showInAppDialog(InAppModel inAppModel) async {
    const storage = FlutterSecureStorage();
    final currentState = InngageProperties.navigatorKey.currentState;
    try {
      if (Navigator.canPop(currentState!.context)) {
        Navigator.pop(currentState.context);
        await storage.delete(key: 'inapp');
      }
      if (currentState.mounted) {
        final dialog = await showDialog(
            context: currentState.context,
            builder: (context) {
              return InAppDialog(inAppModel: inAppModel);
            });

        if (dialog == null) {
          await storage.delete(key: 'inapp');
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
