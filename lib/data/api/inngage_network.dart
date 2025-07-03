import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final String keyAuthorization;
  final String version;

  InngageNetwork({
    required this.logger,
    required this.keyAuthorization,
    this.version = 'v1',
  });

  @override
  Future<void> sendEvent(Event event) async {
    await _postRequest('$version/events/newEvent/', eventToJson(event));
  }

  @override
  Future<void> sendNotification(String notId, String appToken) async {
    final payload = notificationRequestToJson(
      NotificationRequest(
        notificationRequest: Notification(
          appToken: appToken,
          id: notId,
          notId: notId,
        ),
      ),
    );
    logger.i(payload);
    await _postRequest('$version/notification/', payload);
  }

  @override
  Future<void> subscription(SubscriptionRequest subscription) async {
    await _postRequest(
      '$version/subscription/',
      subscriptionToJson(subscription),
    );
  }

  Future<void> _postRequest(String endpoint, String payload) async {
    try {
      final url = Uri.https(AppConstants.baseUrl, endpoint);
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
    } on http.ClientException catch (e) {
      logger.e('Client error: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error: $e');
    }
  }
}
