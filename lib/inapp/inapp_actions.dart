import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/model/inapp/inapp_message_v2.dart';
import '../shared/inngage_properties.dart';

/// Executes a triggered [InAppV2Action] after the message is dismissed.
class InngageInAppActions {
  static Future<void> execute(
    InAppV2Action action, {
    required bool handledBySdk,
    void Function(InAppV2Action action)? onAction,
    void Function(Map<String, String> metadata)? onMetadata,
  }) async {
    if (!handledBySdk) {
      onAction?.call(action);
      return;
    }

    switch (action.type) {
      case InAppV2ActionType.deepLink:
        if (InngageProperties.blockDeepLink) {
          onAction?.call(action);
        } else {
          await _launch(action.url, LaunchMode.externalApplication);
        }
        break;
      case InAppV2ActionType.weblink:
        await _launch(action.url, LaunchMode.externalApplication);
        break;
      case InAppV2ActionType.inAppUrl:
        await _launch(action.url, LaunchMode.inAppBrowserView);
        break;
      case InAppV2ActionType.metadata:
        onMetadata?.call(action.metadata);
        break;
      case InAppV2ActionType.dismiss:
        break;
    }
  }

  static Future<void> _launch(String url, LaunchMode mode) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: mode)) {
        debugPrint('Inngage: could not launch In-App action URL: $url');
      }
    } catch (e) {
      debugPrint('Inngage: failed to launch In-App action URL "$url": $e');
    }
  }
}
