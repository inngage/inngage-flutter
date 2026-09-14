import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import '../../data/model/inapp/inapp_wheel_v2.dart';
import '../draw_weighted.dart';
import 'inapp_v2_colors.dart';
import 'inapp_v2_gamified_header.dart';
import 'inapp_v2_lead_panel.dart';
import 'inapp_v2_result_panel.dart';

enum _WheelStage { leadForm, wheel, resultLocked, result }

/// The "Wheel" (roleta) In-App content: optional lead-capture form, a
/// weighted-draw fortune wheel (the draw happens BEFORE the animation, which
/// then lands on the drawn slice) and a win/lose result panel with the coupon.
class InAppV2WheelCard extends StatefulWidget {
  final InAppMessageV2 message;
  final void Function(Map<String, String> lead)? onLeadCaptured;
  final void Function(InAppV2WheelSlice slice)? onWheelResult;

  const InAppV2WheelCard({
    super.key,
    required this.message,
    this.onLeadCaptured,
    this.onWheelResult,
  });

  @override
  State<InAppV2WheelCard> createState() => _InAppV2WheelCardState();
}

class _InAppV2WheelCardState extends State<InAppV2WheelCard> {
  final _selectedController = StreamController<int>.broadcast();

  late _WheelStage _stage;
  InAppV2WheelSlice? _drawnSlice;
  bool _spinning = false;

  InAppMessageV2 get message => widget.message;
  InAppV2LeadCapture get leadCapture => message.leadCapture;

  bool get _leadCaptureActive =>
      InAppV2LeadPanel.renderLeadCapture && leadCapture.enabled;

  @override
  void initState() {
    super.initState();
    _stage = _leadCaptureActive && leadCapture.capturesBeforeSpin
        ? _WheelStage.leadForm
        : _WheelStage.wheel;
  }

  @override
  void dispose() {
    _selectedController.close();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _drawnSlice != null) return;
    final slices = message.wheel.slices;
    final index = drawWeighted(slices.map((s) => s.weight).toList());
    setState(() {
      _spinning = true;
      _drawnSlice = slices[index];
    });
    _selectedController.add(index);
  }

  void _onSpinEnded() {
    if (!_spinning) return;
    final slice = _drawnSlice!;
    widget.onWheelResult?.call(slice);
    setState(() {
      _spinning = false;
      // With `after` capture, a winning coupon stays locked until the lead
      // form is submitted; a losing spin has nothing to unlock.
      _stage =
          _leadCaptureActive && !leadCapture.capturesBeforeSpin && slice.isWin
              ? _WheelStage.resultLocked
              : _WheelStage.result;
    });
  }

  void _onLeadSubmitted(Map<String, String> lead) {
    widget.onLeadCaptured?.call(lead);
    setState(() {
      _stage = _stage == _WheelStage.leadForm
          ? _WheelStage.wheel
          : _WheelStage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InAppV2GamifiedHeader(message: message),
        _buildStage(),
        InAppV2BrandFooter(message: message),
      ],
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _WheelStage.leadForm:
        return _buildLeadPanel(unlockMode: false);
      case _WheelStage.wheel:
        return _buildWheelPanel();
      case _WheelStage.resultLocked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultPanel(locked: true),
            _buildLeadPanel(unlockMode: true),
          ],
        );
      case _WheelStage.result:
        return _buildResultPanel(locked: false);
    }
  }

  Widget _buildLeadPanel({required bool unlockMode}) {
    return InAppV2LeadPanel(
      leadCapture: leadCapture,
      style: message.style,
      unlockMode: unlockMode,
      onSubmitted: _onLeadSubmitted,
    );
  }

  Widget _buildResultPanel({required bool locked}) {
    final slice = _drawnSlice;
    return InAppV2ResultPanel(
      result: message.result,
      won: slice?.isWin ?? false,
      prizeLabel: slice?.label ?? '',
      couponCode: slice?.code,
      locked: locked,
    );
  }

  Widget _buildWheelPanel() {
    final wheel = message.wheel;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 240,
            child: FortuneWheel(
              selected: _selectedController.stream,
              animateFirst: false,
              physics: NoPanPhysics(),
              onAnimationEnd: _onSpinEnded,
              indicators: const [
                FortuneIndicator(
                  alignment: Alignment.topCenter,
                  child: TriangleIndicator(color: Colors.black87),
                ),
              ],
              items: [
                for (final slice in wheel.slices)
                  FortuneItem(
                    style: FortuneItemStyle(
                      color: inAppColorOr(slice.color, Colors.grey),
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    child: Text(
                      slice.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_spinning && _drawnSlice == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inAppColorOr(
                      wheel.buttonStyle.backgroundColor, Colors.black),
                  foregroundColor:
                      inAppColorOr(wheel.buttonStyle.textColor, Colors.white),
                ),
                onPressed: _spin,
                child: Text(wheel.buttonText),
              ),
            ),
        ],
      ),
    );
  }
}
