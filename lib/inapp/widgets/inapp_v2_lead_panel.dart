import 'package:flutter/material.dart';

import '../../data/model/inapp/inapp_message_v2.dart';
import '../../data/model/inapp/inapp_wheel_v2.dart';
import 'inapp_v2_colors.dart';

/// Lead-capture form panel shared by the gamified In-App types
/// (Wheel/roleta and Scratch/raspadinha).
class InAppV2LeadPanel extends StatefulWidget {
  /// Kill switch for the lead-capture step, shared by all gamified cards.
  /// The flow is fully implemented and tested, but product decided not to
  /// render it for now — flip to `true` to honor `leadCapture.enabled` from
  /// the payload again.
  static bool renderLeadCapture = false;

  final InAppV2LeadCapture leadCapture;
  final InAppV2Style style;

  /// When `true` the panel is unlocking a locked prize (`position: "after"`)
  /// and shows [InAppV2LeadCapture.unlockText] on top.
  final bool unlockMode;
  final void Function(Map<String, String> lead) onSubmitted;

  const InAppV2LeadPanel({
    super.key,
    required this.leadCapture,
    required this.style,
    required this.unlockMode,
    required this.onSubmitted,
  });

  @override
  State<InAppV2LeadPanel> createState() => _InAppV2LeadPanelState();
}

class _InAppV2LeadPanelState extends State<InAppV2LeadPanel> {
  final _formKey = GlobalKey<FormState>();
  late final Map<InAppV2LeadField, TextEditingController> _controllers;

  InAppV2LeadCapture get leadCapture => widget.leadCapture;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in leadCapture.fields) field: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmitted({
      for (final entry in _controllers.entries)
        (entry.key.label.isNotEmpty ? entry.key.label : entry.key.type):
            entry.value.text.trim(),
    });
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

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
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
            if (widget.unlockMode && leadCapture.unlockText.isNotEmpty)
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
                  controller: _controllers[field],
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
                onPressed: _submit,
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
}
