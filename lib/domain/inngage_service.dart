// domain/services/inngage_service.dart
import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import '../data/model/inngage/event_request.dart';
import '../data/model/inngage/subscription_request.dart';
import '../../shared/inngage_properties.dart';
import '../shared/inngage_utils.dart';
import 'services/event_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';

class InngageService {
  final SubscriptionService subscriptionService;
  final NotificationService notificationService;
  final EventService eventService;

  InngageService({
    required this.subscriptionService,
    required this.notificationService,
    required this.eventService,
  });

  Future<void> registerSubscriber(String? registration) async {
    final request = RegisterSubscriberRequest(
      appInstalledIn: DateTime.now(),
      appUpdatedIn: DateTime.now(),
      appToken: InngageProperties.appToken,
      customField: InngageProperties.customFields,
      appVersion: await InngageUtils.getVersionApp(),
      deviceModel: await InngageUtils.getDeviceModel(),
      sdk: '3.7.0',
      phoneNumber: InngageProperties.phoneNumber,
      email: InngageProperties.email,
      deviceManufacturer: await InngageUtils.getDeviceManufacturer(),
      identifier: InngageProperties.identifier,
      osLanguage: (await Devicelocale.preferredLanguages)?.first ?? "",
      osLocale: await Devicelocale.currentLocale,
      osVersion: await InngageUtils.getDeviceOS(),
      registration: registration,
      uuid: await InngageUtils.getUniqueId(),
      platform: Platform.isAndroid ? 'Android' : 'iOS',
      advertiserId: await InngageUtils.getAdvertisingId(),
      idfa: await InngageUtils.getAdvertisingId(),
      lat: InngageProperties.latitude,
      long: InngageProperties.longitude,
    );

    await subscriptionService.subscription(
      SubscriptionRequest(registerSubscriberRequest: request),
    );
  }

  Future<void> registerNotification(
      {required String notId, required String appToken}) async {
    await notificationService.sendNotification(notId, appToken);
  }

  Future<void> registerEvent(
    String registration,
    String eventName,
    Map<String, dynamic> eventValues,
    bool conversionEvent,
    double conversionValue,
    String conversionNotId,
  ) async {
    final eventRequest = NewEventRequest(
      appToken: InngageProperties.appToken,
      identifier: InngageProperties.identifier,
      registration: registration,
      eventName: eventName,
      eventValues: eventValues,
      conversionEvent: conversionEvent,
      conversionNotId: conversionNotId,
      conversionValue: conversionValue,
    );

    await eventService.sendEvent(Event(newEventRequest: eventRequest));
  }
}
