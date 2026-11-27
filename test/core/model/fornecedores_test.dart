import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/resumo_fornecedor_dto.dart';
import 'package:sou_consultora/core/model/filtro_fornecedores.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

ResumoFornecedor _resumo(
  String nome, {
  bool ativo = true,
  int qtdEmAberto = 0,
  int qtdVenceHoje = 0,
}) => ResumoFornecedor(
  id: nome,
  nome: nome,
  criadoEm: DateTime(2023, 3, 1),
  ativo: ativo,
  qtdEmAberto: qtdEmAberto,
  qtdVenceHoje: qtdVenceHoje,
);

void main() {
  group('Fornecedor', () {
    test('nome vazio é recusado', () {
      expect(Fornecedor.validarNome('   '), 'Informe o nome do fornecedor');
      expect(Fornecedor.validarNome('Natura'), isNull);
    });

    test('telefone vazio é aceito; incompleto é recusado', () {
      expect(Fornecedor.validarTelefone(''), isNull);
      expect(Fornecedor.validarTelefone('(11) 9876'), 'Telefone incompleto');
      expect(Fornecedor.validarTelefone('(11) 98765-4321'), isNull);
    });

    test('normaliza para gravar: vazios viram null e telefone só dígitos', () {
      final fornecedor = Fornecedor(
        nome: '  Natura ',
        ramo: ' ',
        contato: '',
        telefone: '(11) 98765-4321',
        observacoes: '  Ciclo às terças ',
      );

      expect(fornecedor.nome, 'Natura');
      expect(fornecedor.ramo, isNull);
      expect(fornecedor.contato, isNull);
      expect(fornecedor.telefone, '11987654321');
      expect(fornecedor.observacoes, 'Ciclo às terças');
      expect(fornecedor.ativo, isTrue);
      expect(Fornecedor(nome: 'X', telefone: '').telefone, isNull);
    });
  });

  group('ResumoFornecedor', () {
    test('status: vence hoje > em espera > ativo', () {
      expect(
        _resumo('A', ativo: false, qtdVenceHoje: 1).status,
        StatusFornecedor.venceHoje,
      );
      expect(_resumo('A', qtdVenceHoje: 1).status, StatusFornecedor.venceHoje);
      expect(_resumo('A', ativo: false).status, StatusFornecedor.emEspera);
      expect(_resumo('A').status, StatusFornecedor.ativo);
    });

    test('iniciais da marca', () {
      expect(ResumoFornecedor.iniciaisDe('Natura'), 'NAT');
      expect(ResumoFornecedor.iniciaisDe('O Boticário'), 'OB');
      expect(ResumoFornecedor.iniciaisDe('Avon / Eudora'), 'AE');
      expect(ResumoFornecedor.iniciaisDe('MK'), 'MK');
      expect(
        ResumoFornecedor.iniciaisDe('Jequiti Cosméticos do Brasil'),
        'JCD',
      );
      expect(ResumoFornecedor.iniciaisDe('  '), '?');
    });

    test('texto de boletos em aberto no singular e no plural', () {
      expect(_resumo('A').textoBoletosEmAberto, 'Nenhum boleto em aberto');
      expect(
        _resumo('A', qtdEmAberto: 1).textoBoletosEmAberto,
        '1 boleto em aberto',
      );
      expect(
        _resumo('A', qtdEmAberto: 2).textoBoletosEmAberto,
        '2 boletos em aberto',
      );
    });
  });

  group('FiltroFornecedores', () {
    final lista = [
      _resumo('Natura'),
      _resumo('O Boticário', qtdVenceHoje: 1),
      _resumo('Mary Kay', ativo: false),
      _resumo('Avon', ativo: false, qtdVenceHoje: 1),
    ];

    List<String> nomes(
      StatusFiltroFornecedor status, {
      String busca = '',
      OrdemNome ordem = OrdemNome.aZ,
    }) => FiltroFornecedores.aplicar(
      lista,
      status: status,
      busca: busca,
      ordem: ordem,
    ).map((f) => f.nome).toList();

    test('busca sem acento', () {
      expect(nomes(StatusFiltroFornecedor.todos, busca: 'boticario'), [
        'O Boticário',
      ]);
    });

    test('vence hoje inclui quem está em espera', () {
      expect(nomes(StatusFiltroFornecedor.venceHoje), ['Avon', 'O Boticário']);
    });

    test('ativos e em espera', () {
      expect(nomes(StatusFiltroFornecedor.ativos), ['Natura', 'O Boticário']);
      expect(nomes(StatusFiltroFornecedor.emEspera), ['Avon', 'Mary Kay']);
    });

    test('ordem A-Z e Z-A', () {
      expect(nomes(StatusFiltroFornecedor.todos), [
        'Avon',
        'Mary Kay',
        'Natura',
        'O Boticário',
      ]);
      expect(
        nomes(StatusFiltroFornecedor.todos, ordem: OrdemNome.zA).first,
        'O Boticário',
      );
    });

    test('contagens por status', () {
      expect(FiltroFornecedores.contagens(lista), {
        StatusFiltroFornecedor.todos: 4,
        StatusFiltroFornecedor.ativos: 2,
        StatusFiltroFornecedor.emEspera: 2,
        StatusFiltroFornecedor.venceHoje: 2,
      });
    });
  });

  group('ResumoFornecedorDto', () {
    test('converte a linha da view (numeric como int, double ou texto)', () {
      final modelo = ResumoFornecedorDto.fromJson({
        'id': 'f1',
        'nome': 'Natura',
        'ramo': 'Cosméticos',
        'contato': null,
        'telefone': '11987654321',
        'observacoes': null,
        'ativo': false,
        'created_at': '2023-03-10T12:00:00+00:00',
        'qtd_em_aberto': 3,
        'valor_em_aberto': '220.00',
        'qtd_atrasados': 1,
        'valor_atrasado': 100,
        'qtd_vence_hoje': 1,
        'qtd_pagos': 1,
        'valor_pagos': 200.5,
      }).paraModel();

      expect(modelo.nome, 'Natura');
      expect(modelo.ramo, 'Cosméticos');
      expect(modelo.emEspera, isTrue);
      expect(modelo.criadoEm.year, 2023);
      expect(modelo.valorEmAberto, 22000);
      expect(modelo.valorAtrasado, 10000);
      expect(modelo.valorPagos, 20050);
      expect(modelo.qtdVenceHoje, 1);
    });
  });
}
