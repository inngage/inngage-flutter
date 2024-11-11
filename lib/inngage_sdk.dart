import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/geolocator/geolocal.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;
  InngageProperties inngageProperties = InngageProperties();

  static var notificationController =
      StreamController<RemoteMessage>.broadcast();

  static void setDebugMode(bool value) {
    InngageProperties.debugMode = value;
  }

  static Future<void> subscribe({
    required String appToken,
    required GlobalKey<NavigatorState> navigatorKey,
    String friendlyIdentifier = '',
    String? attributionId,
    String? phoneNumber,
    String? email,
    bool blockDeepLink = false,
    Function? firebaseListenCallback,
    Map<String, dynamic>? customFields,
    InngageWebViewProperties? inngageWebViewProperties,
    bool requestAdvertiserId = false,
    bool requestGeoLocator = false,
  }) async {
    try {
      //initialize firebase
      defaultApp = await Firebase.initializeApp();
      if (requestGeoLocator) {
        var result = await GeoLocal.handlePermission();
        InngageProperties.latitude = result.latitude.toString();
        InngageProperties.longitude = result.longitude.toString();
      }
    } catch (error) {
      if (InngageProperties.getDebugMode()) {
        debugPrint(error.toString());
      }
    }
    InngageUtils.requestAdvertiserId = requestAdvertiserId;

    //validation identifier
    if (friendlyIdentifier.isEmpty) {
      InngageProperties.identifier = await InngageUtils.getUniqueId();
    } else {
      InngageProperties.identifier = friendlyIdentifier;
    }
    InngageProperties.appToken = appToken;
    InngageProperties.blockDeepLink = blockDeepLink;
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
    if (firebaseListenCallback != null) {
      InngageNotificationMessage.firebaseListenCallback =
          firebaseListenCallback as void Function(dynamic r);
    }

    if (attributionId != null) {
      InngageProperties.attributionId = attributionId;
    }
  }
}
