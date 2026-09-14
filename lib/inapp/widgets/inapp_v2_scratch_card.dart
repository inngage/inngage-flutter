import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import '../../data/model/inapp/inapp_scratch_v2.dart';
import '../../data/model/inapp/inapp_wheel_v2.dart';
import '../draw_weighted.dart';
import 'inapp_v2_colors.dart';
import 'inapp_v2_gamified_header.dart';
import 'inapp_v2_lead_panel.dart';
import 'inapp_v2_result_panel.dart';

enum _ScratchStage { leadForm, scratch, resultLocked, result }

/// The "Scratch" (raspadinha) In-App content. The weighted draw happens in
/// [initState], BEFORE the cover is shown — what gets revealed under the
/// scratch layer is already the drawn prize. Reaching `revealPercent`
/// finishes the reveal and moves on to the shared result panel.
class InAppV2ScratchCard extends StatefulWidget {
  final InAppMessageV2 message;
  final void Function(Map<String, String> lead)? onLeadCaptured;
  final void Function(InAppV2ScratchPrize prize)? onScratchResult;

  const InAppV2ScratchCard({
    super.key,
    required this.message,
    this.onLeadCaptured,
    this.onScratchResult,
  });

  @override
  State<InAppV2ScratchCard> createState() => _InAppV2ScratchCardState();
}

class _InAppV2ScratchCardState extends State<InAppV2ScratchCard> {
  final _scratcherKey = GlobalKey<ScratcherState>();

  late final InAppV2ScratchPrize _drawnPrize;
  late _ScratchStage _stage;
  bool _scratchStarted = false;
  bool _revealed = false;

  InAppMessageV2 get message => widget.message;
  InAppV2LeadCapture get leadCapture => message.leadCapture;
  InAppV2ScratchConfig get scratch => message.scratch;

  bool get _leadCaptureActive =>
      InAppV2LeadPanel.renderLeadCapture && leadCapture.enabled;

  @override
  void initState() {
    super.initState();
    // Draw before the cover is shown: the revealed prize IS the result.
    final prizes = scratch.prizes;
    _drawnPrize = prizes[drawWeighted(prizes.map((p) => p.weight).toList())];
    _stage = _leadCaptureActive && leadCapture.capturesBeforeSpin
        ? _ScratchStage.leadForm
        : _ScratchStage.scratch;
  }

  void _onThresholdReached() {
    // Finish the reveal for the user, then move to the result panel.
    _scratcherKey.currentState?.reveal(
      duration: const Duration(milliseconds: 300),
    );
    Future.delayed(const Duration(milliseconds: 700), _completeReveal);
  }

  /// Also the test seam: scratch-gesture percentages are not deterministic
  /// in widget tests, so tests trigger the post-threshold transition here.
  @visibleForTesting
  void completeReveal() => _completeReveal();

  void _completeReveal() {
    if (_revealed || !mounted) return;
    _revealed = true;
    widget.onScratchResult?.call(_drawnPrize);
    setState(() {
      // With `after` capture, a winning coupon stays locked until the lead
      // form is submitted; a losing scratch has nothing to unlock.
      _stage = _leadCaptureActive &&
              !leadCapture.capturesBeforeSpin &&
              _drawnPrize.isWin
          ? _ScratchStage.resultLocked
          : _ScratchStage.result;
    });
  }

  void _onLeadSubmitted(Map<String, String> lead) {
    widget.onLeadCaptured?.call(lead);
    setState(() {
      _stage = _stage == _ScratchStage.leadForm
          ? _ScratchStage.scratch
          : _ScratchStage.result;
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
      case _ScratchStage.leadForm:
        return InAppV2LeadPanel(
          leadCapture: leadCapture,
          style: message.style,
          unlockMode: false,
          onSubmitted: _onLeadSubmitted,
        );
      case _ScratchStage.scratch:
        return _buildScratchPanel();
      case _ScratchStage.resultLocked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultPanel(locked: true),
            InAppV2LeadPanel(
              leadCapture: leadCapture,
              style: message.style,
              unlockMode: true,
              onSubmitted: _onLeadSubmitted,
            ),
          ],
        );
      case _ScratchStage.result:
        return _buildResultPanel(locked: false);
    }
  }

  Widget _buildResultPanel({required bool locked}) {
    return InAppV2ResultPanel(
      result: message.result,
      won: _drawnPrize.isWin,
      prizeLabel: _drawnPrize.label,
      couponCode: _drawnPrize.code,
      locked: locked,
    );
  }

  Widget _buildScratchPanel() {
    final style = message.style;
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Scratcher(
                key: _scratcherKey,
                brushSize: 40,
                threshold: scratch.revealPercent.toDouble(),
                color: inAppColorOr(scratch.coverColor, Colors.grey),
                onScratchStart: () {
                  if (!_scratchStarted) {
                    setState(() => _scratchStarted = true);
                  }
                },
                onThreshold: _onThresholdReached,
                child: Container(
                  color: inAppColorOr(style.backgroundColor, Colors.white),
                  alignment: Alignment.center,
                  child: Text(
                    _drawnPrize.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: inAppColorOr(style.titleColor, Colors.black),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!_scratchStarted && scratch.instruction.isNotEmpty)
                IgnorePointer(
                  child: Center(
                    child: Text(
                      scratch.instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
