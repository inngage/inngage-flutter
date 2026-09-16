import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_card.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_carousel.dart';

InAppMessageV2 _message(int slides) {
  return InAppMessageV2.fromJson({
    'type': 'Banner',
    'style': {'backgroundColor': '#FFFFFF'},
    'media': {
      'enabled': true,
      'items': [
        for (var i = 1; i <= slides; i++)
          {
            'content': {'title': 'Slide $i', 'body': 'Corpo $i'},
            'actions': {
              'buttons': [
                {
                  'text': 'Botão $i',
                  'action': {'type': 'weblink', 'url': 'https://x.com/$i'},
                },
              ],
            },
          },
      ],
    },
  });
}

Future<void> _openCard(
  WidgetTester tester,
  InAppMessageV2 message,
  List<InAppV2Action> triggered, {
  List<String>? tracked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => InAppV2Card(
              message: message,
              onActionTriggered: triggered.add,
              onClickTracked: tracked?.add,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders a single slide as a banner (no carousel)',
      (tester) async {
    await _openCard(tester, _message(1), []);

    expect(find.text('Slide 1'), findsOneWidget);
    expect(find.text('Corpo 1'), findsOneWidget);
    expect(find.text('Botão 1'), findsOneWidget);
    expect(find.byType(InAppV2Carousel), findsNothing);
  });

  testWidgets('renders two or more slides as a carousel', (tester) async {
    await _openCard(tester, _message(2), []);

    expect(find.byType(InAppV2Carousel), findsOneWidget);
    expect(find.text('Slide 1'), findsOneWidget);
  });

  testWidgets('carousel height adapts to the current slide content',
      (tester) async {
    // Slide 1 is short (title only); slide 2 is tall (long body + button).
    final message = InAppMessageV2.fromJson({
      'type': 'Banner',
      'media': {
        'items': [
          {
            'content': {'title': 'Curto'}
          },
          {
            'content': {
              'title': 'Longo',
              'body': List.filled(30, 'linha de texto').join('\n'),
            },
            'actions': {
              'buttons': [
                {
                  'text': 'Comprar',
                  'action': {'type': 'dismiss'}
                }
              ],
            },
          },
        ],
      },
    });
    await _openCard(tester, message, []);
    await tester.pumpAndSettle();

    final pageView = find.byType(PageView);
    final shortHeight = tester.getSize(pageView).height;

    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Longo'), findsOneWidget);
    final tallHeight = tester.getSize(pageView).height;
    expect(tallHeight, greaterThan(shortHeight));
  });

  testWidgets('button tap closes the dialog and triggers its action',
      (tester) async {
    final triggered = <InAppV2Action>[];
    await _openCard(tester, _message(1), triggered);

    await tester.tap(find.text('Botão 1'));
    await tester.pumpAndSettle();

    expect(find.text('Slide 1'), findsNothing);
    expect(triggered, hasLength(1));
    expect(triggered.single.type, InAppV2ActionType.weblink);
    expect(triggered.single.url, 'https://x.com/1');
  });

  testWidgets('background click triggers the backgroundClick action',
      (tester) async {
    final triggered = <InAppV2Action>[];
    final message = InAppMessageV2.fromJson({
      'type': 'Banner',
      'media': {
        'items': [
          {
            'content': {'title': 'Toque em mim'},
            'actions': {
              'backgroundClick': {'type': 'deeplink', 'url': 'myapp://home'},
            },
          },
        ],
      },
    });
    await _openCard(tester, message, triggered);

    await tester.tap(find.text('Toque em mim'));
    await tester.pumpAndSettle();

    expect(find.text('Toque em mim'), findsNothing);
    expect(triggered.single.type, InAppV2ActionType.deepLink);
    expect(triggered.single.url, 'myapp://home');
  });

  testWidgets('tracks a single button click as "button"', (tester) async {
    final tracked = <String>[];
    await _openCard(tester, _message(1), [], tracked: tracked);

    await tester.tap(find.text('Botão 1'));
    await tester.pumpAndSettle();

    expect(tracked, ['button']);
  });

  testWidgets('tracks a background click as "card"', (tester) async {
    final tracked = <String>[];
    final message = InAppMessageV2.fromJson({
      'type': 'Banner',
      'media': {
        'items': [
          {
            'content': {'title': 'Toque em mim'},
            'actions': {
              'backgroundClick': {'type': 'dismiss'},
            },
          },
        ],
      },
    });
    await _openCard(tester, message, [], tracked: tracked);

    await tester.tap(find.text('Toque em mim'));
    await tester.pumpAndSettle();

    expect(tracked, ['card']);
  });

  testWidgets('tracks two buttons as "button_up" and "button_down"',
      (tester) async {
    InAppMessageV2 twoButtons() => InAppMessageV2.fromJson({
          'type': 'Banner',
          'media': {
            'items': [
              {
                'content': {'title': 'Escolha'},
                'actions': {
                  'buttons': [
                    {
                      'text': 'Primeiro',
                      'action': {'type': 'dismiss'}
                    },
                    {
                      'text': 'Segundo',
                      'action': {'type': 'dismiss'}
                    },
                  ],
                },
              },
            ],
          },
        });

    final tracked = <String>[];
    await _openCard(tester, twoButtons(), [], tracked: tracked);
    await tester.tap(find.text('Primeiro'));
    await tester.pumpAndSettle();
    expect(tracked, ['button_up']);

    tracked.clear();
    await _openCard(tester, twoButtons(), [], tracked: tracked);
    await tester.tap(find.text('Segundo'));
    await tester.pumpAndSettle();
    expect(tracked, ['button_down']);
  });
}
