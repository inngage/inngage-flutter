import 'package:flutter/foundation.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:inngage_plugin/services/inngage_service.dart';

class InngageEvent {
  static Future<bool> sendEvent({
    required String eventName,
    required String appToken,
    String? identifier,
    String? registration,
    Map<String, dynamic> eventValues = const {},
    bool conversionEvent = false,
    double conversionValue = 0,
    String conversionNotId = '',
  }) async {
    if (identifier == null && registration == null) {
      debugPrint(
        'Unfortunately it was not possible send an event,'
        ' you need to declare the identifier or registration',
      );
    }
    try {
      await InngageService.registerEvent(
        InngageProperties.registration,
        eventName,
        eventValues,
        conversionEvent,
        conversionValue,
        conversionNotId,
      );
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
