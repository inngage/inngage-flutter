import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../core/constants.dart';
import '../model/inapp/object_message_request.dart';
import '../model/inngage/event_request.dart';
import '../model/inngage/notification_request.dart';
import '../model/inngage/subscription_request.dart';
import '../../domain/services/event_service.dart';
import '../../domain/services/inapp_message_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/notification_service.dart';

class InngageNetwork
    implements
        SubscriptionService,
        NotificationService,
        EventService,
        InAppMessageService {
  final Logger logger;
  final String version;

  /// Read at request time so keys set after construction (e.g. via
  /// [InngageUtils.setKeyAuthorization]) are picked up.
  final String Function() _keyAuthorization;

  InngageNetwork({
    required this.logger,
    String keyAuthorization = '',
    String Function()? keyAuthorizationProvider,
    this.version = 'v1',
  }) : _keyAuthorization = keyAuthorizationProvider ?? (() => keyAuthorization);

  @override
  Future<bool> sendEvent(Event event) async {
    return _postRequest('$version/events/newEvent/', eventToJson(event));
  }

  @override
  Future<void> sendNotification(String notId, String appToken) async {
    final payload = notificationRequestToJson(NotificationRequest(
      notificationRequest:
          Notification(appToken: appToken, id: notId, notId: notId),
    ));
    logger.i(payload);
    await _postRequest('$version/notification/', payload);
  }

  @override
  Future<Map<String, dynamic>?> subscription(
      SubscriptionRequest subscription) async {
    return _postRequestForJson(
        '$version/subscription/', subscriptionToJson(subscription));
  }

  /// In-App v2 endpoint; versioned as v4 by the contract, independently of
  /// [version] (which the v1 endpoints use).
  @override
  Future<Map<String, dynamic>?> getObjectMessage(
      ObjectMessageRequest request) async {
    return _postRequestForJson(
        'v4/message/objectMessage', json.encode(request.toJson()));
  }

  /// Counts an In-App display. Without `url`/`btn_id` the API records the
  /// event as an opening.
  @override
  Future<bool> trackInAppImpression(String notId) {
    return _postRequest(
        'v4/message/notification', json.encode(_notificationCallback(notId)));
  }

  /// Counts an In-App click. The origin ([clickSource]: `card`, `button`,
  /// `button_up` or `button_down`) goes in `btn_id` — the field the API
  /// provides for clicks without a link (its `url` field only accepts
  /// absolute URLs) — and causes no redirect.
  @override
  Future<bool> trackInAppClick(String notId, String clickSource) {
    return _postRequest('v4/message/notification',
        json.encode(_notificationCallback(notId, btnId: clickSource)));
  }

  /// The API requires `channel_id` as a string and rejects it as a number.
  Map<String, dynamic> _notificationCallback(String notId, {String? btnId}) {
    return {
      'notificationRequest': {
        'id': notId,
        'channel_id': '${ObjectMessageRequest.inAppChannelId}',
        if (btnId != null) 'btn_id': btnId,
      },
    };
  }

  /// Returns `true` when the API responded with 200 OK. Network/client errors
  /// are logged (not thrown) and reported as `false` so callers that care about
  /// delivery can react, while fire-and-forget callers can ignore the result.
  Future<bool> _postRequest(String endpoint, String payload) async {
    try {
      final url = Uri.https(AppConstants.baseUrl, endpoint);
      final keyAuthorization = _keyAuthorization();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        if (keyAuthorization.isNotEmpty)
          'Authorization': 'key=$keyAuthorization',
      };

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Unexpected response: ${response.statusCode}');
      }
      logger.d('PAYLOAD: $payload');
      logger.d('RESPONSE: ${response.body}');
      return true;
    } on http.ClientException catch (e) {
      logger.e('Client error: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Unexpected error: $e');
      return false;
    }
  }

  /// Key under which a non-JSON (or non-object) 200 body is returned by
  /// [_postRequestForJson] so callers can still inspect it.
  static const rawBodyKey = '_rawBody';

  /// Like [_postRequest], but returns the decoded response body on 200 OK.
  /// Never throws: failures are logged and reported as `null`.
  Future<Map<String, dynamic>?> _postRequestForJson(
      String endpoint, String payload) async {
    try {
      final url = Uri.https(AppConstants.baseUrl, endpoint);
      final keyAuthorization = _keyAuthorization();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        if (keyAuthorization.isNotEmpty)
          'Authorization': 'key=$keyAuthorization',
      };

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Unexpected response: ${response.statusCode}');
      }
      logger.d('PAYLOAD: $payload');
      logger.d('RESPONSE: ${response.body}');

      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Fall through to the raw-body wrapper below.
      }
      return {rawBodyKey: response.body};
    } on http.ClientException catch (e) {
      logger.e('Client error: ${e.message}');
      return null;
    } catch (e) {
      logger.e('Unexpected error: $e');
      return null;
    }
  }
}
