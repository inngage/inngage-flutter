import '../../api/inngage_network.dart' show InngageNetwork;

/// Parsed body of `POST /v4/subscription/` (envelope
/// `registerSubscriberResponse`) and, in a reduced form, of
/// `POST /v4/subscription/addCustomField` (`status`/`message`/`appId` at the
/// root).
///
/// Every field is optional: the SDK never fails on a response it cannot fully
/// parse, it just persists what it could read.
class SubscriptionResponse {
  const SubscriptionResponse({
    this.statusDescription,
    this.appId,
    this.subscriberId,
    this.fromSubscriberId,
    this.toSubscriberId,
  });

  /// E.g. `Successfully: subscriberCreated`.
  final String? statusDescription;

  /// Id of the app the subscriber belongs to. Required by the In-App
  /// `/objectMessage` flow.
  final int? appId;

  /// Id of the subscriber to keep in the SDK. On `deviceTransferred` the API
  /// sends no `subscriberId`, so this falls back to [toSubscriberId].
  final String? subscriberId;

  final String? fromSubscriberId;
  final String? toSubscriberId;

  factory SubscriptionResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubscriptionResponse();

    final envelope = json['registerSubscriberResponse'];
    final body = envelope is Map<String, dynamic> ? envelope : json;

    final toSubscriberId = _asString(body['toSubscriberId']);
    return SubscriptionResponse(
      statusDescription:
          _asString(body['statusDescription'] ?? body['message']),
      appId: extractAppId(json),
      subscriberId: _asString(body['subscriberId']) ?? toSubscriberId,
      fromSubscriberId: _asString(body['fromSubscriberId']),
      toSubscriberId: toSubscriberId,
    );
  }

  /// Finds the app id in [response]: the v4 contract names it `appId` (nested
  /// in `registerSubscriberResponse` on the subscription, at the root on
  /// addCustomField); `app_id` is accepted for older shapes. Ints possibly
  /// serialized as strings are handled, nested objects are searched, and a
  /// plain-text body (see [InngageNetwork.rawBodyKey]) is scanned as a last
  /// resort.
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

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
