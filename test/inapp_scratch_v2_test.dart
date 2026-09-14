import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';

const _scratchJson = {
  'type': 'Scratch',
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
    'title': 'Raspe e ganhe!',
    'body': 'Descubra seu prêmio secreto.',
  },
  'leadCapture': {
    'enabled': true,
    'position': 'before',
    'fields': [
      {'type': 'email', 'label': 'Seu e-mail'}
    ],
    'button': {
      'text': 'Continuar',
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
  'scratch': {
    'coverColor': '#9CA3AF',
    'instruction': 'Raspe aqui ✨',
    'revealPercent': 55,
    'prizes': [
      {'label': '15% OFF', 'code': 'RASPA15', 'weight': 3},
      {'label': 'Frete grátis', 'code': 'FRETERASPA', 'weight': 2},
      {'label': 'Quase!', 'code': null, 'weight': 5},
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
  'targeting': {
    'allowedPages': [],
    'excludedPages': [],
    'rules': {'deviceType': 'both'},
  },
};

void main() {
  test('parses the full Scratch contract JSON', () {
    final message = InAppMessageV2.fromResponse(Map.of(_scratchJson))!;

    expect(message.isScratch, isTrue);
    expect(message.isWheel, isFalse);
    expect(message.hasRenderableContent, isTrue);
    expect(message.content!.title, 'Raspe e ganhe!');

    final scratch = message.scratch;
    expect(scratch.coverColor, '#9CA3AF');
    expect(scratch.instruction, 'Raspe aqui ✨');
    expect(scratch.revealPercent, 55);
    expect(scratch.prizes, hasLength(3));
    expect(scratch.prizes[0].code, 'RASPA15');
    expect(scratch.prizes[0].isWin, isTrue);
    expect(scratch.prizes[2].code, isNull);
    expect(scratch.prizes[2].isWin, isFalse);
    expect(scratch.prizes[2].weight, 5);

    final lead = message.leadCapture;
    expect(lead.enabled, isTrue);
    expect(lead.buttonText, 'Continuar');

    final result = message.result;
    expect(result.winTitle, 'Você ganhou');
    expect(result.style.gradient, isTrue);
    expect(result.style.bgFrom, '#FEF3C7');
    expect(result.style.bgTo, '#FDE68A');
  });

  test('isScratch is case-insensitive', () {
    expect(InAppMessageV2.fromJson({'type': 'scratch'}).isScratch, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'SCRATCH'}).isScratch, isTrue);
    expect(InAppMessageV2.fromJson({'type': 'Wheel'}).isScratch, isFalse);
  });

  test('Scratch without prizes is not renderable', () {
    expect(
      InAppMessageV2.fromJson({'type': 'Scratch'}).hasRenderableContent,
      isFalse,
    );
  });

  test('Scratch with prizes is renderable even without media', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Scratch',
      'scratch': {
        'prizes': [
          {'label': 'X'}
        ]
      },
    });
    expect(message.hasRenderableContent, isTrue);
  });

  test('applies defaults for absent Scratch fields', () {
    final message = InAppMessageV2.fromJson({'type': 'Scratch'});

    expect(message.scratch.coverColor, '#9CA3AF');
    expect(message.scratch.instruction, '');
    expect(message.scratch.revealPercent, 50);
    expect(message.scratch.prizes, isEmpty);
  });

  test('revealPercent tolerates strings and clamps to 1-100', () {
    InAppMessageV2 parse(dynamic percent) => InAppMessageV2.fromJson({
          'type': 'Scratch',
          'scratch': {'revealPercent': percent},
        });

    expect(parse('70').scratch.revealPercent, 70);
    expect(parse(0).scratch.revealPercent, 1);
    expect(parse(250).scratch.revealPercent, 100);
    expect(parse('abc').scratch.revealPercent, 50);
  });

  test('prize weight tolerates string values and defaults to 1', () {
    final message = InAppMessageV2.fromJson({
      'type': 'Scratch',
      'scratch': {
        'prizes': [
          {'label': 'A', 'weight': '7'},
          {'label': 'B'},
        ]
      },
    });
    expect(message.scratch.prizes[0].weight, 7);
    expect(message.scratch.prizes[1].weight, 1);
  });
}
