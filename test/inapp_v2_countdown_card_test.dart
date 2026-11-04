import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_countdown_card.dart';

final _base = DateTime(2026, 9, 14, 12, 0, 0);

InAppMessageV2 _countdownMessage({
  required DateTime endDate,
  bool withExpiredTexts = true,
}) {
  return InAppMessageV2.fromJson({
    'type': 'Countdown',
    'content': {'title': 'A oferta termina em:', 'body': '30% OFF.'},
    'countdown': {
      'endDate': endDate.toIso8601String(),
      'boxColor': '#111827',
      'digitColor': '#FFFFFF',
      if (withExpiredTexts) 'expiredTitle': 'Oferta encerrada',
      if (withExpiredTexts) 'expiredBody': 'Fique de olho nas próximas!',
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

String _two(int value) => value.toString().padLeft(2, '0');

/// The editor format: content nested under `countdown`, deadline split into
/// endDate + endTime, box colors under `countdown.style`, no expired texts.
InAppMessageV2 _editorCountdownMessage({required DateTime endDate}) {
  return InAppMessageV2.fromJson({
    'type': 'Countdown',
    'style': {'titleColor': '#450e59', 'bodyColor': '#450e59'},
    'countdown': {
      'content': {
        'title': 'É uma contagem regressiva',
        'body': 'TIC TOC, TIC TOC!!',
      },
      'endDate': '${endDate.year}-${_two(endDate.month)}-${_two(endDate.day)}',
      'endTime': '${_two(endDate.hour)}:${_two(endDate.minute)}',
      'style': {'textColor': '#f1c9fe', 'backgroundColor': '#61177c'},
    },
    'expiration': {'date': '', 'hours': '', 'minutes': ''},
    'title': 'É uma contagem regressiva',
    'body': 'TIC TOC, TIC TOC!!',
    'buttons': [
      {
        'text': 'Aproveitar agora',
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

  testWidgets('never renders the "Powered by Inngage" footer', (tester) async {
    final endDate = _base.add(const Duration(hours: 1));
    await _openCountdown(
        tester, _countdownMessage(endDate: endDate), () => _base);
    expect(find.text('Powered by Inngage'), findsNothing);
  });

  testWidgets('renders title, body and box colors from the editor payload',
      (tester) async {
    // 10:30 on the next day → 22 h 30 min ahead of _base (12:00).
    final endDate = DateTime(_base.year, _base.month, _base.day + 1, 10, 30);
    await _openCountdown(
        tester, _editorCountdownMessage(endDate: endDate), () => _base);

    expect(find.text('É uma contagem regressiva'), findsOneWidget);
    expect(find.text('TIC TOC, TIC TOC!!'), findsOneWidget);
    expect(find.text('Aproveitar agora'), findsOneWidget);
    expect(find.text('00'), findsNWidgets(2)); // DIAS and SEG
    expect(find.text('22'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);

    final box = tester.widget<Container>(find.ancestor(
      of: find.text('DIAS'),
      matching: find.byType(Container),
    ));
    expect((box.decoration as BoxDecoration).color, const Color(0xFF61177C));
    final digits = tester.widget<Text>(find.text('22'));
    expect(digits.style!.color, const Color(0xFFF1C9FE));
  });

  testWidgets(
      'without expired texts, reaching the deadline keeps the header and '
      'hides boxes and buttons', (tester) async {
    var fakeNow = _base;
    final endDate = _base.add(const Duration(seconds: 2));
    await _openCountdown(
        tester,
        _countdownMessage(endDate: endDate, withExpiredTexts: false),
        () => fakeNow);

    expect(find.text('A oferta termina em:'), findsOneWidget);
    expect(find.text('SEG'), findsOneWidget);

    fakeNow = fakeNow.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('A oferta termina em:'), findsOneWidget);
    expect(find.text('30% OFF.'), findsOneWidget);
    expect(find.text('SEG'), findsNothing);
    expect(find.text('Aproveitar agora'), findsNothing);
    expect(find.text('Oferta encerrada'), findsNothing);
  });
}
