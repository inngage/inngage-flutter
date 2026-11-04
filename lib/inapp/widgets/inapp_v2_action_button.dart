import 'package:flutter/material.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import 'inapp_v2_colors.dart';

/// Styled action button from the In-App contract (`text` + `style`), shared
/// by the banner slides and the Countdown card.
class InAppV2ActionButton extends StatelessWidget {
  final InAppV2Button button;
  final VoidCallback onPressed;

  const InAppV2ActionButton({
    super.key,
    required this.button,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            inAppColorOr(button.style.backgroundColor, Colors.black),
        foregroundColor: inAppColorOr(button.style.textColor, Colors.white),
        overlayColor: button.style.hoverColor.isEmpty
            ? null
            : inAppColorOr(button.style.hoverColor, Colors.transparent),
      ),
      onPressed: onPressed,
      child: Text(button.text, textAlign: TextAlign.center),
    );
  }
}
