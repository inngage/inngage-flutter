import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:inngage_plugin/data/model/event_request.dart';
import 'package:inngage_plugin/data/model/notification_request.dart';
import 'package:inngage_plugin/data/model/subscription_request.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:inngage_plugin/util/constants.dart';
import 'package:logger/logger.dart';

abstract class SubscriptionService {
  Future<void> subscription({required SubscriptionRequest subscription});
}

abstract class NotificationService {
  Future<void> notification({required String notId, required String appToken});
}

abstract class EventService {
  Future<void> sendEvent({required Event event});
}

class InngageNetwork
    implements SubscriptionService, NotificationService, EventService {
  InngageNetwork({
    required this.logger,
    this.keyAuthorization = '',
  });

  final String version = 'v1';
  final String keyAuthorization;
  final Logger logger;

  @override
  Future<void> subscription({required SubscriptionRequest subscription}) async {
    final payload = subscriptionToJson(subscription);
    _postRequest(endpoint: '$version/subscription/', payload: payload);
  }

  @override
  Future<void> notification({
    required String notId,
    required String appToken,
  }) async {
    final notificationRequest = NotificationRequest(
      notificationRequest: Notification(
        appToken: appToken,
        id: notId,
        notId: notId,
      ),
    );

    final payload = notificationRequestToJson(notificationRequest);
    logger.i(payload);
    _postRequest(endpoint: '$version/notification/', payload: payload);
  }

  @override
  Future<void> sendEvent({required Event event}) async {
    final payload = eventToJson(event);
    _postRequest(endpoint: '$version/events/newEvent/', payload: payload);
  }

  Future<void> _postRequest(
      {required String endpoint, required String payload}) async {
    try {
      final url = Uri.https(AppConstants.baseUrl, endpoint);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (keyAuthorization.isNotEmpty)
            'Authorization': 'key=$keyAuthorization'
        },
        body: payload,
      );

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Unexpected response status code: ${response.statusCode}');
      }

      if (InngageProperties.getDebugMode()) {
        logger.d('INNGAGE PAYLOAD: $payload');
        logger.d('INNGAGE RESPONSE: ${response.body}');
      }

      return;
    } on http.ClientException catch (e) {
      logger.e(e.message);
      if (e.message.contains('Failed host lookup')) {
        logger.e('Failed to resolve hostname. Check internet connection.');
      } else {
        logger.e('Client error occurred: ${e.message}');
      }
    } catch (e) {
      logger.e('An unexpected error occurred: $e');
    }
  }

  void _handleHttpException(http.ClientException e) {}
}
