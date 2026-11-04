// In-App v2 "Countdown" models. These arrive in the same /objectMessage
// response, discriminated by `type: "Countdown"`.

class InAppV2CountdownConfig {
  /// Campaign deadline, interpreted in the device's local time. The campaign
  /// editor stores the date and the time separately (`endDate: "2026-10-20"`
  /// + `endTime: "10:30"`); the original contract sends them joined
  /// (`endDate: "2026-09-15T17:28"`). Both are accepted, see
  /// [parseDeadline]. `null` when absent or unparseable — the message is
  /// then not renderable.
  final DateTime? endDate;

  /// Background color of the DIAS/HORAS/MIN/SEG boxes. Read from
  /// `style.backgroundColor` (editor format) or `boxColor` (original
  /// contract).
  final String boxColor;

  /// Color of the digits and labels inside the boxes. Read from
  /// `style.textColor` (editor format) or `digitColor` (original contract).
  final String digitColor;

  /// Texts shown in place of the boxes once the deadline is reached while
  /// the card is open. The campaign editor does not expose them yet, so
  /// they are usually empty — the header title/body then stay as the only
  /// content.
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
    final rawStyle = json['style'];
    final style = rawStyle is Map<String, dynamic> ? rawStyle : const {};
    return InAppV2CountdownConfig(
      endDate: parseDeadline(json['endDate'], json['endTime']),
      boxColor: _firstNonEmpty(
          [style['backgroundColor'], json['boxColor']], '#111827'),
      digitColor:
          _firstNonEmpty([style['textColor'], json['digitColor']], '#FFFFFF'),
      expiredTitle: json['expiredTitle'] as String? ?? '',
      expiredBody: json['expiredBody'] as String? ?? '',
    );
  }

  /// Combines `endDate` and `endTime` into a local [DateTime].
  ///
  /// - `endDate` already carrying a time (`"2026-09-15T17:28"`) wins and
  ///   `endTime` is ignored;
  /// - a date-only `endDate` (`"2026-10-20"`) is combined with `endTime` in
  ///   `H:mm` or `H:mm:ss` form;
  /// - without a usable `endTime` the deadline falls on local midnight of
  ///   `endDate`;
  /// - anything unparseable yields `null`.
  static DateTime? parseDeadline(dynamic endDate, dynamic endTime) {
    if (endDate is! String || endDate.trim().isEmpty) return null;
    final date = DateTime.tryParse(endDate.trim());
    if (date == null) return null;

    final hasTime = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(endDate.trim());
    if (!hasTime) return date;

    final time = endTime is String ? _parseTime(endTime) : null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day).add(time);
  }

  /// `H:mm` or `H:mm:ss` → offset from midnight; `null` when malformed.
  static Duration? _parseTime(String raw) {
    final match =
        RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$').firstMatch(raw);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '') ?? 0;
    if (hour > 23 || minute > 59 || second > 59) return null;
    return Duration(hours: hour, minutes: minute, seconds: second);
  }

  static String _firstNonEmpty(List<dynamic> candidates, String fallback) {
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
    }
    return fallback;
  }
}
