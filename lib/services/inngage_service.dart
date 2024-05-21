import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:inngage_plugin/data/model/event_request.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class InngageService {
  final InngageNetwork inngageNetwork;

  InngageService(this.inngageNetwork);

  static Future<void> registerSubscriber(String? registration) async {
    final registerSubscriberRequest = RegisterSubscriberRequest(
      appInstalledIn: DateTime.now(),
      appToken: InngageProperties.appToken,
      appUpdatedIn: DateTime.now(),
      customField: InngageProperties.customFields,
      appVersion: await InngageUtils.getVersionApp(),
      deviceModel: await InngageUtils.getDeviceModel(),
      sdk: '2.0.9',
      phoneNumber: InngageProperties.phoneNumber,
      email: InngageProperties.email,
      deviceManufacturer: await InngageUtils.getDeviceManufacturer(),
      identifier: InngageProperties.identifier,
      osLanguage: (await Devicelocale.preferredLanguages)!.isNotEmpty
          ? (await Devicelocale.preferredLanguages)![0]
          : "",
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

    //make request subscription to inngage backend
    await InngageProperties.inngageNetwork.subscription(
      subscription: SubscriptionRequest(
        registerSubscriberRequest: registerSubscriberRequest,
      ),
    );
  }

  static Future<void> registerNotification(
      {required String notId, required String appToken}) async {
    await InngageProperties.inngageNetwork
        .notification(notId: notId, appToken: appToken);
  }

  static Future<void> registerEvent(
      String? registration,
      String eventName,
      Map<String, dynamic> eventValues,
      bool conversionEvent,
      double conversionValue,
      String conversionNotId) async {
    final eventRequest = NewEventRequest(
      appToken: InngageProperties.appToken,
      identifier: InngageProperties.identifier,
      registration: registration!,
      eventName: eventName,
      eventValues: eventValues,
      conversionEvent: conversionEvent,
      conversionNotId: conversionNotId,
      conversionValue: conversionValue,
    );

    await InngageProperties.inngageNetwork.sendEvent(
      event: Event(newEventRequest: eventRequest),
    );
  }
}
