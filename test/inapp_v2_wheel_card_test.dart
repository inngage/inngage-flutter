import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_wheel_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_card.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_lead_panel.dart';

/// Builds a Wheel message. With [allWinning] every slice has a coupon and
/// with `false` none has, making the (random) draw deterministic for result
/// assertions. No icon/images to keep widget tests off the network.
InAppMessageV2 _wheelMessage({
  bool leadEnabled = true,
  String leadPosition = 'before',
  bool allWinning = true,
  bool hideBrand = false,
}) {
  return InAppMessageV2.fromJson({
    'type': 'Wheel',
    'hideBrand': hideBrand,
    'content': {'title': 'Gire a roleta', 'body': 'Boa sorte!'},
    'leadCapture': {
      'enabled': leadEnabled,
      'position': leadPosition,
      'fields': [
        {'type': 'email', 'label': 'Seu e-mail'}
      ],
      'button': {'text': 'Liberar meu giro'},
      'consentText': 'Termos & Condições.',
      'unlockText': 'Cadastre-se para liberar seu cupom',
    },
    'wheel': {
      'buttonText': 'Girar 🎡',
      'button': {'backgroundColor': '#7C3AED', 'textColor': '#FFFFFF'},
      'slices': [
        {
          'label': 'A',
          'color': '#7C3AED',
          'code': allWinning ? 'CUPOMA' : null,
          'weight': 1
        },
        {
          'label': 'B',
          'color': '#F59E0B',
          'code': allWinning ? 'CUPOMB' : null,
          'weight': 1
        },
      ],
    },
    'result': {
      'winTitle': 'Parabéns!',
      'loseTitle': 'Foi por pouco!',
      'body': 'Apresente no checkout.',
      'winEmoji': '🎁',
      'loseEmoji': '🙂',
      'style': {'textColor': '#111827'},
    },
  });
}

Future<void> _openWheel(
  WidgetTester tester,
  InAppMessageV2 message, {
  void Function(Map<String, String>)? onLeadCaptured,
  void Function(InAppV2WheelSlice)? onWheelResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => InAppV2Card(
                message: message,
                onActionTriggered: (_) {},
                onLeadCaptured: onLeadCaptured,
                onWheelResult: onWheelResult,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _spin(WidgetTester tester) async {
  await tester.tap(find.text('Girar 🎡'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 6));
  await tester.pump();
}

void main() {
  tearDown(() => InAppV2LeadPanel.renderLeadCapture = false);

  testWidgets(
      'lead capture is not rendered while the kill switch is off (default)',
      (tester) async {
    await _openWheel(tester, _wheelMessage());

    // Payload asks for lead capture, but the flow starts on the wheel.
    expect(find.text('Liberar meu giro'), findsNothing);
    expect(find.text('Girar 🎡'), findsOneWidget);
  });

  testWidgets('before flow: form gates the wheel and validates the e-mail',
      (tester) async {
    InAppV2LeadPanel.renderLeadCapture = true;
    final leads = <Map<String, String>>[];
    await _openWheel(tester, _wheelMessage(), onLeadCaptured: leads.add);

    // Form first, no wheel yet.
    expect(find.text('Liberar meu giro'), findsOneWidget);
    expect(find.text('Termos & Condições.'), findsOneWidget);
    expect(find.text('Girar 🎡'), findsNothing);

    // Invalid e-mail is rejected.
    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Liberar meu giro'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail inválido'), findsOneWidget);
    expect(leads, isEmpty);

    // Valid e-mail unlocks the wheel and delivers the lead.
    await tester.enterText(find.byType(TextFormField), 'user@inngage.com.br');
    await tester.tap(find.text('Liberar meu giro'));
    await tester.pumpAndSettle();
    expect(leads.single, {'Seu e-mail': 'user@inngage.com.br'});
    expect(find.text('Girar 🎡'), findsOneWidget);
  });

  testWidgets('spin lands on the drawn slice and shows the win result',
      (tester) async {
    final results = <InAppV2WheelSlice>[];
    await _openWheel(
      tester,
      _wheelMessage(leadEnabled: false),
      onWheelResult: results.add,
    );

    expect(find.text('Girar 🎡'), findsOneWidget);
    await _spin(tester);

    expect(results, hasLength(1));
    expect(results.single.isWin, isTrue);
    expect(find.text('Parabéns!'), findsOneWidget);
    expect(find.text(results.single.code!), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.text('Apresente no checkout.'), findsOneWidget);
    // Single spin per display: the button is gone.
    expect(find.text('Girar 🎡'), findsNothing);
  });

  testWidgets('losing spin shows the lose panel without a coupon',
      (tester) async {
    await _openWheel(
        tester, _wheelMessage(leadEnabled: false, allWinning: false));

    await _spin(tester);

    expect(find.text('Foi por pouco!'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsNothing);
  });

  testWidgets('after flow: winning coupon stays locked until sign-up',
      (tester) async {
    InAppV2LeadPanel.renderLeadCapture = true;
    final results = <InAppV2WheelSlice>[];
    await _openWheel(
      tester,
      _wheelMessage(leadPosition: 'after'),
      onWheelResult: results.add,
    );

    // Wheel comes first in the `after` flow.
    expect(find.text('Girar 🎡'), findsOneWidget);
    await _spin(tester);

    // Locked preview: unlock text visible, coupon hidden.
    final code = results.single.code!;
    expect(find.text('Cadastre-se para liberar seu cupom'), findsOneWidget);
    expect(find.text(code), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'user@inngage.com.br');
    await tester.tap(find.text('Liberar meu giro'));
    await tester.pumpAndSettle();

    expect(find.text(code), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('copy button shows the copied feedback', (tester) async {
    await _openWheel(tester, _wheelMessage(leadEnabled: false));
    await _spin(tester);

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(find.text('Cupom copiado!'), findsOneWidget);
  });

  testWidgets('brand footer follows hideBrand', (tester) async {
    await _openWheel(tester, _wheelMessage(leadEnabled: false));
    expect(find.text('Powered by Inngage'), findsOneWidget);
  });

  testWidgets('hideBrand true suppresses the footer', (tester) async {
    await _openWheel(
        tester, _wheelMessage(leadEnabled: false, hideBrand: true));
    expect(find.text('Powered by Inngage'), findsNothing);
  });
}
