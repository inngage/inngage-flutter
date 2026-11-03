// To parse this JSON data, do
//
//     final subscription = subscriptionFromJson(jsonString);

import 'dart:convert';
import 'dart:io';

String subscriptionToJson(SubscriptionRequest data) =>
    json.encode(data.toJson());

/// Body of `POST /v4/subscription/`, enveloped in `registerSubscriberRequest`
/// (the historical SDK format, still accepted by the v4 contract).
class SubscriptionRequest {
  SubscriptionRequest({
    this.registerSubscriberRequest,
  });

  RegisterSubscriberRequest? registerSubscriberRequest;

  Map<String, dynamic> toJson() => {
        "registerSubscriberRequest": registerSubscriberRequest?.toJson() ?? {},
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
    this.osName,
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
    this.lat,
    this.long,
    this.advertiserId,
    this.idfa,
    this.optIn,
  });

  String? appToken;
  String? identifier;
  String? registration;

  /// `"android"` or `"ios"`. The v4 API classifies any unrecognized value as
  /// platform 5 ("Others"), which never receives push — send it lowercase.
  String? platform;
  String? sdk;
  String? deviceModel;
  String? deviceManufacturer;
  String? osName;
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
  String? lat;
  String? long;
  String? idfa;
  String? advertiserId;

  /// Push permission state as the v4 API expects it: `"1"` when granted,
  /// `"0"` otherwise. `null` omits the key (the API keeps the stored value).
  String? optIn;

  /// Serializes the request omitting absent values: the v4 contract asks SDKs
  /// to omit a key rather than send `null`, `""`, `"null"` or `"undefined"`.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      "app_token": appToken,
      "identifier": identifier,
      "registration": registration,
      "platform": platform,
      "sdk": sdk,
      "device_model": deviceModel,
      "device_manufacturer": deviceManufacturer,
      "os_name": osName,
      "os_locale": osLocale,
      "os_language": osLanguage,
      "os_version": osVersion,
      "app_version": appVersion,
      "app_installed_in": appInstalledIn?.toIso8601String(),
      "app_updated_in": appUpdatedIn?.toIso8601String(),
      "uuid": uuid,
      "attribution_id": attributionId,
      "custom_field": customField,
      "phone_number": phoneNumber,
      "email": email,
      "lat": lat,
      "long": long,
      "opt_in": optIn,
    };
    if (Platform.isIOS) {
      json["idfa"] = idfa;
    } else {
      json["advertiser_id"] = advertiserId;
    }
    return stripAbsentValues(json);
  }
}

/// Removes entries the Inngage v4 API treats as absent (`null`, blank strings
/// and the literal `"null"`/`"undefined"`), plus empty maps, so the request
/// carries only meaningful keys.
Map<String, dynamic> stripAbsentValues(Map<String, dynamic> json) {
  json.removeWhere((_, value) => isAbsentValue(value));
  return json;
}

bool isAbsentValue(Object? value) {
  if (value == null) return true;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == 'null' || trimmed == 'undefined';
  }
  if (value is Map) return value.isEmpty;
  return false;
}
