import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/data/api/inngage_api.dart';
import 'package:logger/logger.dart';

import 'inngage_web_view_properties_model.dart';

class InngageProperties {
  static bool isInOpen = false;
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static String identifier = '';
  static String phoneNumber = '';
  static String email = '';
  static String appToken = '';
  static String registration = '';
  static String latitude = '';
  static String longitude = '';
  static String attributionId = '';
  static String keyAuthorization = '';
  static Map<String, dynamic> customFields = {};
  static bool debugMode = false;
  static bool blockDeepLink = false;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static InngageWebViewProperties inngageWebViewProperties =
      InngageWebViewProperties();
  static final InngageNetwork inngageNetwork = InngageNetwork(
    keyAuthorization: keyAuthorization,
    logger: Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 20000,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    ),
  );

  static bool getDebugMode() => debugMode;
}
