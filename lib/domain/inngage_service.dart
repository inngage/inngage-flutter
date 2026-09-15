// domain/services/inngage_service.dart
import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/api/inngage_network.dart';
import '../data/local/inapp_local_store.dart';
import '../data/model/inapp/inapp_message_v2.dart';
import '../data/model/inapp/object_message_request.dart';
import '../data/model/inngage/event_request.dart';
import '../data/model/inngage/subscription_request.dart';
import '../../shared/inngage_properties.dart';
import '../shared/inngage_utils.dart';
import 'services/event_service.dart';
import 'services/inapp_message_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';

class InngageService {
  final SubscriptionService subscriptionService;
  final NotificationService notificationService;
  final EventService eventService;
  final InAppMessageService inAppMessageService;
  final InAppLocalStore inAppLocalStore;

  InngageService({
    required this.subscriptionService,
    required this.notificationService,
    required this.eventService,
    required this.inAppMessageService,
    this.inAppLocalStore = const InAppLocalStore(),
  });

  Future<void> registerSubscriber(String? registration) async {
    if (registration != null && registration.isNotEmpty) {
      InngageProperties.registration = registration;
    }

    final request = RegisterSubscriberRequest(
      appInstalledIn: DateTime.now(),
      appUpdatedIn: DateTime.now(),
      appToken: InngageProperties.appToken,
      customField: InngageProperties.customFields,
      appVersion: await InngageUtils.getVersionApp(),
      deviceModel: await InngageUtils.getDeviceModel(),
      sdk: AppConstants.sdkVersion,
      phoneNumber: InngageProperties.phoneNumber,
      email: InngageProperties.email,
      deviceManufacturer: await InngageUtils.getDeviceManufacturer(),
      identifier: InngageProperties.identifier,
      osLanguage: (await Devicelocale.preferredLanguages)?.first ?? "",
      osLocale: await Devicelocale.currentLocale,
      osVersion: await InngageUtils.getDeviceOS(),
      registration: registration,
      uuid: await InngageUtils.getUniqueId(),
      platform: Platform.isAndroid ? 'Android' : 'iOS',
      advertiserId: await InngageUtils.getAdvertisingId(),
      idfa: await InngageUtils.getAdvertisingId(),
      lat: InngageProperties.latitude,
      long: InngageProperties.longitude,
    );

    final response = await subscriptionService.subscription(
      SubscriptionRequest(registerSubscriberRequest: request),
    );

    // The In-App /objectMessage flow needs the app_id returned by the
    // subscription plus the registration token, both persisted across
    // sessions.
    final appId = extractAppId(response);
    final effectiveRegistration = InngageProperties.registration;
    if (appId != null && effectiveRegistration.isNotEmpty) {
      await inAppLocalStore.saveSubscription(
        appId: appId,
        registration: effectiveRegistration,
      );
    }
  }

  /// Fetches the In-App message to display right now, or `null` when there is
  /// none (missing prerequisites, delivery failure, or suppressed response).
  Future<InAppMessageV2?> fetchInAppMessage() async {
    final appId = await inAppLocalStore.readAppId();
    final registration = await inAppLocalStore.readRegistration();

    if (appId == null || registration == null || registration.isEmpty) {
      debugPrint(
          'Inngage: In-App fetch skipped — app_id/registration not available. '
          'Make sure the subscription has completed at least once before '
          'requesting In-App messages.');
      return null;
    }

    final firstAccess = await inAppLocalStore.readFirstAccess();
    final response = await inAppMessageService.getObjectMessage(
      ObjectMessageRequest(
        appId: appId,
        registration: registration,
        firstAccess: firstAccess,
      ),
    );

    // null means the request never got a 200 back, so firstAccess must not be
    // consumed — a failed first attempt still counts as first access.
    if (response == null) return null;

    if (firstAccess) {
      await inAppLocalStore.markFirstAccessConsumed();
    }
    return InAppMessageV2.fromResponse(response);
  }

  /// Counts an In-App display. No-op (returns `false`) without a [notId].
  Future<bool> trackInAppImpression(String notId) async {
    if (notId.isEmpty) return false;
    return inAppMessageService.trackInAppImpression(notId);
  }

  /// Counts an In-App click at [clickSource] (`card`, `button`, `button_up`
  /// or `button_down`). No-op (returns `false`) without a [notId].
  Future<bool> trackInAppClick(String notId, String clickSource) async {
    if (notId.isEmpty) return false;
    return inAppMessageService.trackInAppClick(notId, clickSource);
  }

  /// The subscription response carries the app id in the `app_id` field —
  /// in production it arrives as `appId`, nested in
  /// `registerSubscriberResponse`, so both spellings are accepted (an int,
  /// possibly serialized as string). As a fallback it is also searched in
  /// nested objects and in a plain-text body.
  @visibleForTesting
  static int? extractAppId(Map<String, dynamic>? response) {
    if (response == null) return null;

    final direct = response['app_id'] ?? response['appId'];
    if (direct is int) return direct;
    if (direct is String) return int.tryParse(direct);

    for (final value in response.values) {
      if (value is Map<String, dynamic>) {
        final nested = extractAppId(value);
        if (nested != null) return nested;
      }
    }

    final rawBody = response[InngageNetwork.rawBodyKey];
    if (rawBody is String) {
      final match = RegExp(r'app_?id\D{0,10}(\d+)', caseSensitive: false)
          .firstMatch(rawBody);
      if (match != null) return int.tryParse(match.group(1)!);
    }
    return null;
  }

  Future<void> registerNotification(
      {required String notId, required String appToken}) async {
    await notificationService.sendNotification(notId, appToken);
  }

  Future<bool> registerEvent(
    String registration,
    String eventName,
    Map<String, dynamic> eventValues,
    bool conversionEvent,
    double conversionValue,
    String conversionNotId, {
    String? appToken,
    String? identifier,
  }) async {
    final eventRequest = NewEventRequest(
      appToken: appToken ?? InngageProperties.appToken,
      identifier: identifier ?? InngageProperties.identifier,
      registration: registration,
      eventName: eventName,
      eventValues: eventValues,
      conversionEvent: conversionEvent,
      conversionNotId: conversionNotId,
      conversionValue: conversionValue,
    );

    return eventService.sendEvent(Event(newEventRequest: eventRequest));
  }
}
