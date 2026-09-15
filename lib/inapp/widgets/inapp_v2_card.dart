import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import '../../data/model/inapp/inapp_scratch_v2.dart';
import '../../data/model/inapp/inapp_wheel_v2.dart';
import 'inapp_v2_colors.dart';
import 'inapp_v2_countdown_card.dart';
import 'inapp_v2_scratch_card.dart';
import 'inapp_v2_slide.dart';
import 'inapp_v2_wheel_card.dart';

/// The In-App message dialog card. Renders a banner when the message has a
/// single slide, a carousel (with dot indicator) when it has two or more,
/// the fortune-wheel flow for `type: "Wheel"`, the scratch-card flow for
/// `type: "Scratch"` and the ticking-deadline card for `type: "Countdown"`
/// messages.
class InAppV2Card extends StatelessWidget {
  static const double _carouselHeight = 360;

  final InAppMessageV2 message;
  final ValueChanged<InAppV2Action> onActionTriggered;
  final void Function(Map<String, String> lead)? onLeadCaptured;
  final void Function(InAppV2WheelSlice slice)? onWheelResult;
  final void Function(InAppV2ScratchPrize prize)? onScratchResult;

  const InAppV2Card({
    super.key,
    required this.message,
    required this.onActionTriggered,
    this.onLeadCaptured,
    this.onWheelResult,
    this.onScratchResult,
  });

  Alignment get _alignment {
    switch (message.style.position.toLowerCase()) {
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = message.style;
    final items =
        message.media.items.where((item) => item.hasRenderableContent).toList();

    final backgroundImage = style.backgroundImage ?? '';
    final borderRadius = BorderRadius.circular(12);

    return Dialog(
      alignment: _alignment,
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: inAppColorOr(style.backgroundColor, Colors.white),
          borderRadius: borderRadius,
          border: style.borderColor.isEmpty
              ? null
              : Border.all(
                  color: inAppColorOr(style.borderColor, Colors.transparent)),
          boxShadow: style.shadow
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
          image: backgroundImage.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(backgroundImage),
                  fit: BoxFit.cover,
                ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: _buildContent(context, items),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<InAppV2CarouselItem> items) {
    if (message.isWheel) {
      return InAppV2WheelCard(
        message: message,
        onLeadCaptured: onLeadCaptured,
        onWheelResult: onWheelResult,
      );
    }

    if (message.isScratch) {
      return InAppV2ScratchCard(
        message: message,
        onLeadCaptured: onLeadCaptured,
        onScratchResult: onScratchResult,
      );
    }

    if (message.isCountdown) {
      return InAppV2CountdownCard(
        message: message,
        onActionTriggered: onActionTriggered,
      );
    }

    if (items.isEmpty) {
      // Background-image-only message: give the image room to show and let
      // a tap anywhere dismiss it.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(width: double.infinity, height: 200),
      );
    }

    if (items.length == 1) {
      return InAppV2Slide(
        item: items.first,
        style: message.style,
        mediaPosition: message.media.position,
        onActionTriggered: onActionTriggered,
      );
    }

    return ImageSlideshow(
      height: _carouselHeight,
      isLoop: false,
      indicatorColor: inAppColorOr(message.style.titleColor, Colors.black87),
      indicatorBackgroundColor: Colors.black26,
      children: [
        for (final item in items)
          SingleChildScrollView(
            child: InAppV2Slide(
              item: item,
              style: message.style,
              mediaPosition: message.media.position,
              onActionTriggered: onActionTriggered,
            ),
          ),
      ],
    );
  }
}
