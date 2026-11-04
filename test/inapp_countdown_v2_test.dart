import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';

Map<String, dynamic> _countdownJson({required String endDate}) => {
      'type': 'Countdown',
      'icon': 'https://storage.googleapis.com/inn-app-icons/380.png',
      'hideBrand': false,
      'style': {
        'position': 'center',
        'backgroundColor': '#ffffff',
        'backgroundImage': null,
        'borderColor': '#e5e7eb',
        'shadow': true,
        'titleColor': '#111827',
        'bodyColor': '#4B5563',
      },
      'content': {
        'title': 'A oferta termina em:',
        'body': 'Últimas horas com 30% OFF em todo o site.',
      },
      'countdown': {
        'endDate': endDate,
        'boxColor': '#111827',
        'digitColor': '#FFFFFF',
        'expiredTitle': 'Oferta encerrada',
        'expiredBody': 'Fique de olho nas próximas!',
      },
      'buttons': [
        {
          'text': 'Aproveitar agora',
          'style': {
            'backgroundColor': '#7C3AED',
            'textColor': '#FFFFFF',
            'hoverColor': '#6D28D9',
          },
          'action': {'type': 'weblink', 'url': 'https://', 'target': '_blank'},
        },
      ],
      'targeting': {
        'allowedPages': [],
        'excludedPages': [],
        'rules': {'deviceType': 'both'},
      },
    };

void main() {
  test('parses the full Countdown contract JSON', () {
    final message = InAppMessageV2.fromResponse(
        _countdownJson(endDate: '2099-09-15T17:28'))!;

    expect(message.isCountdown, isTrue);
    expect(message.isWheel, isFalse);
    expect(message.hasRenderableContent, isTrue);
    expect(message.content!.title, 'A oferta termina em:');

    final countdown = message.countdown;
    expect(countdown.endDate, DateTime(2099, 9, 15, 17, 28));
    expect(countdown.boxColor, '#111827');
    expect(countdown.digitColor, '#FFFFFF');
    expect(countdown.expiredTitle, 'Oferta encerrada');
    expect(countdown.expiredBody, 'Fique de olho nas próximas!');

    final button = message.buttons.single;
    expect(button.text, 'Aproveitar agora');
    expect(button.style.backgroundColor, '#7C3AED');
    expect(button.action!.type, InAppV2ActionType.weblink);
    expect(button.action!.url, 'https://');
  });

  test('isCountdown is case-insensitive', () {
    expect(InAppMessageV2.fromJson({'type': 'countdown'}).isCountdown, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'COUNTDOWN'}).isCountdown, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'Banner'}).isCountdown, isFalse);
  });

  test('an already-expired campaign is not renderable', () {
    final message = InAppMessageV2.fromResponse(
        _countdownJson(endDate: '2020-01-01T00:00'));
    expect(message!.hasRenderableContent, isFalse);
  });

  test('missing or unparseable endDate is not renderable', () {
    expect(
      InAppMessageV2.fromJson({'type': 'Countdown'}).hasRenderableContent,
      isFalse,
    );
    expect(
      InAppMessageV2.fromJson({
        'type': 'Countdown',
        'countdown': {'endDate': 'not-a-date'},
      }).hasRenderableContent,
      isFalse,
    );
  });

  test('applies defaults for absent Countdown fields', () {
    final message = InAppMessageV2.fromJson({'type': 'Countdown'});

    expect(message.countdown.endDate, isNull);
    expect(message.countdown.boxColor, '#111827');
    expect(message.countdown.digitColor, '#FFFFFF');
    expect(message.countdown.expiredTitle, '');
    expect(message.countdown.expiredBody, '');
    expect(message.buttons, isEmpty);
  });
}
