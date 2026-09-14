import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/inapp/draw_weighted.dart';

void main() {
  test('distributes draws proportionally to the weights', () {
    final random = Random(42);
    const weights = [3, 2, 4, 1]; // total 10
    final counts = List.filled(weights.length, 0);

    const rounds = 10000;
    for (var i = 0; i < rounds; i++) {
      counts[drawWeighted(weights, random: random)]++;
    }

    for (var i = 0; i < weights.length; i++) {
      final expected = rounds * weights[i] / 10;
      expect(
        counts[i],
        inInclusiveRange((expected * 0.85).floor(), (expected * 1.15).ceil()),
        reason: 'index $i drawn ${counts[i]} times, expected ~$expected',
      );
    }
  });

  test('never draws entries with zero or negative weight', () {
    final random = Random(7);
    for (var i = 0; i < 1000; i++) {
      final index = drawWeighted([0, 5, -3], random: random);
      expect(index, 1);
    }
  });

  test('single entry is always drawn', () {
    expect(drawWeighted([1], random: Random(1)), 0);
    expect(drawWeighted([0], random: Random(1)), 0);
  });

  test('all-zero weights fall back to a uniform draw', () {
    final random = Random(3);
    final seen = <int>{};
    for (var i = 0; i < 200; i++) {
      seen.add(drawWeighted([0, 0, 0], random: random));
    }
    expect(seen, {0, 1, 2});
  });

  test('empty list throws', () {
    expect(() => drawWeighted([]), throwsArgumentError);
  });
}
