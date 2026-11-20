import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';

String _digitar(TextInputFormatter mascara, String texto) => mascara
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto))
    .text;

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('moeda', () {
    test('formata centavos', () {
      expect(FormatadorMoeda.formatar(123456), r'R$ 1.234,56');
      expect(FormatadorMoeda.formatar(0), r'R$ 0,00');
      expect(FormatadorMoeda.formatarSemSimbolo(84250), '842,50');
    });

    test('ida e volta sem perder centavos', () {
      for (final centavos in [0, 1, 99, 100, 21990, 5482000]) {
        expect(
          FormatadorMoeda.ler(FormatadorMoeda.formatar(centavos)),
          centavos,
        );
      }
    });

    test('máscara digita da direita para a esquerda', () {
      final mascara = MascaraMoeda();
      expect(_digitar(mascara, '1'), '0,01');
      expect(_digitar(mascara, '123'), '1,23');
      expect(_digitar(mascara, '1234567'), '12.345,67');
    });
  });

  group('data', () {
    final data = DateTime(2024, 10, 15);

    test('curta, por extenso e mês/ano', () {
      expect(FormatadorData.curta(data), '15/10/2024');
      expect(FormatadorData.porExtenso(data), '15 de outubro de 2024');
      expect(FormatadorData.mesAno(DateTime(2024, 11)), 'novembro de 2024');
    });

    test('relativo', () {
      final hoje = DateTime(2024, 11, 2, 18, 30);
      expect(
        FormatadorData.relativo(DateTime(2024, 11, 2), hoje: hoje),
        'hoje',
      );
      expect(
        FormatadorData.relativo(DateTime(2024, 11, 1), hoje: hoje),
        'ontem',
      );
      expect(
        FormatadorData.relativo(DateTime(2024, 11, 3), hoje: hoje),
        'amanhã',
      );
      expect(FormatadorData.relativo(data, hoje: hoje), 'há 18 dias');
      expect(
        FormatadorData.relativo(DateTime(2024, 11, 5), hoje: hoje),
        'em 3 dias',
      );
    });

    test('ler valida a data', () {
      expect(FormatadorData.ler('15/05/2024'), DateTime(2024, 5, 15));
      expect(FormatadorData.ler('31/02/2024'), isNull);
      expect(FormatadorData.ler('15/05'), isNull);
    });

    test('máscara', () {
      expect(_digitar(MascaraData(), '1'), '1');
      expect(_digitar(MascaraData(), '1505'), '15/05');
      expect(_digitar(MascaraData(), '150520241'), '15/05/2024');
    });
  });

  group('telefone', () {
    test('celular e fixo', () {
      expect(FormatadorTelefone.formatar('11987654321'), '(11) 98765-4321');
      expect(FormatadorTelefone.formatar('1134567890'), '(11) 3456-7890');
    });

    test('parcial enquanto digita', () {
      expect(_digitar(MascaraTelefone(), '1'), '(1');
      expect(_digitar(MascaraTelefone(), '11987'), '(11) 987');
      expect(_digitar(MascaraTelefone(), '119876543210'), '(11) 98765-4321');
    });

    test('validação', () {
      expect(FormatadorTelefone.valido('(11) 98765-4321'), isTrue);
      expect(FormatadorTelefone.valido('(11) 9876'), isFalse);
    });
  });

  group('cpf', () {
    test('máscara formata enquanto digita', () {
      expect(_digitar(MascaraCpf(), '123'), '123');
      expect(_digitar(MascaraCpf(), '1234'), '123.4');
      expect(_digitar(MascaraCpf(), '1234567'), '123.456.7');
      expect(_digitar(MascaraCpf(), '1234567890'), '123.456.789-0');
      expect(_digitar(MascaraCpf(), '12345678909'), '123.456.789-09');
    });

    test('ignora o que não é dígito e corta no 11º', () {
      expect(_digitar(MascaraCpf(), '123.456.789-09'), '123.456.789-09');
      expect(_digitar(MascaraCpf(), '123456789012345'), '123.456.789-01');
    });
  });
}
