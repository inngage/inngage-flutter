import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/firebase/notification_utils.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

// Still extends ChangeNotifier only for backward compatibility: nothing ever
// calls notifyListeners(), so listeners never fire. Will stop extending it
// in 4.0.
class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;

  @Deprecated('Never emitted any events and will be removed in 4.0. '
      'Use InngageSDK.subscribe\'s firebaseListenCallback instead.')
  static final StreamController<RemoteMessage> notificationController =
      StreamController<RemoteMessage>.broadcast();

  @Deprecated('InngageProperties is an all-static class; access it directly. '
      'This instance field will be removed in 4.0.')
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

    // The push-based In-App flow (< 4.0.0) persisted payloads under these
    // keys; clear them so nothing stale survives an SDK upgrade.
    await InngageProperties.inngageService.inAppLocalStore
        .clearLegacyInAppKeys();

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
      // Function.apply accepts any single-argument callback signature, unlike
      // a hard cast to `void Function(dynamic)`, which throws at subscribe
      // time for callbacks typed as `void Function(Map<String, dynamic>)`.
      InngageNotificationMessage.onNotificationClick =
          (data) => Function.apply(firebaseListenCallback, [data]);
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

  /// Writes custom fields to the subscriber on the Inngage API right away
  /// (`POST /v4/subscription/addCustomField`), with no session side effects:
  /// no device is touched and no event is emitted.
  ///
  /// [identifier] is the person's business identifier (e-mail, CPF, customer
  /// id) and is required: without it the fields would silently land on the
  /// anonymous device subscriber. On success it also becomes the SDK's
  /// current identifier (this is the replacement for the deprecated
  /// `InngageUtils.addUserData`). Field names must exist in the app's
  /// custom-field catalog on the Inngage platform; unknown names are silently
  /// ignored by the API. [identity] maps external system ids, e.g.
  /// `{'vtex': '7a3c9f1e'}`.
  ///
  /// On success the fields are merged into `InngageProperties.customFields`
  /// and [email]/[phoneNumber], when given, update their properties, so the
  /// next subscriber registration carries the same data. Returns `false` when
  /// nothing was sent or the API did not accept the request (failures are
  /// logged, never thrown).
  static Future<bool> addCustomField({
    required String identifier,
    required Map<String, dynamic> customField,
    String? email,
    String? phoneNumber,
    Map<String, String>? identity,
  }) {
    return InngageProperties.inngageService.addCustomField(
      identifier: identifier,
      customField: customField,
      email: email,
      phoneNumber: phoneNumber,
      identity: identity,
    );
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

  static Future<bool> registerEvent({
    required String registration,
    required String eventName,
    required Map<String, dynamic> eventValues,
    String? appToken,
    String? identifier,
    bool? conversionEvent,
    double? conversionValue,
    String? conversionNotId,
  }) async {
    return InngageProperties.inngageService.registerEvent(
      registration,
      eventName,
      eventValues,
      conversionEvent ?? false,
      conversionValue ?? 0,
      conversionNotId ?? '',
      appToken: appToken,
      identifier: identifier,
    );
  }
}
