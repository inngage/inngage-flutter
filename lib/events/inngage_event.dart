import 'package:flutter/foundation.dart';
import '../inngage_plugin.dart';

class InngageEvent {
  /// Sends an event to the Inngage API.
  ///
  /// [appToken] is optional: when omitted, the token configured via
  /// `InngageSDK.subscribe` is used.
  static Future<bool> sendEvent({
    required String eventName,
    String? appToken,
    String? identifier,
    String? registration,
    Map<String, dynamic> eventValues = const {},
    bool? conversionEvent,
    double? conversionValue,
    String? conversionNotId,
  }) async {
    final resolvedAppToken = appToken ??
        (InngageProperties.appToken.isNotEmpty
            ? InngageProperties.appToken
            : null);
    if (resolvedAppToken == null) {
      debugPrint(
        'Inngage: cannot send event "$eventName", no appToken was provided '
        'and none is configured via InngageSDK.subscribe.',
      );
      return false;
    }

    if (identifier == null && registration == null) {
      debugPrint(
        'Unfortunately it was not possible send an event,'
        ' you need to declare the identifier or registration',
      );
    }

    final resolvedRegistration = registration ??
        (InngageProperties.registration.isNotEmpty
            ? InngageProperties.registration
            : '');
    final resolvedIdentifier = identifier ?? InngageProperties.identifier;

    try {
      return await InngageSDK.registerEvent(
        registration: resolvedRegistration,
        appToken: resolvedAppToken,
        identifier: resolvedIdentifier,
        eventName: eventName,
        eventValues: eventValues,
        conversionEvent: conversionEvent,
        conversionNotId: conversionNotId,
        conversionValue: conversionValue,
      );
    } catch (e) {
      return false;
    }
  }

  static void setCustomFields({required Map<String, dynamic> customFields}) {
    InngageProperties.customFields = customFields;
  }

  static void setDebugMode(bool value) {
    InngageProperties.debugMode = value;
  }

  static void setUserPhone(String number) {
    InngageProperties.phoneNumber = number;
    if (InngageProperties.debugMode) {
      debugPrint("user phone number: ${InngageProperties.phoneNumber}");
    }
  }

  static void setAttributionId(String id) {
    InngageProperties.attributionId = id;
  }
}
