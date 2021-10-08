import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inngage_plugin/data/exceptions/exceptions.dart';
import 'package:inngage_plugin/data/model/event_request.dart';
import 'package:inngage_plugin/data/model/notification_request.dart';
import 'package:inngage_plugin/data/model/subscription_request.dart';
import 'package:inngage_plugin/util/constants.dart';

abstract class InngageNetworkData {
  Future<void> subscription({
    required SubscriptionRequest subscription,
  });
  Future<void> notification({
    required String notid,
    required String appToken,
  });
  Future<void> sendEvent({
    required String eventName,
    required String appToken,
    required String identifier,
    required String registration,
    Map<String, dynamic> eventValues = const {},
  });
}

class InngageNetwork implements InngageNetworkData {
  InngageNetwork({this.keyAuthorization = ''});
  final String keyAuthorization;

  @override
  Future<void> subscription({
    required SubscriptionRequest subscription,
  }) async {
    final payload = subscriptionToJson(subscription);
    final resp = await http.post(
      Uri.parse(AppConstants.BASE_URL + '/subscription/'),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        'Content-Type': 'application/json',
        if (keyAuthorization.isNotEmpty) 'Authorization': 'key=$keyAuthorization'
      },
      body: payload,
    );
    if (kDebugMode) {
      print('INNGAGE PAYLOAD: $payload');
      print('INNGAGE RESPONSE: ${resp.body}');
    }
    if (resp.statusCode != 200) {
      throw InngageException('Unfortunately it was not possible to subscribe');
    }
    return;
  }

  @override
  Future<void> notification({
    required String notid,
    required String appToken,
  }) async {
    final notificationRequest = NotificationRequest(
      notificationRequest: Notification(
        appToken: appToken,
        id: notid,
        notid: notid,
      ),
    );
    final payload = notificationRequestToJson(notificationRequest);
    final resp = await http.post(
      Uri.parse(AppConstants.BASE_URL + '/notification/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        if (keyAuthorization.isNotEmpty) 'Authorization': 'key=$keyAuthorization'
      },
      body: payload,
    );
    if (resp.statusCode != 200) {
      throw InngageException(
        'Unfortunately it was not possible confirm notification',
      );
    }
    return;
  }

  @override
  Future<void> sendEvent({
    required String eventName,
    required String appToken,
    required String identifier,
    required String registration,
    Map<String, dynamic> eventValues = const {},
    bool conversionEvent = false,
    double conversionValue = 0,
    String conversionNotId = '',
  }) async {
    final eventRequest = NewEventRequest(
      appToken: appToken,
      identifier: identifier,
      registration: registration,
      eventName: eventName,
      eventValues: eventValues,
      conversionEvent: conversionEvent,
      conversionNotId: conversionNotId,
      conversionValue: conversionValue,
    );
    final event = Event(newEventRequest: eventRequest);

    final payload = eventToJson(event);

    final resp = await http.post(
      Uri.parse(AppConstants.BASE_URL + '/events/newEvent/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        if (keyAuthorization.isNotEmpty) 'Authorization': 'key=$keyAuthorization'
      },
      body: payload,
    );
    if (resp.statusCode != 200) {
      throw InngageException(
        'Unfortunately it was not possible send an event',
      );
    }
  }
}
