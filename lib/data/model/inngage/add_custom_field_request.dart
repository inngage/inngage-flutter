import 'dart:convert';

import 'subscription_request.dart' show stripAbsentValues;

String addCustomFieldRequestToJson(AddCustomFieldRequest data) =>
    json.encode(data.toJson());

/// Body of `POST /v4/subscription/addCustomField`, enveloped in
/// `fieldsRequest`.
///
/// Writes custom fields (and optionally contact and identities) to a
/// subscriber **without any session side effect**: no device is touched, no
/// `lastAccess` is recorded and no event is emitted.
class AddCustomFieldRequest {
  const AddCustomFieldRequest({
    required this.appToken,
    required this.identifier,
    required this.customField,
    this.email,
    this.phoneNumber,
    this.identity,
    this.registration,
  });

  final String appToken;

  /// Business identifier of the person (e-mail, CPF, customer id). Required
  /// by the API.
  final String identifier;

  /// `{ "field_name": value }`. The API requires a non-empty object; unknown
  /// field names are silently ignored server-side.
  final Map<String, dynamic> customField;

  final String? email;
  final String? phoneNumber;

  /// `{ "provider": "id" }`, e.g. `{ "vtex": "7a3c9f1e" }`. On this route
  /// every pair is stored (one id per provider).
  final Map<String, String>? identity;

  /// Push token. It does not create a device here; it only lets the API claim
  /// an anonymous/technical subscriber that owns this device for
  /// [identifier].
  final String? registration;

  Map<String, dynamic> toJson() => {
        'fieldsRequest': stripAbsentValues({
          'app_token': appToken,
          'identifier': identifier,
          'custom_field': customField,
          'email': email,
          'phone_number': phoneNumber,
          'identity': identity,
          'registration': registration,
        }),
      };
}
