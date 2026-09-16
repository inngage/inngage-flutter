import 'package:flutter/material.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import 'inapp_v2_colors.dart';

/// Header shared by the gamified In-App cards: close affordance plus the
/// `content` title/body. The payload `icon` is intentionally not rendered
/// (product decision).
class InAppV2GamifiedHeader extends StatelessWidget {
  final InAppMessageV2 message;

  const InAppV2GamifiedHeader({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final style = message.style;
    final content = message.content;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: inAppColorOr(style.bodyColor, Colors.black)
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if ((content?.title ?? '').isNotEmpty)
            Text(
              content!.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: inAppColorOr(style.titleColor, Colors.black),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if ((content?.body ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                content!.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inAppColorOr(style.bodyColor, Colors.black),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Powered by Inngage" footer, shown unless the payload sets `hideBrand`.
class InAppV2BrandFooter extends StatelessWidget {
  final InAppMessageV2 message;

  const InAppV2BrandFooter({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.hideBrand) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Powered by Inngage',
        style: TextStyle(
          fontSize: 11,
          color: inAppColorOr(message.style.bodyColor, Colors.black)
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
