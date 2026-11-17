import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/cliente_dto.dart';
import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/dto/resumo_cliente_dto.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/model/filtro_clientes.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

final _hoje = DateTime(2026, 11, 17, 15);

ResumoCliente _resumo(
  String nome, {
  int atrasado = 0,
  int venceHoje = 0,
  int saldo = 0,
  DateTime? nascimento,
}) {
  return ResumoCliente(
    id: nome,
    nome: nome,
    whatsapp: '11987654321',
    criadaEm: DateTime(2025),
    dataNascimento: nascimento,
    saldoDevedor: saldo,
    valorAtrasado: atrasado,
    valorVenceHoje: venceHoje,
  );
}

void main() {
  group('Endereco', () {
    test('vazio é válido e não é gravado', () {
      const endereco = Endereco(rua: '  ', numero: '');
      expect(endereco.vazio, isTrue);
      expect(endereco.validar(), (rua: null, numero: null, cep: null));
      expect(endereco.paraGravar(), isNull);
    });

    test('só bairro exige rua e número', () {
      final erros = const Endereco(bairro: 'Centro').validar();
      expect(erros.rua, 'Obrigatório');
      expect(erros.numero, 'Obrigatório');
    });

    test('CEP incompleto é inválido; gravado só com dígitos', () {
      expect(
        const Endereco(cep: '0100', rua: 'R', numero: '1').validar().cep,
        'CEP inválido',
      );
      expect(
        const Endereco(
          cep: '01001-000',
          rua: 'R',
          numero: '1',
        ).paraGravar()!['cep'],
        '01001000',
      );
    });

    test('linhas de exibição', () {
      const endereco = Endereco(
        rua: 'Rua das Acácias',
        numero: '450',
        complemento: 'Apto 82',
        bairro: 'Jd. Paulista',
        uf: 'SP',
      );
      expect(endereco.linhaRua, 'Rua das Acácias, 450 - Apto 82');
      expect(endereco.linhaBairroCidade, 'Jd. Paulista - SP');
      expect(
        const Endereco(cidade: 'São Paulo').linhaBairroCidade,
        'São Paulo',
      );
      expect(const Endereco(cep: '01001000').linhaRua, isNull);
    });
  });

  group('Cliente', () {
    test('validações', () {
      expect(Cliente.validarNome('  '), 'Informe o nome');
      expect(Cliente.validarWhatsapp(''), 'Informe o WhatsApp');
      expect(Cliente.validarWhatsapp('1199'), 'WhatsApp inválido');
      expect(Cliente.validarWhatsapp('(11) 98765-4321'), isNull);
    });

    test('nascimento: vazio ok, inexistente e futuro inválidos, hoje ok', () {
      expect(Cliente.validarNascimento('', null, hoje: _hoje), isNull);
      expect(
        Cliente.validarNascimento('31/02/1990', null, hoje: _hoje),
        'Data inválida',
      );
      expect(
        Cliente.validarNascimento(
          '18/11/2026',
          DateTime(2026, 11, 18),
          hoje: _hoje,
        ),
        'Data inválida',
      );
      expect(
        Cliente.validarNascimento(
          '17/11/2026',
          DateTime(2026, 11, 17),
          hoje: _hoje,
        ),
        isNull,
      );
    });

    test('iniciais', () {
      expect(Cliente.iniciaisDe('Mariana Souza'), 'MS');
      expect(Cliente.iniciaisDe(' juliana '), 'J');
      expect(Cliente.iniciaisDe(''), '?');
    });
  });

  group('Situação da cliente', () {
    test('prioridade: atrasada > vence hoje > aniversário > em dia', () {
      final aniversario = DateTime(1990, 11, 3);
      expect(
        _resumo(
          'a',
          atrasado: 1,
          venceHoje: 1,
          nascimento: aniversario,
        ).situacao(_hoje),
        SituacaoCliente.atrasada,
      );
      expect(
        _resumo('b', venceHoje: 1, nascimento: aniversario).situacao(_hoje),
        SituacaoCliente.venceHoje,
      );
      expect(
        _resumo('c', nascimento: aniversario).situacao(_hoje),
        SituacaoCliente.aniversario,
      );
      expect(
        _resumo('d', saldo: 500, nascimento: DateTime(1990, 5)).situacao(_hoje),
        SituacaoCliente.emDia,
      );
    });
  });

  group('FiltroClientes', () {
    final lista = [
      _resumo('Patrícia Ribeiro'),
      _resumo('ana Lima', saldo: 100, atrasado: 100),
      _resumo('Beatriz', saldo: 85, venceHoje: 85),
      _resumo('Juliana', nascimento: DateTime(1995, 11, 20)),
    ];

    List<String> nomes(
      StatusFiltroCliente status, {
      String busca = '',
      OrdemNome ordem = OrdemNome.aZ,
    }) {
      return FiltroClientes.aplicar(
        lista,
        status: status,
        busca: busca,
        ordem: ordem,
        hoje: _hoje,
      ).map((c) => c.nome).toList();
    }

    test('busca sem acento nem maiúsculas', () {
      expect(nomes(StatusFiltroCliente.todos, busca: 'patricia'), [
        'Patrícia Ribeiro',
      ]);
      expect(TextoBusca.normalizar(' Ação  Já '), 'acao ja');
    });

    test('ordem A-Z ignora maiúsculas; Z-A inverte', () {
      expect(nomes(StatusFiltroCliente.todos), [
        'ana Lima',
        'Beatriz',
        'Juliana',
        'Patrícia Ribeiro',
      ]);
      expect(
        nomes(StatusFiltroCliente.todos, ordem: OrdemNome.zA).first,
        'Patrícia Ribeiro',
      );
      expect(OrdemNome.aZ.inversa, OrdemNome.zA);
    });

    test('filtros e contagens', () {
      expect(nomes(StatusFiltroCliente.comSaldo), ['ana Lima', 'Beatriz']);
      expect(nomes(StatusFiltroCliente.emDia), [
        'Beatriz',
        'Juliana',
        'Patrícia Ribeiro',
      ]);
      expect(nomes(StatusFiltroCliente.aniversariantes), ['Juliana']);
      expect(FiltroClientes.contagens(lista, _hoje), {
        StatusFiltroCliente.todos: 4,
        StatusFiltroCliente.emDia: 3,
        StatusFiltroCliente.comSaldo: 2,
        StatusFiltroCliente.aniversariantes: 1,
      });
    });
  });

  group('DTOs', () {
    test('resumo converte numeric (número ou texto) em centavos', () {
      final dto = ResumoClienteDto.fromJson({
        'id': 'c1',
        'nome': 'Ana',
        'whatsapp': '11987654321',
        'data_nascimento': '1990-05-10',
        'created_at': '2026-11-17T12:00:00+00:00',
        'qtd_compras': 2,
        'total_compras': 350,
        'ultima_compra': null,
        'saldo_devedor': '270.5',
        'valor_atrasado': 70.1,
        'valor_vence_hoje': 0,
      });
      final model = dto.paraModel();
      expect(model.totalCompras, 35000);
      expect(model.saldoDevedor, 27050);
      expect(model.valorAtrasado, 7010);
      expect(model.dataNascimento, DateTime(1990, 5, 10));
      expect(model.ultimaCompra, isNull);
    });

    test('cliente com endereço embutido e sem endereço', () {
      final comEndereco = ClienteDto.fromJson({
        'id': 'c1',
        'endereco_id': 'e1',
        'nome': 'Ana',
        'whatsapp': '11987654321',
        'data_nascimento': null,
        'observacoes': 'Florais',
        'created_at': '2026-11-17T12:00:00Z',
        'enderecos': {
          'id': 'e1',
          'cep': '01001000',
          'rua': 'Praça da Sé',
          'numero': '10',
          'uf': 'SP',
        },
      }).paraModel();
      expect(comEndereco.temEndereco, isTrue);
      expect(comEndereco.endereco!.linhaRua, 'Praça da Sé, 10');

      final semEndereco = ClienteDto.fromJson({
        'id': 'c2',
        'endereco_id': null,
        'nome': 'Bia',
        'whatsapp': '11987654321',
        'created_at': '2026-11-17T12:00:00Z',
        'enderecos': null,
      }).paraModel();
      expect(semEndereco.temEndereco, isFalse);
    });

    test('data para gravar', () {
      expect(ConversoresDto.textoData(DateTime(1990, 5, 3)), '1990-05-03');
      expect(ConversoresDto.textoData(null), isNull);
    });
  });
}
