// To parse this JSON data, do
//
//     final subscription = subscriptionFromJson(jsonString);

import 'dart:convert';
import 'dart:io';

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
  RegisterSubscriberRequest(
      {this.appToken,
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
      this.attributionId,
      this.customField,
      this.phoneNumber,
      this.email,
      this.advertiserId,
      this.idfa});

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
  String? attributionId;
  Map<String, dynamic>? customField;
  String? phoneNumber;
  String? email;
  String? idfa;
  String? advertiserId;

  Map<String, dynamic> toJson() {
    var json = {
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
      "attribution_id": attributionId,
      "custom_field": customField,
      "phone": phoneNumber,
      "email": email,
    };
    if (Platform.isIOS) {
      json["idfa"] = idfa;
    } else {
      json["advertiser_id"] = advertiserId;
    }
    return json;
  }
}
