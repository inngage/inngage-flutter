import 'dart:math';

/// Weighted draw shared by the gamified In-App types (Wheel/roleta and the
/// future Scratch/raspadinha): returns the index of the drawn entry, with
/// probability proportional to its weight.
///
/// Non-positive weights are treated as 0 (never drawn). When [weights] is
/// empty or all weights are 0, falls back to a uniform draw (or 0 for an
/// empty list is invalid — throws [ArgumentError]).
///
/// [random] is injectable for deterministic tests.
int drawWeighted(List<int> weights, {Random? random}) {
  if (weights.isEmpty) {
    throw ArgumentError('drawWeighted requires at least one entry');
  }

  final rng = random ?? Random();
  final sanitized = weights.map((w) => w > 0 ? w : 0).toList();
  final total = sanitized.fold<int>(0, (sum, w) => sum + w);

  if (total == 0) return rng.nextInt(weights.length);

  var ticket = rng.nextInt(total);
  for (var i = 0; i < sanitized.length; i++) {
    ticket -= sanitized[i];
    if (ticket < 0) return i;
  }
  return sanitized.length - 1;
}
