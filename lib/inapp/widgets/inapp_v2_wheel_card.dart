import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import '../../data/model/inapp/inapp_wheel_v2.dart';
import '../draw_weighted.dart';
import 'inapp_v2_colors.dart';

enum _WheelStage { leadForm, wheel, resultLocked, result }

/// The "Wheel" (roleta) In-App content: optional lead-capture form, a
/// weighted-draw fortune wheel (the draw happens BEFORE the animation, which
/// then lands on the drawn slice) and a win/lose result panel with the coupon.
class InAppV2WheelCard extends StatefulWidget {
  /// Kill switch for the lead-capture step. The flow is fully implemented and
  /// tested, but product decided not to render it for now — flip to `true`
  /// to honor `leadCapture.enabled` from the payload again.
  static bool renderLeadCapture = false;

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
  final _formKey = GlobalKey<FormState>();
  late final Map<InAppV2LeadField, TextEditingController> _fieldControllers;

  late _WheelStage _stage;
  InAppV2WheelSlice? _drawnSlice;
  bool _spinning = false;

  InAppMessageV2 get message => widget.message;
  InAppV2LeadCapture get leadCapture => message.leadCapture;

  bool get _leadCaptureActive =>
      InAppV2WheelCard.renderLeadCapture && leadCapture.enabled;

  @override
  void initState() {
    super.initState();
    _fieldControllers = {
      for (final field in leadCapture.fields) field: TextEditingController(),
    };
    _stage = _leadCaptureActive && leadCapture.capturesBeforeSpin
        ? _WheelStage.leadForm
        : _WheelStage.wheel;
  }

  @override
  void dispose() {
    _selectedController.close();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
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

  void _submitLead() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lead = <String, String>{
      for (final entry in _fieldControllers.entries)
        (entry.key.label.isNotEmpty ? entry.key.label : entry.key.type):
            entry.value.text.trim(),
    };
    widget.onLeadCaptured?.call(lead);
    setState(() {
      _stage = _stage == _WheelStage.leadForm
          ? _WheelStage.wheel
          : _WheelStage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = message.style;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildStage(),
        if (!message.hideBrand)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Powered by Inngage',
              style: TextStyle(
                fontSize: 11,
                color: inAppColorOr(style.bodyColor, Colors.black)
                    .withValues(alpha: 0.5),
              ),
            ),
          )
        else
          const SizedBox(height: 8),
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

  Widget _buildHeader() {
    final style = message.style;
    final content = message.content;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The payload `icon` is intentionally not rendered (product
          // decision); the row keeps only the close affordance.
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

  Widget _buildLeadPanel({required bool unlockMode}) {
    final style = message.style;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inAppColorOr(style.titleColor, Colors.black)
            .withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unlockMode && leadCapture.unlockText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  leadCapture.unlockText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: inAppColorOr(style.titleColor, Colors.black),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            for (final field in leadCapture.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _fieldControllers[field],
                  keyboardType: field.type == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: field.label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  validator: (value) => _validateField(field, value),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inAppColorOr(
                      leadCapture.buttonStyle.backgroundColor, Colors.black),
                  foregroundColor: inAppColorOr(
                      leadCapture.buttonStyle.textColor, Colors.white),
                ),
                onPressed: _submitLead,
                child: Text(leadCapture.buttonText),
              ),
            ),
            if (leadCapture.consentText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  leadCapture.consentText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        inAppColorOr(leadCapture.consentColor, Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _validateField(InAppV2LeadField field, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Campo obrigatório';
    if (field.type == 'email' &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'E-mail inválido';
    }
    return null;
  }

  Widget _buildResultPanel({required bool locked}) {
    final result = message.result;
    final slice = _drawnSlice;
    final won = slice?.isWin ?? false;
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
          if ((slice?.label ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                slice!.label,
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          if (won && !locked) _buildCouponBox(slice!.code!, textColor),
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

  Widget _buildCouponBox(String code, Color textColor) {
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
