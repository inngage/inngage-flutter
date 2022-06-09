import 'package:flutter/material.dart';
import 'package:inngage_plugin/inapp/inapp_dialog.dart';
import 'package:inngage_plugin/models/innapp_model.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InngageDialog {
  static showInAppDialog(
      InAppModel inAppModel) async {
    try {
      final currentState = InngageProperties.navigatorKey.currentState;
      final _inngageWebViewProperties = InngageProperties.inngageWebViewProperties;
      showDialog(
          context: currentState!.context,
          builder: (_) {
            return InAppDialog(
                inAppModel: inAppModel,
                inngageWebViewProperties: _inngageWebViewProperties,
                navigatorKey: InngageProperties.navigatorKey);
          });
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('inapp');
    } catch (e) {}
  }
}
