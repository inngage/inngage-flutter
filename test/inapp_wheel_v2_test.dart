import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';

const _wheelJson = {
  'type': 'Wheel',
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
    'title': 'Gire a roleta da sorte',
    'body': 'Um giro por visita. Boa sorte!',
  },
  'leadCapture': {
    'enabled': true,
    'position': 'before',
    'fields': [
      {'type': 'email', 'label': 'Seu e-mail'}
    ],
    'button': {
      'text': 'Liberar meu giro',
      'style': {
        'backgroundColor': '#7C3AED',
        'textColor': '#FFFFFF',
        'hoverColor': '#6D28D9',
      },
    },
    'consentText': 'Ao continuar você concorda com nossos Termos & Condições.',
    'consentColor': '#9CA3AF',
    'unlockText': 'Cadastre-se para liberar seu cupom 🎁',
  },
  'wheel': {
    'buttonText': 'Girar 🎡',
    'button': {'backgroundColor': '#7C3AED', 'textColor': '#FFFFFF'},
    'slices': [
      {'label': '10% OFF', 'color': '#7C3AED', 'code': 'GIRO10', 'weight': 3},
      {
        'label': 'Frete grátis',
        'color': '#F59E0B',
        'code': 'FRETE0',
        'weight': 2
      },
      {'label': 'Quase!', 'color': '#9CA3AF', 'code': null, 'weight': 4},
      {'label': '25% OFF', 'color': '#10B981', 'code': 'GIRO25', 'weight': 1},
    ],
  },
  'result': {
    'winTitle': 'Parabéns! 🎉',
    'loseTitle': 'Foi por pouco!',
    'body': 'Apresente o cupom no checkout.',
    'winEmoji': '🎁',
    'loseEmoji': '🙂',
    'style': {
      'gradient': false,
      'bgFrom': '#FFFFFF',
      'bgTo': '#F5F3FF',
      'textColor': '#111827',
    },
  },
  'targeting': {
    'allowedPages': [],
    'excludedPages': [],
    'rules': {'deviceType': 'both'},
  },
};

void main() {
  test('parses the full Wheel contract JSON', () {
    final message = InAppMessageV2.fromResponse(Map.of(_wheelJson))!;

    expect(message.isWheel, isTrue);
    expect(message.hasRenderableContent, isTrue);
    expect(
        message.icon, 'https://storage.googleapis.com/inn-app-icons/380.png');
    expect(message.hideBrand, isFalse);
    expect(message.content!.title, 'Gire a roleta da sorte');
    expect(message.content!.body, 'Um giro por visita. Boa sorte!');

    final lead = message.leadCapture;
    expect(lead.enabled, isTrue);
    expect(lead.capturesBeforeSpin, isTrue);
    expect(lead.fields.single.type, 'email');
    expect(lead.fields.single.label, 'Seu e-mail');
    expect(lead.buttonText, 'Liberar meu giro');
    expect(lead.buttonStyle.backgroundColor, '#7C3AED');
    expect(lead.consentColor, '#9CA3AF');
    expect(lead.unlockText, 'Cadastre-se para liberar seu cupom 🎁');

    final wheel = message.wheel;
    expect(wheel.buttonText, 'Girar 🎡');
    expect(wheel.buttonStyle.backgroundColor, '#7C3AED');
    expect(wheel.buttonStyle.textColor, '#FFFFFF');
    expect(wheel.slices, hasLength(4));
    expect(wheel.slices[0].code, 'GIRO10');
    expect(wheel.slices[0].isWin, isTrue);
    expect(wheel.slices[2].code, isNull);
    expect(wheel.slices[2].isWin, isFalse);
    expect(wheel.slices[2].weight, 4);

    final result = message.result;
    expect(result.winTitle, 'Parabéns! 🎉');
    expect(result.loseTitle, 'Foi por pouco!');
    expect(result.winEmoji, '🎁');
    expect(result.style.gradient, isFalse);
    expect(result.style.bgFrom, '#FFFFFF');
    expect(result.style.textColor, '#111827');
  });

  test('isWheel is case-insensitive', () {
    expect(InAppMessageV2.fromJson({'type': 'wheel'}).isWheel, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'WHEEL'}).isWheel, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'Banner'}).isWheel, isFalse);
  });

  test('Wheel without slices is not renderable', () {
    final message = InAppMessageV2.fromJson({'type': 'Wheel'});
    expect(message.hasRenderableContent, isFalse);
  });

  test('Wheel with slices is renderable even without media', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Wheel',
      'wheel': {
        'slices': [
          {'label': 'X', 'weight': 1}
        ]
      },
    });
    expect(message.hasRenderableContent, isTrue);
  });

  test('applies defaults for absent Wheel fields', () {
    final message = InAppMessageV2.fromJson({'type': 'Wheel'});

    expect(message.icon, '');
    expect(message.hideBrand, isFalse);
    expect(message.content, isNull);
    expect(message.leadCapture.enabled, isFalse);
    expect(message.leadCapture.capturesBeforeSpin, isTrue);
    expect(message.wheel.buttonText, 'Girar');
    expect(message.wheel.slices, isEmpty);
    expect(message.result.winTitle, '');
    expect(message.result.style.gradient, isFalse);
  });

  test('slice weight tolerates string values and defaults to 1', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Wheel',
      'wheel': {
        'slices': [
          {'label': 'A', 'weight': '5'},
          {'label': 'B'},
        ]
      },
    });
    expect(message.wheel.slices[0].weight, 5);
    expect(message.wheel.slices[1].weight, 1);
  });

  test('leadCapture position after disables capturesBeforeSpin', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Wheel',
      'leadCapture': {'enabled': true, 'position': 'after'},
    });
    expect(message.leadCapture.capturesBeforeSpin, isFalse);
  });
}
