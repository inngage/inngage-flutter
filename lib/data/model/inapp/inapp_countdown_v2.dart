// In-App v2 "Countdown" models. These arrive in the same /objectMessage
// response, discriminated by `type: "Countdown"`.

class InAppV2CountdownConfig {
  /// Campaign deadline, interpreted in the device's local time (the backend
  /// sends `"2026-09-15T17:28"`, with no timezone). `null` when absent or
  /// unparseable — the message is then not renderable.
  final DateTime? endDate;
  final String boxColor;
  final String digitColor;
  final String expiredTitle;
  final String expiredBody;

  const InAppV2CountdownConfig({
    this.endDate,
    this.boxColor = '#111827',
    this.digitColor = '#FFFFFF',
    this.expiredTitle = '',
    this.expiredBody = '',
  });

  factory InAppV2CountdownConfig.fromJson(Map<String, dynamic> json) {
    final rawEndDate = json['endDate'];
    return InAppV2CountdownConfig(
      endDate: rawEndDate is String ? DateTime.tryParse(rawEndDate) : null,
      boxColor: json['boxColor'] as String? ?? '#111827',
      digitColor: json['digitColor'] as String? ?? '#FFFFFF',
      expiredTitle: json['expiredTitle'] as String? ?? '',
      expiredBody: json['expiredBody'] as String? ?? '',
    );
  }
}
