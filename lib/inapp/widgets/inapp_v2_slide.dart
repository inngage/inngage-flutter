import 'package:flutter/material.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import 'inapp_v2_action_button.dart';
import 'inapp_v2_colors.dart';

/// A single In-App slide: image, title/body and action buttons. Used both as
/// a standalone banner (single item) and as a carousel page (2+ items).
class InAppV2Slide extends StatelessWidget {
  final InAppV2CarouselItem item;
  final InAppV2Style style;
  final String mediaPosition;

  /// Called after the dialog is popped by a tap on a button/background.
  final ValueChanged<InAppV2Action> onActionTriggered;

  /// Click-tracking hook; receives where the user clicked (`card`, `button`,
  /// `button_up` or `button_down`).
  final void Function(String clickSource)? onClickTracked;

  const InAppV2Slide({
    super.key,
    required this.item,
    required this.style,
    required this.mediaPosition,
    required this.onActionTriggered,
    this.onClickTracked,
  });

  void _trigger(
      BuildContext context, InAppV2Action? action, String clickSource) {
    onClickTracked?.call(clickSource);
    Navigator.of(context).pop();
    onActionTriggered(action ?? const InAppV2Action());
  }

  @override
  Widget build(BuildContext context) {
    final image = item.image.isNotEmpty
        ? Image.network(
            item.image,
            width: double.infinity,
            height: 160,
            // The contract only defines "fill" (center-crop); any other value
            // gets the same treatment until new modes are specified.
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        : null;

    final texts = <Widget>[
      if (item.content.title.isNotEmpty)
        Text(
          item.content.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: inAppColorOr(style.titleColor, Colors.black),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      if (item.content.body.isNotEmpty) ...[
        if (item.content.title.isNotEmpty) const SizedBox(height: 8),
        Text(
          item.content.body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: inAppColorOr(style.bodyColor, Colors.black),
            fontSize: 14,
          ),
        ),
      ],
    ];

    final imageOnBottom = mediaPosition.toLowerCase() == 'bottom';
    final backgroundClick = item.actions.backgroundClick;

    final slideBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (image != null && !imageOnBottom) image,
        if (texts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(mainAxisSize: MainAxisSize.min, children: texts),
          ),
        if (image != null && imageOnBottom)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: image,
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (backgroundClick != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _trigger(context, backgroundClick, 'card'),
            child: slideBody,
          )
        else
          slideBody,
        if (item.actions.buttons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildButtons(context),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    final all = item.actions.buttons;
    final buttons = [
      for (var i = 0; i < all.length; i++)
        InAppV2ActionButton(
          button: all[i],
          onPressed: () => _trigger(
            context,
            all[i].action,
            all.length == 1 ? 'button' : (i == 0 ? 'button_up' : 'button_down'),
          ),
        ),
    ];

    if (buttons.length <= 2) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: buttons[i]),
        ],
      ],
    );
  }
}
