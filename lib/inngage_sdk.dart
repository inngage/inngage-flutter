import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inngage_plugin/dialogs/app_dialog.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:inngage_plugin/models/innapp_model.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:inngage_plugin/models/inngage_web_view_properties_model.dart';
import 'package:inngage_plugin/util/utils.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'firebase/firbase_message.dart';
import 'inapp/inapp_dialog.dart';

class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;
  InngageProperties inngageProperties = InngageProperties();

  static var notificationController =
      StreamController<RemoteMessage>.broadcast();

  static Future<void> subscribe(
      {required String appToken,
      required GlobalKey<NavigatorState> navigatorKey,
      String friendlyIdentifier = '',
      String? phoneNumber,
      Map<String, dynamic>? customFields,
      InngageWebViewProperties? inngageWebViewProperties,
      bool requestAdvertiserId = false}) async {
    try {
      //initialize firebase
      defaultApp = await Firebase.initializeApp();
    } catch (error) {
      if (InngageProperties.getDebugMode()) {
        print(error.toString());
      }
    }
    InngageUtils.requestAdvertiserId = requestAdvertiserId;
    //validation identifier
    if (friendlyIdentifier.isEmpty) {
      InngageProperties.identifier = await InngageUtils.getId();
    } else {
      InngageProperties.identifier = friendlyIdentifier;
    }
    InngageProperties.appToken = appToken;
    //set navigator key
    InngageProperties.navigatorKey = navigatorKey = navigatorKey;

    //set inngage web view properties
    if (inngageWebViewProperties != null) {
      InngageProperties.inngageWebViewProperties = inngageWebViewProperties;
    }
    //set inngage web view properties
    if (phoneNumber != null) {
      InngageProperties.phoneNumber = phoneNumber;
    }

    //set customFields properties
    if (customFields != null) {
      InngageProperties.customFields = customFields;
    }

    //FIREBASE
    InngageFirebaseMessage inngageFirebaseMessage = InngageFirebaseMessage();
    await inngageFirebaseMessage.config();

    try {
      final prefs = await SharedPreferences.getInstance();
      var datax = prefs.getString('inapp');
      var data = json.decode(datax!);

      var inappMessage = data['inapp_message'];

      if (inappMessage) {
        var inAppModel = InAppModel.fromJson(data);
        InngageDialog.showInAppDialog(inAppModel);
      }
    } catch (e) {
      print(e);
    }
  }
}
