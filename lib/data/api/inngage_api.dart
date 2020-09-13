import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:inngage_plugin/util/constants.dart';
import 'package:inngage_plugin/data/model/notification_request.dart';
import 'package:inngage_plugin/data/model/subscription_request.dart';
import 'package:inngage_plugin/data/exceptions/exceptions.dart';
import 'package:meta/meta.dart';

abstract class InngageNetworkData {
  Future<void> subscription(SubscriptionRequest subscription);
  Future<void> notification({
    @required String notid,
    @required String appToken,
  });
}

class InngageNetwork implements InngageNetworkData {
  InngageNetwork();

  @override
  Future<void> subscription(SubscriptionRequest subscription) async {
    final payload = subscriptionToJson(subscription);
    final resp = await http.post(
      AppConstants.BASE_URL + '/subscription/',
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        'Content-Type': 'application/json',
      },
      body: payload,
    );

    if (resp.statusCode != 200) {
      throw InngageException('Unfortunately it was not possible to subscribe');
    }
    return;
  }

  @override
  Future<void> notification({
    @required String notid,
    @required String appToken,
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
      AppConstants.BASE_URL + '/notification/',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
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
}
