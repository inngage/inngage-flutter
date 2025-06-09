import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/firebase/notification_utils.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;
  static final StreamController<RemoteMessage> notificationController =
      StreamController<RemoteMessage>.broadcast();

  final InngageProperties inngageProperties = InngageProperties();

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
    bool initFirebase = true,
  }) async {
    try {
      if (initFirebase) {
        defaultApp = await Firebase.initializeApp();
      }

      if (requestGeoLocator) {
        final result = await GeoLocal.handlePermission();
        InngageProperties.latitude = result.latitude.toString();
        InngageProperties.longitude = result.longitude.toString();
      }
    } catch (error) {
      if (InngageProperties.getDebugMode()) {
        debugPrint('Erro ao inicializar Firebase ou Geolocalização: $error');
      }
    }

    InngageUtils.requestAdvertiserId = requestAdvertiserId;
    await _configureProperties(
      appToken: appToken,
      navigatorKey: navigatorKey,
      friendlyIdentifier: friendlyIdentifier,
      attributionId: attributionId,
      phoneNumber: phoneNumber,
      email: email,
      blockDeepLink: blockDeepLink,
      customFields: customFields,
      inngageWebViewProperties: inngageWebViewProperties,
      firebaseListenCallback: firebaseListenCallback,
    );
  }

  static Future<void> _configureProperties({
    required String appToken,
    required GlobalKey<NavigatorState> navigatorKey,
    required String friendlyIdentifier,
    String? attributionId,
    String? phoneNumber,
    String? email,
    bool blockDeepLink = false,
    Map<String, dynamic>? customFields,
    InngageWebViewProperties? inngageWebViewProperties,
    Function? firebaseListenCallback,
  }) async {
    InngageProperties.appToken = appToken;
    InngageProperties.blockDeepLink = blockDeepLink;
    InngageProperties.navigatorKey = navigatorKey;
    InngageProperties.identifier = friendlyIdentifier.isNotEmpty
        ? friendlyIdentifier
        : await InngageUtils.getUniqueId();

    if (attributionId != null) {
      InngageProperties.attributionId = attributionId;
    }
    if (phoneNumber != null) {
      InngageProperties.phoneNumber = phoneNumber;
    }
    if (email != null) {
      InngageProperties.email = email;
    }
    if (customFields != null) {
      InngageProperties.customFields = customFields;
    }
    if (inngageWebViewProperties != null) {
      InngageProperties.inngageWebViewProperties = inngageWebViewProperties;
    }
    if (firebaseListenCallback != null) {
      InngageNotificationMessage.onNotificationClick =
          firebaseListenCallback as void Function(dynamic);
    }
  }

  static void updateStatusMessage(String? payload) {
    if (payload != null) {
      final notificationResponse =
          Map<String, dynamic>.from(json.decode(payload));
      openNotification(notificationResponse);
    }
  }

  static Future<void> registerSubscriber(String? registration) async {
    await InngageProperties.inngageService.registerSubscriber(registration);
  }

  static Future<void> registerNotification({
    required String notId,
    required String appToken,
  }) async {
    await InngageProperties.inngageService.registerNotification(
      notId: notId,
      appToken: appToken,
    );
  }

  static Future<void> registerEvent({
    required String registration,
    required String eventName,
    required Map<String, dynamic> eventValues,
    bool? conversionEvent,
    double? conversionValue,
    String? conversionNotId,
  }) async {
    await InngageProperties.inngageService.registerEvent(
      registration,
      eventName,
      eventValues,
      conversionEvent ?? false,
      conversionValue ?? 0,
      conversionNotId ?? '',
    );
  }
}
