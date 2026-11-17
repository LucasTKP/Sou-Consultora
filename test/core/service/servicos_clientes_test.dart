import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/service/servico_cep.dart';
import 'package:sou_consultora/core/service/servico_clientes.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

class _ApiFalsa implements ApiSupabase {
  bool semRede = false;
  String? funcaoChamada;
  Map<String, dynamic>? parametros;
  String? tabelaListada;
  String? ordem;

  @override
  Future<List<Map<String, dynamic>>> listar(
    String tabela, {
    String? ordenarPor,
    Map<String, Object> onde = const {},
  }) async {
    if (semRede) throw const SocketException('offline');
    tabelaListada = tabela;
    ordem = ordenarPor;
    return [
      {
        'id': 'c1',
        'nome': 'Ana',
        'whatsapp': '11987654321',
        'data_nascimento': null,
        'created_at': '2026-11-17T12:00:00Z',
        'qtd_compras': 0,
        'total_compras': 0,
        'ultima_compra': null,
        'saldo_devedor': 0,
        'valor_atrasado': 0,
        'valor_vence_hoje': 0,
      },
    ];
  }

  @override
  Future<dynamic> rpc(String funcao, {Map<String, dynamic>? parametros}) async {
    if (semRede) throw const SocketException('offline');
    funcaoChamada = funcao;
    this.parametros = parametros;
    return 'c9';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ServicoClientes', () {
    test('lista da view resumo_clientes ordenada por nome', () async {
      final api = _ApiFalsa();
      final resultado = await ServicoClientes(api: api).listarResumos();

      expect((resultado as Sucesso).valor.single.nome, 'Ana');
      expect(api.tabelaListada, 'resumo_clientes');
      expect(api.ordem, 'nome');
    });

    test('sem rede vira FalhaRede', () async {
      final resultado = await ServicoClientes(api: _ApiFalsa()..semRede = true)
          .listarResumos();
      expect((resultado as Erro).falha, isA<FalhaRede>());
    });

    test(
      'salvar chama a RPC sem consultora_id e com a data em aaaa-mm-dd',
      () async {
        final api = _ApiFalsa();
        final resultado = await ServicoClientes(api: api).salvar(
          id: null,
          nome: 'Ana',
          whatsapp: '11987654321',
          dataNascimento: DateTime(1990, 5, 3),
          observacoes: null,
          endereco: {'rua': 'R', 'numero': '1'},
        );

        expect((resultado as Sucesso).valor, 'c9');
        expect(api.funcaoChamada, 'salvar_cliente');
        expect(api.parametros!.keys, isNot(contains('p_consultora_id')));
        expect(
          api.parametros!.keys.any((chave) => chave.contains('consultora')),
          isFalse,
        );
        expect(api.parametros!['p_data_nascimento'], '1990-05-03');
        expect(api.parametros!['p_endereco'], {'rua': 'R', 'numero': '1'});
      },
    );
  });

  group('ServicoCepViaCep', () {
    test('CEP encontrado vira endereço', () async {
      Uri? chamado;
      final cliente = MockClient((requisicao) async {
        chamado = requisicao.url;
        return http.Response(
          '{"cep":"01001-000","logradouro":"Praça da Sé","complemento":"lado ímpar","bairro":"Sé","localidade":"São Paulo","uf":"SP"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final resultado = await ServicoCepViaCep(cliente: cliente)
          .buscar('01001-000');

      final endereco = (resultado as Sucesso<Endereco?>).valor!;
      expect(chamado.toString(), 'https://viacep.com.br/ws/01001000/json/');
      expect(endereco.rua, 'Praça da Sé');
      expect(endereco.cidade, 'São Paulo');
      expect(endereco.uf, 'SP');
      expect(
        endereco.complemento,
        isNull,
        reason: 'o complemento do ViaCEP é do logradouro, não da casa',
      );
    });

    test('{"erro": true} é CEP não encontrado', () async {
      final cliente = MockClient(
        (_) async => http.Response('{"erro": "true"}', 200),
      );
      final resultado = await ServicoCepViaCep(cliente: cliente)
          .buscar('99999999');
      expect((resultado as Sucesso<Endereco?>).valor, isNull);
    });

    test('tempo esgotado vira FalhaRede', () async {
      final cliente = MockClient((_) => Completer<http.Response>().future);
      final resultado = await ServicoCepViaCep(
        cliente: cliente,
        limite: const Duration(milliseconds: 10),
      ).buscar('01001000');
      expect((resultado as Erro).falha, isA<FalhaRede>());
    });

    test('CEP incompleto não chama a rede', () async {
      var chamadas = 0;
      final cliente = MockClient((_) async {
        chamadas++;
        return http.Response('{}', 200);
      });
      final resultado = await ServicoCepViaCep(cliente: cliente).buscar('0100');
      expect((resultado as Sucesso<Endereco?>).valor, isNull);
      expect(chamadas, 0);
    });
  });

  group('ServicoWhatsappNativo', () {
    test('link com +55 e só dígitos', () {
      expect(
        ServicoWhatsappNativo.linkDe('(11) 98765-4321').toString(),
        'https://wa.me/5511987654321',
      );
    });

    test('não conseguir abrir vira erro com a mensagem da spec', () async {
      final resultado = await ServicoWhatsappNativo(abrir: (_) async => false)
          .abrirConversa('11987654321');
      expect(
        (resultado as Erro).falha.mensagem,
        'Não foi possível abrir o WhatsApp',
      );
    });
  });
}
