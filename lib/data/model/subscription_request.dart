// To parse this JSON data, do
//
//     final subscription = subscriptionFromJson(jsonString);

import 'dart:convert';

String subscriptionToJson(SubscriptionRequest data) =>
    json.encode(data.toJson());

class SubscriptionRequest {
  SubscriptionRequest({
    this.registerSubscriberRequest,
  });

  RegisterSubscriberRequest? registerSubscriberRequest;

  Map<String, dynamic> toJson() => {
        "registerSubscriberRequest": registerSubscriberRequest!.toJson(),
      };
}

class RegisterSubscriberRequest {
  RegisterSubscriberRequest({
    this.appToken,
    this.identifier,
    this.registration,
    this.platform,
    this.sdk,
    this.deviceModel,
    this.deviceManufacturer,
    this.osLocale,
    this.osLanguage,
    this.osVersion,
    this.appVersion,
    this.appInstalledIn,
    this.appUpdatedIn,
    this.uuid,
    this.customField,
    this.phoneNumber,
  });

  String? appToken;
  String? identifier;
  String? registration;
  String? platform;
  String? sdk;
  String? deviceModel;
  String? deviceManufacturer;
  String? osLocale;
  String? osLanguage;
  String? osVersion;
  String? appVersion;
  DateTime? appInstalledIn;
  DateTime? appUpdatedIn;
  String? uuid;
  Map<String, dynamic>? customField;
  String? phoneNumber;

  Map<String, dynamic> toJson() => {
        "app_token": appToken,
        "identifier": identifier,
        "registration": registration,
        "platform": platform,
        "sdk": sdk,
        "device_model": deviceModel,
        "device_manufacturer": deviceManufacturer,
        "os_locale": osLocale,
        "os_language": osLanguage,
        "os_version": osVersion,
        "app_version": appVersion,
        "app_installed_in": appInstalledIn!.toIso8601String(),
        "app_updated_in": appUpdatedIn!.toIso8601String(),
        "uuid": uuid,
        "custom_field": customField,
        "phone": phoneNumber
      };
}
