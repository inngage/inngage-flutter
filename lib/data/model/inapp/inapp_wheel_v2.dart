// In-App v2 "Wheel" (roleta) models. These arrive in the same
// /objectMessage response, discriminated by `type: "Wheel"`.

import 'inapp_message_v2.dart';

class InAppV2LeadField {
  final String type;
  final String label;

  const InAppV2LeadField({this.type = 'text', this.label = ''});

  factory InAppV2LeadField.fromJson(Map<String, dynamic> json) {
    return InAppV2LeadField(
      type: json['type'] as String? ?? 'text',
      label: json['label'] as String? ?? '',
    );
  }
}

class InAppV2LeadCapture {
  final bool enabled;

  /// `before`: the form gates the wheel spin. `after`: the user spins first
  /// and the prize coupon stays locked until the form is submitted.
  final String position;
  final List<InAppV2LeadField> fields;
  final String buttonText;
  final InAppV2ButtonStyle buttonStyle;
  final String consentText;
  final String consentColor;
  final String unlockText;

  const InAppV2LeadCapture({
    this.enabled = false,
    this.position = 'before',
    this.fields = const [],
    this.buttonText = '',
    this.buttonStyle = const InAppV2ButtonStyle(),
    this.consentText = '',
    this.consentColor = '',
    this.unlockText = '',
  });

  factory InAppV2LeadCapture.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final rawButton = json['button'];
    final button = rawButton is Map<String, dynamic> ? rawButton : const {};
    final rawButtonStyle = button['style'];
    return InAppV2LeadCapture(
      enabled: json['enabled'] as bool? ?? false,
      position: json['position'] as String? ?? 'before',
      fields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(InAppV2LeadField.fromJson)
              .toList()
          : const [],
      buttonText: button['text'] as String? ?? '',
      buttonStyle: rawButtonStyle is Map<String, dynamic>
          ? InAppV2ButtonStyle.fromJson(rawButtonStyle)
          : const InAppV2ButtonStyle(),
      consentText: json['consentText'] as String? ?? '',
      consentColor: json['consentColor'] as String? ?? '',
      unlockText: json['unlockText'] as String? ?? '',
    );
  }

  bool get capturesBeforeSpin => position.toLowerCase() != 'after';
}

class InAppV2WheelSlice {
  final String label;
  final String color;

  /// Coupon code. `null`/empty means the slice is a losing one.
  final String? code;
  final int weight;

  const InAppV2WheelSlice({
    this.label = '',
    this.color = '',
    this.code,
    this.weight = 1,
  });

  factory InAppV2WheelSlice.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight'];
    return InAppV2WheelSlice(
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '',
      code: json['code'] as String?,
      weight: rawWeight is int
          ? rawWeight
          : int.tryParse(rawWeight?.toString() ?? '') ?? 1,
    );
  }

  bool get isWin => code != null && code!.isNotEmpty;
}

class InAppV2WheelConfig {
  final String buttonText;
  final InAppV2ButtonStyle buttonStyle;
  final List<InAppV2WheelSlice> slices;

  const InAppV2WheelConfig({
    this.buttonText = 'Girar',
    this.buttonStyle = const InAppV2ButtonStyle(),
    this.slices = const [],
  });

  factory InAppV2WheelConfig.fromJson(Map<String, dynamic> json) {
    final rawButton = json['button'];
    final rawSlices = json['slices'];
    return InAppV2WheelConfig(
      buttonText: json['buttonText'] as String? ?? 'Girar',
      // Unlike lead capture, the wheel `button` object holds the colors
      // directly ({backgroundColor, textColor}), with no nested `style`.
      buttonStyle: rawButton is Map<String, dynamic>
          ? InAppV2ButtonStyle.fromJson(rawButton)
          : const InAppV2ButtonStyle(),
      slices: rawSlices is List
          ? rawSlices
              .whereType<Map<String, dynamic>>()
              .map(InAppV2WheelSlice.fromJson)
              .toList()
          : const [],
    );
  }
}

class InAppV2ResultStyle {
  final bool gradient;
  final String bgFrom;
  final String bgTo;
  final String textColor;

  const InAppV2ResultStyle({
    this.gradient = false,
    this.bgFrom = '',
    this.bgTo = '',
    this.textColor = '',
  });

  factory InAppV2ResultStyle.fromJson(Map<String, dynamic> json) {
    return InAppV2ResultStyle(
      gradient: json['gradient'] as bool? ?? false,
      bgFrom: json['bgFrom'] as String? ?? '',
      bgTo: json['bgTo'] as String? ?? '',
      textColor: json['textColor'] as String? ?? '',
    );
  }
}

class InAppV2ResultConfig {
  final String winTitle;
  final String loseTitle;
  final String body;
  final String winEmoji;
  final String loseEmoji;
  final InAppV2ResultStyle style;

  const InAppV2ResultConfig({
    this.winTitle = '',
    this.loseTitle = '',
    this.body = '',
    this.winEmoji = '',
    this.loseEmoji = '',
    this.style = const InAppV2ResultStyle(),
  });

  factory InAppV2ResultConfig.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['style'];
    return InAppV2ResultConfig(
      winTitle: json['winTitle'] as String? ?? '',
      loseTitle: json['loseTitle'] as String? ?? '',
      body: json['body'] as String? ?? '',
      winEmoji: json['winEmoji'] as String? ?? '',
      loseEmoji: json['loseEmoji'] as String? ?? '',
      style: rawStyle is Map<String, dynamic>
          ? InAppV2ResultStyle.fromJson(rawStyle)
          : const InAppV2ResultStyle(),
    );
  }
}
