// domain/services/inngage_service.dart
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/local/inapp_local_store.dart';
import '../data/model/inapp/inapp_message_v2.dart';
import '../data/model/inapp/object_message_request.dart';
import '../data/model/inngage/add_custom_field_request.dart';
import '../data/model/inngage/event_request.dart';
import '../data/model/inngage/subscription_request.dart';
import '../data/model/inngage/subscription_response.dart';
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
      osName: InngageUtils.getOsName(),
      osVersion: await InngageUtils.getDeviceOS(),
      registration: registration,
      uuid: await InngageUtils.getUniqueId(),
      platform: InngageUtils.getPlatformName(),
      advertiserId: await InngageUtils.getAdvertisingId(),
      idfa: await InngageUtils.getAdvertisingId(),
      lat: InngageProperties.latitude,
      long: InngageProperties.longitude,
      optIn: await InngageUtils.getPushOptIn(),
    );

    final response = await subscriptionService.subscription(
      SubscriptionRequest(registerSubscriberRequest: request),
    );
    await persistSubscriptionResponse(response);
  }

  /// Persists what the In-App `/objectMessage` flow needs from a subscription
  /// response — the `appId` plus the registration token, both kept across
  /// sessions — and the `subscriberId` (exposed via
  /// [InngageProperties.subscriberId]). A `null`/unparseable response leaves
  /// the stored values untouched.
  @visibleForTesting
  Future<SubscriptionResponse> persistSubscriptionResponse(
      Map<String, dynamic>? response) async {
    final parsed = SubscriptionResponse.fromJson(response);

    final subscriberId = parsed.subscriberId;
    if (subscriberId != null) {
      InngageProperties.subscriberId = subscriberId;
    }

    final appId = parsed.appId;
    final effectiveRegistration = InngageProperties.registration;
    if (appId != null && effectiveRegistration.isNotEmpty) {
      await inAppLocalStore.saveSubscription(
        appId: appId,
        registration: effectiveRegistration,
        subscriberId: subscriberId,
      );
    }
    return parsed;
  }

  /// Writes [customField] (and optionally contact/identities) to the
  /// subscriber identified by [identifier] through
  /// `/v4/subscription/addCustomField`, which has no session side effects.
  ///
  /// [identifier] is the person's business identifier (e-mail, CPF, customer
  /// id). It is required so the fields never silently land on the anonymous
  /// (device-uuid) subscriber that `subscribe` registers before login.
  ///
  /// On success [identifier] becomes [InngageProperties.identifier], the
  /// fields are merged into [InngageProperties.customFields] and
  /// [email]/[phoneNumber], when given, update their properties, so the next
  /// subscriber registration carries the same data. Returns `false` without
  /// calling the API when [customField] or [identifier] is empty, and when
  /// the API does not answer 2xx.
  Future<bool> addCustomField({
    required String identifier,
    required Map<String, dynamic> customField,
    String? email,
    String? phoneNumber,
    Map<String, String>? identity,
  }) async {
    final resolvedIdentifier = identifier.trim();

    if (customField.isEmpty) {
      debugPrint('Inngage: addCustomField skipped — customField is empty.');
      return false;
    }
    if (resolvedIdentifier.isEmpty) {
      debugPrint('Inngage: addCustomField skipped — identifier is empty.');
      return false;
    }
    if (InngageProperties.appToken.isEmpty) {
      debugPrint('Inngage: addCustomField skipped — no appToken configured. '
          'Call InngageSDK.subscribe first.');
      return false;
    }

    final registration = InngageProperties.registration;
    final response = await subscriptionService.addCustomField(
      AddCustomFieldRequest(
        appToken: InngageProperties.appToken,
        identifier: resolvedIdentifier,
        customField: customField,
        email: email,
        phoneNumber: phoneNumber,
        identity: identity,
        registration: registration.isEmpty ? null : registration,
      ),
    );
    if (response == null) return false;

    InngageProperties.customFields = {
      ...InngageProperties.customFields,
      ...customField,
    };
    InngageProperties.identifier = resolvedIdentifier;
    if (email != null && email.isNotEmpty) InngageProperties.email = email;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      InngageProperties.phoneNumber = phoneNumber;
    }

    // The response carries the appId at its root; keep the In-App store in
    // sync in case the subscription never completed on this install.
    await persistSubscriptionResponse(response);
    return true;
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

  /// See [SubscriptionResponse.extractAppId].
  @visibleForTesting
  static int? extractAppId(Map<String, dynamic>? response) =>
      SubscriptionResponse.extractAppId(response);

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
