import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/model/inapp/inapp_wheel_v2.dart';
import 'inapp_v2_colors.dart';

/// Win/lose result panel shared by the gamified In-App types: emoji + title,
/// prize label, optional coupon with copy-to-clipboard, solid or gradient
/// background. With [locked] the coupon and body are withheld (the lead form
/// unlocks them in the `position: "after"` flow).
class InAppV2ResultPanel extends StatelessWidget {
  final InAppV2ResultConfig result;
  final bool won;
  final String prizeLabel;
  final String? couponCode;
  final bool locked;

  const InAppV2ResultPanel({
    super.key,
    required this.result,
    required this.won,
    required this.prizeLabel,
    required this.couponCode,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = inAppColorOr(result.style.textColor, Colors.black);

    final background = result.style.gradient
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                inAppColorOr(result.style.bgFrom, Colors.white),
                inAppColorOr(result.style.bgTo, Colors.white),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          )
        : BoxDecoration(
            color: inAppColorOr(result.style.bgFrom, Colors.white),
            borderRadius: BorderRadius.circular(12),
          );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? result.winEmoji : result.loseEmoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            won ? result.winTitle : result.loseTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (prizeLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                prizeLabel,
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          if (won && !locked && (couponCode ?? '').isNotEmpty)
            _CouponBox(code: couponCode!, textColor: textColor),
          if (result.body.isNotEmpty && !locked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                result.body,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _CouponBox extends StatelessWidget {
  final String code;
  final Color textColor;

  const _CouponBox({required this.code, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('Cupom copiado!')),
              );
            },
            child: Icon(
              Icons.copy,
              size: 18,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
