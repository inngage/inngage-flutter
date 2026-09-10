import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_card.dart';

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
  List<InAppV2Action> triggered,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => InAppV2Card(
              message: message,
              onActionTriggered: triggered.add,
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
    expect(find.byType(ImageSlideshow), findsNothing);
  });

  testWidgets('renders two or more slides as a carousel', (tester) async {
    await _openCard(tester, _message(2), []);

    expect(find.byType(ImageSlideshow), findsOneWidget);
    expect(find.text('Slide 1'), findsOneWidget);
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
}
