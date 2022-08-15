import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      String? email,
      Function? firebaseListenCallback,
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
    if (email != null) {
      InngageProperties.email = email;
    }

    //set customFields properties
    if (customFields != null) {
      InngageProperties.customFields = customFields;
    }

    //FIREBASE
    InngageFirebaseMessage inngageFirebaseMessage = InngageFirebaseMessage();
    if(firebaseListenCallback != null){
      InngageFirebaseMessage.firebaseListenCallback = firebaseListenCallback as void Function(dynamic r);
    }
    
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
