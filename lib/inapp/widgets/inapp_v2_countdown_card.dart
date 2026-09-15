import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/model/inapp/inapp_countdown_v2.dart';
import '../../data/model/inapp/inapp_message_v2.dart';
import 'inapp_v2_action_button.dart';
import 'inapp_v2_colors.dart';
import 'inapp_v2_gamified_header.dart';

/// The "Countdown" In-App content: four DIAS/HORAS/MIN/SEG boxes ticking
/// every second toward `countdown.endDate`, plus the root-level action
/// buttons. When the deadline is reached while the card is open, the boxes
/// and buttons give way to the expired title/body.
class InAppV2CountdownCard extends StatefulWidget {
  final InAppMessageV2 message;
  final ValueChanged<InAppV2Action> onActionTriggered;

  /// Time source, injectable for deterministic tests.
  final DateTime Function() clock;

  const InAppV2CountdownCard({
    super.key,
    required this.message,
    required this.onActionTriggered,
    this.clock = DateTime.now,
  });

  @override
  State<InAppV2CountdownCard> createState() => _InAppV2CountdownCardState();
}

class _InAppV2CountdownCardState extends State<InAppV2CountdownCard> {
  Timer? _timer;
  late Duration _remaining;

  InAppMessageV2 get message => widget.message;

  bool get _expired => _remaining <= Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final endDate = message.countdown.endDate;
    if (endDate == null) return Duration.zero;
    return endDate.difference(widget.clock());
  }

  void _tick() {
    final remaining = _computeRemaining();
    setState(() => _remaining = remaining);
    if (remaining <= Duration.zero) {
      _timer?.cancel();
    }
  }

  void _onButtonPressed(InAppV2Button button) {
    Navigator.of(context).pop();
    widget.onActionTriggered(button.action ?? const InAppV2Action());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InAppV2GamifiedHeader(message: message),
        if (_expired) _buildExpiredPanel() else _buildCountdownPanel(),
        InAppV2BrandFooter(message: message),
      ],
    );
  }

  Widget _buildCountdownPanel() {
    final remaining = _remaining.isNegative ? Duration.zero : _remaining;
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeBox(config: message.countdown, value: days, label: 'DIAS'),
              const SizedBox(width: 8),
              _TimeBox(config: message.countdown, value: hours, label: 'HORAS'),
              const SizedBox(width: 8),
              _TimeBox(config: message.countdown, value: minutes, label: 'MIN'),
              const SizedBox(width: 8),
              _TimeBox(config: message.countdown, value: seconds, label: 'SEG'),
            ],
          ),
          if (message.buttons.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < message.buttons.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: InAppV2ActionButton(
                  button: message.buttons[i],
                  onPressed: () => _onButtonPressed(message.buttons[i]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExpiredPanel() {
    final style = message.style;
    final countdown = message.countdown;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countdown.expiredTitle.isNotEmpty)
            Text(
              countdown.expiredTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: inAppColorOr(style.titleColor, Colors.black),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (countdown.expiredBody.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                countdown.expiredBody,
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

class _TimeBox extends StatelessWidget {
  final InAppV2CountdownConfig config;
  final int value;
  final String label;

  const _TimeBox({
    required this.config,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final digitColor = inAppColorOr(config.digitColor, Colors.white);
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: inAppColorOr(config.boxColor, Colors.black),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: digitColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: digitColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
