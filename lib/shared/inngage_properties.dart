import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/domain/inngage_service.dart';
import 'package:inngage_plugin/domain/services/impl/event_service_impl.dart';
import 'package:inngage_plugin/domain/services/impl/notification_service_impl.dart';
import 'package:inngage_plugin/domain/services/impl/subscription_service_impl.dart';
import 'package:logger/logger.dart';

import '../data/api/inngage_network.dart';
import '../data/model/inngage/web_view_properties_model.dart';

class InngageProperties {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static InngageWebViewProperties inngageWebViewProperties =
      InngageWebViewProperties();
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static bool isInOpen = false;
  static bool debugMode = false;
  static bool blockDeepLink = false;
  static String appToken = '';
  static String identifier = '';
  static String phoneNumber = '';
  static String email = '';
  static String registration = '';
  static String latitude = '';
  static String longitude = '';
  static String attributionId = '';
  static String keyAuthorization = '';
  static Map<String, dynamic> customFields = {};

  static bool getDebugMode() => debugMode;

  static final InngageNetwork network = InngageNetwork(
    // Read lazily so keys set after startup (InngageUtils.setKeyAuthorization)
    // are honored on every request.
    keyAuthorizationProvider: () => keyAuthorization,
    logger: Logger(
      filter: _InngageLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        colors: true,
        printEmojis: true,
      ),
    ),
  );

  static final inngageService = InngageService(
      subscriptionService: SubscriptionServiceImpl(network),
      notificationService: NotificationServiceImpl(network),
      eventService: EventServiceImpl(network));
}

/// Errors are always logged; anything below error level (request/response
/// payloads, which may contain PII) is only logged when
/// [InngageProperties.debugMode] is enabled.
class _InngageLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) =>
      InngageProperties.debugMode || event.level.value >= Level.error.value;
}
