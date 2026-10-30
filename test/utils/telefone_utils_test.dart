import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/utils/telefone_utils.dart';

void main() {
  group('normalizarTelefone (RF001/RF002 - identificador de acesso)', () {
    test('mantém só os dígitos', () {
      expect(normalizarTelefone('(64) 99300-2156'), '64993002156');
    });

    test('remove o prefixo do país (+55)', () {
      expect(normalizarTelefone('+55 (64) 99300-2156'), '64993002156');
      expect(normalizarTelefone('5564993002156'), '64993002156');
    });

    test('remove o zero à esquerda do DDD', () {
      expect(normalizarTelefone('064993002156'), '64993002156');
    });

    test('não confunde o DDD 55 com o código do país', () {
      expect(normalizarTelefone('55999912345'), '55999912345');
    });

    test('formas diferentes de digitar o mesmo número geram a mesma conta', () {
      final formas = ['64993002156', '(64) 99300-2156', '+55 64 99300-2156', '0 64 99300 2156'];
      expect(formas.map(normalizarTelefone).toSet(), {'64993002156'});
    });
  });

  group('telefoneValido / validarTelefone', () {
    test('aceita celular com DDD (11 dígitos) e fixo (10 dígitos)', () {
      expect(telefoneValido('(64) 99300-2156'), isTrue);
      expect(telefoneValido('6436211234'), isTrue);
    });

    test('rejeita número sem DDD ou incompleto', () {
      expect(telefoneValido('993002156'), isFalse);
      expect(telefoneValido('6499300215'), isTrue); // 10 dígitos é fixo
      expect(telefoneValido('649930021'), isFalse);
    });

    test('rejeita celular de 11 dígitos que não começa com 9 depois do DDD', () {
      expect(telefoneValido('64 89300-2156'), isFalse);
    });

    test('rejeita DDD inexistente', () {
      expect(telefoneValido('00993002156'), isFalse);
      expect(telefoneValido('10993002156'), isFalse);
    });

    test('validarTelefone devolve as mensagens do formulário', () {
      expect(validarTelefone(''), 'Informe o número de telefone');
      expect(validarTelefone(null), 'Informe o número de telefone');
      expect(validarTelefone('123'), 'Informe o telefone com DDD, por exemplo (64) 99999-9999');
      expect(validarTelefone('(64) 99300-2156'), isNull);
    });
  });

  group('formatarTelefone e máscara de digitação', () {
    test('formata celular e fixo', () {
      expect(formatarTelefone('64993002156'), '(64) 99300-2156');
      expect(formatarTelefone('6436211234'), '(64) 3621-1234');
    });

    test('formata número incompleto enquanto a pessoa digita', () {
      expect(formatarTelefone('6'), '(6');
      expect(formatarTelefone('64'), '(64');
      expect(formatarTelefone('649'), '(64) 9');
      expect(formatarTelefone('649930'), '(64) 9930');
    });

    test('a máscara limita a 11 dígitos e ignora letras', () {
      final formatter = TelefoneInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '64a99300-2156999'),
      );
      expect(resultado.text, '(64) 99300-2156');
    });

    test('a tecla de apagar nunca fica presa nos separadores da máscara', () {
      final formatter = TelefoneInputFormatter();
      var texto = '(64) 99300-2156';
      // Simula a pessoa apagando um caractere por vez até esvaziar o campo.
      for (var i = 0; i < 20 && texto.isNotEmpty; i++) {
        final menor = texto.substring(0, texto.length - 1);
        texto = formatter
            .formatEditUpdate(
              TextEditingValue(text: texto),
              TextEditingValue(text: menor),
            )
            .text;
      }
      expect(texto, isEmpty);
    });

    test('a máscara aceita um número colado com +55', () {
      final formatter = TelefoneInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '+55 64 99300-2156'),
      );
      expect(resultado.text, '(64) 99300-2156');
    });
  });

  group('normalizarResposta (recuperação de senha)', () {
    test('ignora maiúsculas, acentos e espaços extras', () {
      expect(normalizarResposta('  Maria  da Conceição '), 'maria da conceicao');
      expect(normalizarResposta('MARIA DA CONCEICAO'), 'maria da conceicao');
    });

    test('respostas equivalentes geram o mesmo texto', () {
      expect(normalizarResposta('José Antônio'), normalizarResposta('jose antonio'));
    });
  });
}
