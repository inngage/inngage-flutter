import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_id/advertising_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../inngage_plugin.dart';

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

  static Future<void> launchURL(String url) async {
    final Uri url0 = Uri.parse(url);
    if (!await launchUrl(url0, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not lauch $url0');
    }
  }

  /// Platform name as the v4 subscription expects it: `"android"` or `"ios"`.
  /// Anything else is classified by the API as "Others" and never receives
  /// push.
  static String getPlatformName() => Platform.isIOS ? 'ios' : 'android';

  static String getOsName() => Platform.isIOS ? 'iOS' : 'Android';

  /// Push permission state for the subscription `opt_in` field: `"1"` when
  /// granted (authorized or provisional), `"0"` when denied, `null` when it
  /// cannot be determined (e.g. Firebase not initialized), in which case the
  /// key is omitted and the API keeps the stored value.
  static Future<String?> getPushOptIn() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return '1';
        case AuthorizationStatus.denied:
          return '0';
        case AuthorizationStatus.notDetermined:
          return null;
      }
    } catch (_) {
      return null;
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

  static Future<String> _getUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('deviceUUID');

    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString('deviceUUID', uuid);
    }
    return uuid;
  }

  static Future<String> getUniqueId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? await _getUuid();
    } else {
      return await _getUuid();
    }
  }

  static void setIdentifier({required String identifier}) async {
    InngageProperties.identifier = identifier;
  }

  /// Updates the local user data only. Nothing is sent until the next
  /// subscriber registration; to persist custom fields on the API right away
  /// use `InngageSDK.addCustomField`.
  static void addUserData({
    required String? appToken,
    String? identifier,
    Map<String, dynamic>? customFields,
    String? email,
    String? phoneNumber,
  }) async {
    InngageProperties.appToken = appToken ?? InngageProperties.appToken;
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
