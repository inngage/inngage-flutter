import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_scratch_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_card.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_lead_panel.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_scratch_card.dart';

/// Builds a Scratch message. With [allWinning] every prize has a coupon and
/// with `false` none has, making the (random) draw deterministic for result
/// assertions. No icon/images to keep widget tests off the network.
InAppMessageV2 _scratchMessage({
  bool leadEnabled = true,
  String leadPosition = 'before',
  bool allWinning = true,
  bool hideBrand = false,
}) {
  return InAppMessageV2.fromJson({
    'type': 'Scratch',
    'hideBrand': hideBrand,
    'content': {'title': 'Raspe e ganhe!', 'body': 'Prêmio secreto.'},
    'leadCapture': {
      'enabled': leadEnabled,
      'position': leadPosition,
      'fields': [
        {'type': 'email', 'label': 'Seu e-mail'}
      ],
      'button': {'text': 'Continuar'},
      'consentText': 'Termos & Condições.',
      'unlockText': 'Cadastre-se para liberar seu cupom',
    },
    'scratch': {
      'coverColor': '#9CA3AF',
      'instruction': 'Raspe aqui ✨',
      'revealPercent': 55,
      'prizes': [
        {'label': 'A', 'code': allWinning ? 'RASPAA' : null, 'weight': 1},
        {'label': 'B', 'code': allWinning ? 'RASPAB' : null, 'weight': 1},
      ],
    },
    'result': {
      'winTitle': 'Você ganhou',
      'loseTitle': 'Não foi dessa vez!',
      'body': 'Use o cupom no checkout.',
      'winEmoji': '🎁',
      'loseEmoji': '🙂',
      'style': {
        'gradient': true,
        'bgFrom': '#FEF3C7',
        'bgTo': '#FDE68A',
        'textColor': '#92400E',
      },
    },
  });
}

Future<void> _openScratch(
  WidgetTester tester,
  InAppMessageV2 message, {
  void Function(Map<String, String>)? onLeadCaptured,
  void Function(InAppV2ScratchPrize)? onScratchResult,
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
                onScratchResult: onScratchResult,
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

/// Scratch-gesture percentages are not deterministic in widget tests, so the
/// post-threshold transition is triggered through the card's test seam.
Future<void> _reveal(WidgetTester tester) async {
  final dynamic state = tester.state(find.byType(InAppV2ScratchCard));
  state.completeReveal();
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => InAppV2LeadPanel.renderLeadCapture = false);

  testWidgets('shows the cover with instruction and hides the coupon',
      (tester) async {
    final results = <InAppV2ScratchPrize>[];
    await _openScratch(
      tester,
      _scratchMessage(leadEnabled: false),
      onScratchResult: results.add,
    );

    expect(find.text('Raspe e ganhe!'), findsOneWidget);
    expect(find.text('Raspe aqui ✨'), findsOneWidget);
    // The prize is drawn upfront but nothing is delivered before the reveal.
    expect(results, isEmpty);
    expect(find.text('Você ganhou'), findsNothing);
  });

  testWidgets('reveal delivers the drawn prize and shows the win result',
      (tester) async {
    final results = <InAppV2ScratchPrize>[];
    await _openScratch(
      tester,
      _scratchMessage(leadEnabled: false),
      onScratchResult: results.add,
    );

    await _reveal(tester);

    expect(results, hasLength(1));
    expect(results.single.isWin, isTrue);
    expect(find.text('Você ganhou'), findsOneWidget);
    expect(find.text(results.single.code!), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.text('Use o cupom no checkout.'), findsOneWidget);
  });

  testWidgets('losing reveal shows the lose panel without a coupon',
      (tester) async {
    await _openScratch(
        tester, _scratchMessage(leadEnabled: false, allWinning: false));

    await _reveal(tester);

    expect(find.text('Não foi dessa vez!'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsNothing);
  });

  testWidgets('lead capture is not rendered while the kill switch is off',
      (tester) async {
    await _openScratch(tester, _scratchMessage());

    expect(find.text('Continuar'), findsNothing);
    expect(find.text('Raspe aqui ✨'), findsOneWidget);
  });

  testWidgets('before flow: form gates the scratch area', (tester) async {
    InAppV2LeadPanel.renderLeadCapture = true;
    final leads = <Map<String, String>>[];
    await _openScratch(tester, _scratchMessage(), onLeadCaptured: leads.add);

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Raspe aqui ✨'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'user@inngage.com.br');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(leads.single, {'Seu e-mail': 'user@inngage.com.br'});
    expect(find.text('Raspe aqui ✨'), findsOneWidget);
  });

  testWidgets('after flow: winning coupon stays locked until sign-up',
      (tester) async {
    InAppV2LeadPanel.renderLeadCapture = true;
    final results = <InAppV2ScratchPrize>[];
    await _openScratch(
      tester,
      _scratchMessage(leadPosition: 'after'),
      onScratchResult: results.add,
    );

    // Scratch comes first in the `after` flow.
    expect(find.text('Raspe aqui ✨'), findsOneWidget);
    await _reveal(tester);

    final code = results.single.code!;
    expect(find.text('Cadastre-se para liberar seu cupom'), findsOneWidget);
    expect(find.text(code), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'user@inngage.com.br');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text(code), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('brand footer follows hideBrand', (tester) async {
    await _openScratch(tester, _scratchMessage(leadEnabled: false));
    expect(find.text('Powered by Inngage'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await _openScratch(
        tester, _scratchMessage(leadEnabled: false, hideBrand: true));
    expect(find.text('Powered by Inngage'), findsNothing);
  });
}
