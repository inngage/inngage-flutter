import 'package:flutter/material.dart';

import '../../util/hexcolor.dart';

/// Parses a hex color coming from the In-App contract, falling back when the
/// value is absent, empty or malformed (colors are never worth a crash).
Color inAppColorOr(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return HexColor.fromHex(hex);
  } on FormatException {
    return fallback;
  }
}
