import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_id/advertising_id.dart';

class InngageUtils {
  static bool requestAdvertiserId = false;

  static Future<String> getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    // String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;
    return packageInfo.version;
  }

  static void launchURL(String url) async {
    final Uri url0 = Uri.parse(url);
    if (!await launchUrl(url0, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not lauch $url0');
    }
  }

  static Future<String> getDeviceOS() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await InngageProperties.deviceInfo.iosInfo;
      return iosInfo.systemVersion;
    } else {
      AndroidDeviceInfo androidInfo =
          await InngageProperties.deviceInfo.androidInfo;
      return androidInfo.version.release;
    }
  }

  static Future<String> getDeviceModel() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await InngageProperties.deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    } else {
      AndroidDeviceInfo androidInfo =
          await InngageProperties.deviceInfo.androidInfo;
      return androidInfo.model;
    }
  }

  static Future<String> getDeviceManufacturer() async {
    if (Platform.isIOS) {
      return 'Apple';
    } else {
      AndroidDeviceInfo androidInfo =
          await InngageProperties.deviceInfo.androidInfo;
      return androidInfo.manufacturer;
    }
  }

  static Future<String> getAdvertisingId() async {
    if (requestAdvertiserId) {
      try {
        return await AdvertisingId.id(true) ?? "Unknown";
      } on PlatformException {
        return "Unknown";
      }
    } else {
      return "Unknown";
    }
  }

  static Future<String> getUniqueId() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await InngageProperties.deviceInfo.iosInfo;
      return iosInfo.identifierForVendor!;
    } else {
      AndroidDeviceInfo androidInfo =
          await InngageProperties.deviceInfo.androidInfo;
      return androidInfo.id;
    }
  }

  static Future<String> getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor!; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // unique ID on Android
    }
  }

  static void setIdentifier({required String identifier}) async {
    InngageProperties.identifier = identifier;
  }

  static void addUserData({
    String? identifier,
    Map<String, dynamic>? customFields,
    String? email,
    String? phoneNumber,
  }) {
    InngageProperties.identifier = identifier ?? InngageProperties.identifier;
    InngageProperties.customFields =
        customFields ?? InngageProperties.customFields;
    InngageProperties.email = email ?? InngageProperties.email;
    InngageProperties.phoneNumber =
        phoneNumber ?? InngageProperties.phoneNumber;
  }

  static void setKeyAuthorization({required String keyAuthorization}) async {
    InngageProperties.keyAuthorization = keyAuthorization;
  }

  static bool isNullOrEmpty(String? text) {
    return text == null || text.isEmpty;
  }
}
