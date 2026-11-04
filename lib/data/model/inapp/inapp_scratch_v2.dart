// In-App v2 "Scratch" (raspadinha) models. These arrive in the same
// /objectMessage response, discriminated by `type: "Scratch"`.

class InAppV2ScratchPrize {
  final String label;

  /// Coupon code. `null`/empty means the prize is a losing one.
  final String? code;
  final int weight;

  const InAppV2ScratchPrize({this.label = '', this.code, this.weight = 1});

  factory InAppV2ScratchPrize.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight'];
    return InAppV2ScratchPrize(
      label: json['label'] as String? ?? '',
      code: json['code'] as String?,
      weight: rawWeight is int
          ? rawWeight
          : int.tryParse(rawWeight?.toString() ?? '') ?? 1,
    );
  }

  bool get isWin => code != null && code!.isNotEmpty;
}

class InAppV2ScratchConfig {
  final String coverColor;
  final String instruction;

  /// Percentage of the cover that must be scratched before the card fully
  /// reveals itself and moves on to the result panel.
  final int revealPercent;
  final List<InAppV2ScratchPrize> prizes;

  /// "Maximum repetitions" configured in the campaign editor (how many times
  /// the same user may play). Parsed for completeness only: the SDK draws
  /// once per display and never re-opens the card by itself, so any limit
  /// is enforced by the server when it decides whether to deliver the
  /// campaign again. `null` when absent.
  final int? maxRepetitions;

  const InAppV2ScratchConfig({
    this.coverColor = '#9CA3AF',
    this.instruction = '',
    this.revealPercent = 50,
    this.prizes = const [],
    this.maxRepetitions,
  });

  factory InAppV2ScratchConfig.fromJson(Map<String, dynamic> json) {
    final rawPercent = json['revealPercent'];
    final percent = rawPercent is int
        ? rawPercent
        : int.tryParse(rawPercent?.toString() ?? '') ?? 50;
    final rawPrizes = json['prizes'];
    final rawMaxRepetitions = json['maxRepetitions'];
    return InAppV2ScratchConfig(
      coverColor: json['coverColor'] as String? ?? '#9CA3AF',
      instruction: json['instruction'] as String? ?? '',
      revealPercent: percent.clamp(1, 100),
      prizes: rawPrizes is List
          ? rawPrizes
              .whereType<Map<String, dynamic>>()
              .map(InAppV2ScratchPrize.fromJson)
              .toList()
          : const [],
      maxRepetitions: rawMaxRepetitions is int
          ? rawMaxRepetitions
          : int.tryParse(rawMaxRepetitions?.toString() ?? ''),
    );
  }
}
