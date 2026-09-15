import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_countdown_card.dart';

final _base = DateTime(2026, 9, 14, 12, 0, 0);

InAppMessageV2 _countdownMessage({
  required DateTime endDate,
  bool hideBrand = false,
}) {
  return InAppMessageV2.fromJson({
    'type': 'Countdown',
    'hideBrand': hideBrand,
    'content': {'title': 'A oferta termina em:', 'body': '30% OFF.'},
    'countdown': {
      'endDate': endDate.toIso8601String(),
      'boxColor': '#111827',
      'digitColor': '#FFFFFF',
      'expiredTitle': 'Oferta encerrada',
      'expiredBody': 'Fique de olho nas próximas!',
    },
    'buttons': [
      {
        'text': 'Aproveitar agora',
        'style': {'backgroundColor': '#7C3AED', 'textColor': '#FFFFFF'},
        'action': {'type': 'weblink', 'url': 'https://www.inngage.com.br'},
      },
    ],
  });
}

/// Pumps the card inside a dialog with a fake clock. Advancing [fakeNow]
/// plus pumping 1s makes the periodic timer tick deterministically.
Future<void> _openCountdown(
  WidgetTester tester,
  InAppMessageV2 message,
  DateTime Function() clock, {
  List<InAppV2Action>? triggered,
  List<String>? tracked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                child: InAppV2CountdownCard(
                  message: message,
                  clock: clock,
                  onActionTriggered: (action) => triggered?.add(action),
                  onClickTracked: tracked?.add,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders the DIAS/HORAS/MIN/SEG boxes with the remaining time',
      (tester) async {
    // 1 day, 1 hour, 57 minutes and 9 seconds ahead — mirrors the reference
    // screenshot (01 / 01 / 57 / 09).
    final endDate =
        _base.add(const Duration(days: 1, hours: 1, minutes: 57, seconds: 9));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => _base);

    expect(find.text('DIAS'), findsOneWidget);
    expect(find.text('HORAS'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('SEG'), findsOneWidget);
    expect(find.text('01'), findsNWidgets(2));
    expect(find.text('57'), findsOneWidget);
    expect(find.text('09'), findsOneWidget);
    expect(find.text('Aproveitar agora'), findsOneWidget);
    expect(find.text('A oferta termina em:'), findsOneWidget);
  });

  testWidgets('ticks every second', (tester) async {
    var fakeNow = _base;
    final endDate = _base.add(const Duration(seconds: 30));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => fakeNow);

    expect(find.text('30'), findsOneWidget);

    fakeNow = fakeNow.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29'), findsOneWidget);

    fakeNow = fakeNow.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('28'), findsOneWidget);
  });

  testWidgets('button closes the dialog and triggers the action',
      (tester) async {
    final triggered = <InAppV2Action>[];
    final endDate = _base.add(const Duration(hours: 2));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => _base,
        triggered: triggered);

    await tester.tap(find.text('Aproveitar agora'));
    await tester.pumpAndSettle();

    expect(find.text('A oferta termina em:'), findsNothing);
    expect(triggered.single.type, InAppV2ActionType.weblink);
    expect(triggered.single.url, 'https://www.inngage.com.br');
  });

  testWidgets(
      'reaching the deadline swaps boxes and buttons for the expired panel',
      (tester) async {
    var fakeNow = _base;
    final endDate = _base.add(const Duration(seconds: 2));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => fakeNow);

    expect(find.text('SEG'), findsOneWidget);
    expect(find.text('Oferta encerrada'), findsNothing);

    fakeNow = fakeNow.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Oferta encerrada'), findsOneWidget);
    expect(find.text('Fique de olho nas próximas!'), findsOneWidget);
    expect(find.text('SEG'), findsNothing);
    expect(find.text('Aproveitar agora'), findsNothing);
  });

  testWidgets('single button click is tracked as "button"', (tester) async {
    final tracked = <String>[];
    final endDate = _base.add(const Duration(hours: 2));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => _base,
        tracked: tracked);

    await tester.tap(find.text('Aproveitar agora'));
    await tester.pumpAndSettle();

    expect(tracked, ['button']);
  });

  testWidgets('brand footer follows hideBrand', (tester) async {
    final endDate = _base.add(const Duration(hours: 1));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => _base);
    expect(find.text('Powered by Inngage'), findsOneWidget);
  });

  testWidgets('hideBrand true suppresses the footer', (tester) async {
    final endDate = _base.add(const Duration(hours: 1));
    await _openCountdown(tester,
        _countdownMessage(endDate: endDate, hideBrand: true), () => _base);
    expect(find.text('Powered by Inngage'), findsNothing);
  });
}
