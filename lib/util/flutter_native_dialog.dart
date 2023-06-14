import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

const MethodChannel _channel =  MethodChannel('flutter_native_dialog');

class FlutterNativeDialog {
  static const String defaultPositiveButtonText = "OK";
  static const String defaultNegativeButtonText = "Cancel";

  /// Shows an alert dialog to the user
  ///
  /// An alert contains an optional [title], [message]. The [positiveButtonText]
  /// will appear under the dialog and allows users to close it. When closed,
  /// a bool will be returned to the user. This value will always be true.
  static Future<bool?> showAlertDialog({
    String? title,
    String? message,
    String? positiveButtonText,
  }) async {
    return await _channel.invokeMethod(
      'dialog.alert',
      {
        "title": title,
        "message": message,
        "positiveButtonText":
            positiveButtonText ?? defaultPositiveButtonText,
      },
    );
  }

  /// Shows an alert dialog asking the user for a confirmation
  ///
  /// This alert contains an optional [title], [message]. [positiveButtonText]
  /// and [negativeButtonText] will be shown on the corresponding buttons. When
  /// the user clicks on [positiveButtonText] this will return true. When the
  /// user clicks on [negativeButtonText] this will return false. [destructive]
  /// can be set to true to show the user this is a destructive operation (only on iOS).
  static Future<bool?> showConfirmDialog({
    String? title,
    String? message,
    String positiveButtonText = defaultPositiveButtonText,
    String negativeButtonText = defaultNegativeButtonText,
    bool destructive = false,
  }) async {
    return await _channel.invokeMethod(
      'dialog.confirm',
      {
        "title": title,
        "message": message,
        "positiveButtonText": positiveButtonText,
        "negativeButtonText": negativeButtonText,
        "destructive": destructive,
      },
    );
  }

  @visibleForTesting
  static void setMockCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    //_channel.setMockMethodCallHandler(handler);
  }
}
