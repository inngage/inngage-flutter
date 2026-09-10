import 'package:flutter/material.dart';

import '../data/model/inapp/inapp_message_v2.dart';
import '../shared/inngage_properties.dart';
import 'inapp_actions.dart';
import 'widgets/inapp_v2_card.dart';

/// Public entry point of the In-App Message channel.
///
/// The flow is pull-based and on demand: call [show] wherever the app wants an
/// In-App message to appear (after the splash screen, on the login screen, on
/// a specific route…). The SDK fetches `/v4/message/objectMessage` and renders
/// the returned message — or renders nothing, silently, when there is none.
///
/// Prerequisite: the subscription must have completed at least once
/// ([InngageSDK.subscribe] → registration), since the fetch depends on the
/// `app_id` and registration token persisted from it.
class InngageInApp {
  /// Fetches and, when available, displays the current In-App message.
  ///
  /// [context] defaults to the navigator provided to `InngageSDK.subscribe`.
  /// With [handledBySdk] `true` (default) the SDK executes the message
  /// actions itself (deep links, browser, in-app browser); `metadata` actions
  /// are always delivered to [onMetadata]. With [handledBySdk] `false`, every
  /// triggered action is delivered to [onAction] instead.
  static Future<void> show({
    BuildContext? context,
    bool handledBySdk = true,
    void Function(InAppV2Action action)? onAction,
    void Function(Map<String, String> metadata)? onMetadata,
  }) async {
    final message = await InngageProperties.inngageService.fetchInAppMessage();
    if (message == null || !message.hasRenderableContent) return;

    final dialogContext =
        context ?? InngageProperties.navigatorKey.currentState?.context;
    if (dialogContext == null || !dialogContext.mounted) {
      debugPrint('Inngage: In-App not shown — no context available. Pass a '
          'context to InngageInApp.show or provide the navigatorKey to '
          'InngageSDK.subscribe.');
      return;
    }

    await showDialog(
      context: dialogContext,
      builder: (_) => InAppV2Card(
        message: message,
        onActionTriggered: (action) => InngageInAppActions.execute(
          action,
          handledBySdk: handledBySdk,
          onAction: onAction,
          onMetadata: onMetadata,
        ),
      ),
    );
  }
}
