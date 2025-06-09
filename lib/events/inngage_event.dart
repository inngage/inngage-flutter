import 'package:flutter/foundation.dart';
import '../inngage_plugin.dart';

class InngageEvent {
  static Future<bool> sendEvent({
    required String eventName,
    required String appToken,
    String? identifier,
    String? registration,
    Map<String, dynamic> eventValues = const {},
    bool? conversionEvent,
    double? conversionValue,
    String? conversionNotId,
  }) async {
    if (identifier == null && registration == null) {
      debugPrint(
        'Unfortunately it was not possible send an event,'
        ' you need to declare the identifier or registration',
      );
    }
    try {
      await InngageSDK.registerEvent(
          registration: InngageProperties.registration,
          eventName: eventName,
          eventValues: eventValues,
          conversionEvent: conversionEvent,
          conversionNotId: conversionNotId,
          conversionValue: conversionValue);
    } catch (e) {
      return false;
    }
    return true;
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
