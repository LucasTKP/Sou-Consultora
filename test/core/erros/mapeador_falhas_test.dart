import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const duplicado = PostgrestException(message: 'duplicate key', code: '23505');

  test('valor repetido vira FalhaValidacao com a mensagem informada', () {
    final falha = mapearFalha(
      duplicado,
      mensagemPadrao: 'padrão',
      mensagemDuplicado: 'Já existe um fornecedor com esse nome.',
    );

    expect(falha, isA<FalhaValidacao>());
    expect(falha.mensagem, 'Já existe um fornecedor com esse nome.');
  });

  test('valor repetido sem mensagem própria continua inesperado', () {
    final falha = mapearFalha(duplicado, mensagemPadrao: 'padrão');

    expect(falha, isA<FalhaInesperada>());
    expect(falha.mensagem, 'padrão');
  });

  test('outros erros do banco continuam inesperados', () {
    final falha = mapearFalha(
      const PostgrestException(message: 'check', code: '23514'),
      mensagemPadrao: 'padrão',
      mensagemDuplicado: 'repetido',
    );

    expect(falha, isA<FalhaInesperada>());
  });

  test('erro de negócio das funções (SC400) mostra a mensagem do banco', () {
    final falha = mapearFalha(
      const PostgrestException(
        message: 'Este lote já teve vendas e não pode ser apagado.',
        code: 'SC400',
      ),
      mensagemPadrao: 'padrão',
    );

    expect(falha, isA<FalhaValidacao>());
    expect(falha.mensagem, 'Este lote já teve vendas e não pode ser apagado.');
  });
}
