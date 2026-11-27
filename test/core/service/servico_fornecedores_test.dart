import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ApiFalsa implements ApiSupabase {
  bool semRede = false;
  bool duplicado = false;
  String? tabela;
  Map<String, dynamic>? dados;
  Object? idAtualizado;

  static const _linha = {
    'id': 'f1',
    'nome': 'Natura',
    'ramo': null,
    'contato': null,
    'telefone': null,
    'observacoes': null,
    'ativo': true,
    'created_at': '2026-11-17T12:00:00Z',
    'qtd_em_aberto': 0,
    'valor_em_aberto': 0,
    'qtd_atrasados': 0,
    'valor_atrasado': 0,
    'qtd_vence_hoje': 0,
    'qtd_pagos': 0,
    'valor_pagos': 0,
  };

  void _falhar() {
    if (semRede) throw const SocketException('offline');
    if (duplicado) {
      throw const PostgrestException(message: 'duplicate', code: '23505');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listar(
    String tabela, {
    String? ordenarPor,
    Map<String, Object> onde = const {},
  }) async {
    _falhar();
    this.tabela = tabela;
    return [_linha];
  }

  @override
  Future<Map<String, dynamic>> inserir(
    String tabela,
    Map<String, dynamic> dados,
  ) async {
    _falhar();
    this.tabela = tabela;
    this.dados = dados;
    return {'id': 'novo'};
  }

  @override
  Future<Map<String, dynamic>> atualizar(
    String tabela,
    Map<String, dynamic> dados, {
    required String coluna,
    required Object valor,
  }) async {
    _falhar();
    this.tabela = tabela;
    this.dados = dados;
    idAtualizado = valor;
    return {'id': valor};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ApiFalsa api;
  late ServicoFornecedores servico;

  setUp(() {
    api = _ApiFalsa();
    servico = ServicoFornecedores(api: api);
  });

  test('lista o resumo pela view', () async {
    final resultado = await servico.listarResumos();

    expect(api.tabela, 'resumo_fornecedores');
    expect((resultado as Sucesso).valor.single.nome, 'Natura');
  });

  test('sem rede vira FalhaRede', () async {
    api.semRede = true;

    final resultado = await servico.listarResumos();

    expect((resultado as Erro).falha, isA<FalhaRede>());
  });

  test(
    'criar envia só os campos editáveis, sem consultora_id/id/ativo',
    () async {
      final resultado = await servico.criar(
        Fornecedor(nome: 'Natura', telefone: '(11) 98765-4321'),
      );

      expect((resultado as Sucesso).valor, 'novo');
      expect(api.tabela, 'fornecedores');
      expect(api.dados, {
        'nome': 'Natura',
        'ramo': null,
        'contato': null,
        'telefone': '11987654321',
        'observacoes': null,
      });
    },
  );

  test('atualizar envia o status em espera', () async {
    await servico.atualizar('f1', Fornecedor(nome: 'Mary Kay', ativo: false));

    expect(api.idAtualizado, 'f1');
    expect(api.dados!['ativo'], isFalse);
    expect(api.dados!.containsKey('consultora_id'), isFalse);
  });

  test('nome repetido vira FalhaValidacao com mensagem clara', () async {
    api.duplicado = true;

    final resultado = await servico.criar(Fornecedor(nome: 'natura'));

    final falha = (resultado as Erro).falha;
    expect(falha, isA<FalhaValidacao>());
    expect(falha.mensagem, Fornecedor.mensagemDuplicado);
  });
}
