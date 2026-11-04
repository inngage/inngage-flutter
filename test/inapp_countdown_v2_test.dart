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

/// The payload the campaign editor really saves, as captured from the
/// `/objectMessage` response (see doc/TASK_FIX_INAPP_COUNTDOWN.md).
Map<String, dynamic> _editorCountdownJson({
  String endDate = '2099-11-04',
  String? endTime = '10:00',
}) =>
    {
      'type': 'Countdown',
      'style': {
        'position': 'center',
        'backgroundColor': '#e392fe',
        'backgroundImage': null,
        'borderColor': '#831100',
        'shadow': true,
        'titleColor': '#450e59',
        'bodyColor': '#450e59',
      },
      'countdown': {
        'content': {
          'title': 'É uma contagem regressiva',
          'body': 'TIC TOC, TIC TOC!! ',
        },
        'endDate': endDate,
        if (endTime != null) 'endTime': endTime,
        'style': {'textColor': '#f1c9fe', 'backgroundColor': '#61177c'},
      },
      'expiration': {'date': '', 'hours': '', 'minutes': ''},
      'title': 'É uma contagem regressiva',
      'body': 'TIC TOC, TIC TOC!! ',
      'notId': 'abc123',
    };

void main() {
  test('parses the payload saved by the campaign editor', () {
    final message = InAppMessageV2.fromResponse(_editorCountdownJson())!;

    expect(message.isCountdown, isTrue);
    expect(message.hasRenderableContent, isTrue);
    expect(message.notId, 'abc123');
    expect(message.content!.title, 'É uma contagem regressiva');
    expect(message.content!.body, 'TIC TOC, TIC TOC!! ');

    final countdown = message.countdown;
    expect(countdown.endDate, DateTime(2099, 11, 4, 10, 0));
    expect(countdown.boxColor, '#61177c');
    expect(countdown.digitColor, '#f1c9fe');
    expect(countdown.expiredTitle, '');
    expect(countdown.expiredBody, '');
    expect(message.buttons, isEmpty);
  });

  test('endDate + endTime are combined in local time', () {
    DateTime? parse(String endDate, String? endTime) => InAppMessageV2.fromJson(
            _editorCountdownJson(endDate: endDate, endTime: endTime))
        .countdown
        .endDate;

    expect(parse('2099-11-04', '10:30'), DateTime(2099, 11, 4, 10, 30));
    expect(parse('2099-11-04', '9:05'), DateTime(2099, 11, 4, 9, 5));
    expect(parse('2099-11-04', '23:59:30'), DateTime(2099, 11, 4, 23, 59, 30));
    expect(parse('2099-11-04', ' 08:15 '), DateTime(2099, 11, 4, 8, 15));
    // Missing or malformed endTime → local midnight of endDate.
    expect(parse('2099-11-04', null), DateTime(2099, 11, 4));
    expect(parse('2099-11-04', ''), DateTime(2099, 11, 4));
    expect(parse('2099-11-04', '10h30'), DateTime(2099, 11, 4));
    expect(parse('2099-11-04', '25:00'), DateTime(2099, 11, 4));
    // A joined endDate (original contract) wins over endTime.
    expect(parse('2099-11-04T17:28', '10:30'), DateTime(2099, 11, 4, 17, 28));
    expect(parse('2099-11-04T17:28', null), DateTime(2099, 11, 4, 17, 28));
    expect(parse('not-a-date', '10:30'), isNull);
    expect(parse('', '10:30'), isNull);
  });

  test('endTime of a non-string type is ignored', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'countdown': {'endDate': '2099-11-04', 'endTime': 1030},
    });
    expect(message.countdown.endDate, DateTime(2099, 11, 4));
  });

  test('countdown.style colors take precedence over boxColor/digitColor', () {
    InAppMessageV2 parse(Map<String, dynamic> countdown) =>
        InAppMessageV2.fromJson({'type': 'Countdown', 'countdown': countdown});

    final both = parse({
      'boxColor': '#111111',
      'digitColor': '#222222',
      'style': {'backgroundColor': '#aaaaaa', 'textColor': '#bbbbbb'},
    });
    expect(both.countdown.boxColor, '#aaaaaa');
    expect(both.countdown.digitColor, '#bbbbbb');

    final emptyStyle = parse({
      'boxColor': '#111111',
      'digitColor': '#222222',
      'style': {'backgroundColor': '', 'textColor': null},
    });
    expect(emptyStyle.countdown.boxColor, '#111111');
    expect(emptyStyle.countdown.digitColor, '#222222');

    final onlyStyle = parse({
      'style': {'backgroundColor': '#aaaaaa'},
    });
    expect(onlyStyle.countdown.boxColor, '#aaaaaa');
    expect(onlyStyle.countdown.digitColor, '#FFFFFF');

    expect(parse({'style': 'oops'}).countdown.boxColor, '#111827');
  });

  test('header content falls back to root content, then root title/body', () {
    final root = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'content': {'title': 'Root title', 'body': 'Root body'},
      'title': 'Flat title',
      'body': 'Flat body',
    });
    expect(root.content!.title, 'Root title');
    expect(root.content!.body, 'Root body');

    final flat = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'title': 'Flat title',
      'body': 'Flat body',
    });
    expect(flat.content!.title, 'Flat title');
    expect(flat.content!.body, 'Flat body');

    final nested = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'countdown': {
        'content': {'title': 'Nested title', 'body': ''},
      },
      'content': {'title': 'Root title', 'body': 'Root body'},
      'title': 'Flat title',
    });
    expect(nested.content!.title, 'Nested title');
    expect(nested.content!.body, '');

    final emptyNested = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'countdown': {
        'content': {'title': '', 'body': ''},
      },
      'title': 'Flat title',
    });
    expect(emptyNested.content!.title, 'Flat title');

    expect(InAppMessageV2.fromJson({'type': 'Countdown'}).content, isNull);
    expect(
      InAppMessageV2.fromJson({
        'type': 'Countdown',
        'content': <String, dynamic>{},
      }).content,
      isNotNull,
    );
  });

  test('the expiration object is ignored', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Countdown',
      'countdown': {'endDate': '2099-11-04', 'endTime': '10:00'},
      'expiration': {'date': '2026-10-19', 'hours': '20', 'minutes': '0'},
    });
    expect(message.countdown.endDate, DateTime(2099, 11, 4, 10, 0));
    expect(message.hasRenderableContent, isTrue);
  });

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
