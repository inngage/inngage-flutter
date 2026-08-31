import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../core/constants.dart';
import '../model/inngage/event_request.dart';
import '../model/inngage/notification_request.dart';
import '../model/inngage/subscription_request.dart';
import '../../domain/services/event_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/notification_service.dart';

class InngageNetwork
    implements SubscriptionService, NotificationService, EventService {
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
  Future<void> subscription(SubscriptionRequest subscription) async {
    await _postRequest(
        '$version/subscription/', subscriptionToJson(subscription));
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
}
