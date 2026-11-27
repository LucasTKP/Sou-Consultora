import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_boletos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_fornecedores.dart';

ResumoBoleto _boleto(
  String id, {
  required DateTime vencimento,
  String fornecedorId = 'f1',
  String marca = 'Natura',
  int valor = 10000,
  String? observacoes,
  DateTime? pagoEm,
}) => ResumoBoleto(
  id: id,
  fornecedorId: fornecedorId,
  fornecedorNome: marca,
  valor: valor,
  vencimento: vencimento,
  observacoes: observacoes,
  dataPagamento: pagoEm,
);

void main() {
  final hoje = DateTime(2026, 11, 12, 9);

  group('Boleto (model)', () {
    test('situação: pago, atrasado, vence hoje e pendente', () {
      expect(
        _boleto('a', vencimento: DateTime(2026, 11, 5)).status(hoje: hoje),
        StatusBoleto.atrasado,
      );
      expect(
        _boleto('h', vencimento: DateTime(2026, 11, 12)).status(hoje: hoje),
        StatusBoleto.venceHoje,
      );
      expect(
        _boleto('p', vencimento: DateTime(2026, 11, 18)).status(hoje: hoje),
        StatusBoleto.pendente,
      );
      // Pago vale mais que vencido.
      expect(
        _boleto(
          'x',
          vencimento: DateTime(2026, 11, 5),
          pagoEm: DateTime(2026, 11, 1),
        ).status(hoje: hoje),
        StatusBoleto.pago,
      );
    });

    test('dias de atraso e para vencer', () {
      final atrasado = _boleto('a', vencimento: DateTime(2026, 11, 5));
      final futuro = _boleto('f', vencimento: DateTime(2026, 11, 18));
      expect(atrasado.diasAtraso(hoje: hoje), 7);
      expect(atrasado.diasParaVencer(hoje: hoje), 0);
      expect(futuro.diasParaVencer(hoje: hoje), 6);
      expect(futuro.diasAtraso(hoje: hoje), 0);
    });

    test('iniciais e tipo do comprovante', () {
      expect(_boleto('a', vencimento: hoje).iniciais, 'NAT');
      final comPdf = ResumoBoleto(
        id: 'c',
        fornecedorId: 'f1',
        fornecedorNome: 'O Boticário',
        valor: 1,
        vencimento: hoje,
        caminhoComprovante: 'id/boletos/c/1.PDF',
      );
      expect(comPdf.iniciais, 'OB');
      expect(comPdf.temComprovante, isTrue);
      expect(comPdf.comprovanteEmPdf, isTrue);
    });

    test('validações do lançamento e da data de pagamento', () {
      expect(PedidoBoleto.validarFornecedor(null), 'Escolha a marca do boleto');
      expect(PedidoBoleto.validarFornecedor('f1'), isNull);
      expect(PedidoBoleto.validarValor(0), 'Informe o valor do boleto');
      expect(PedidoBoleto.validarValor(null), 'Informe o valor do boleto');
      expect(PedidoBoleto.validarValor(1), isNull);
      expect(PedidoBoleto.validarVencimento(null), isNotNull);
      expect(
        ResumoBoleto.validarDataPagamento(DateTime(2026, 11, 13), hoje: hoje),
        'A data do pagamento não pode ser no futuro',
      );
      expect(
        ResumoBoleto.validarDataPagamento(
          DateTime(2026, 11, 12, 23),
          hoje: hoje,
        ),
        isNull,
      );
    });

    test('comprovante: tipo pelo nome e limite de 10 MB', () {
      expect(TipoComprovante.doNome('extrato.PDF'), TipoComprovante.pdf);
      expect(TipoComprovante.doNome('foto.jpeg'), TipoComprovante.jpg);
      expect(TipoComprovante.doNome('planilha.xlsx'), isNull);
      expect(ArquivoComprovante.validarTamanho(10 * 1024 * 1024), isNull);
      expect(
        ArquivoComprovante.validarTamanho(10 * 1024 * 1024 + 1),
        contains('10 MB'),
      );
    });

    test('DTO da view resumo_boletos', () {
      final boleto = BoletoDto.fromJson({
        'id': 'b1',
        'fornecedor_id': 'f1',
        'fornecedor_nome': 'Avon Cosméticos',
        'fornecedor_ativo': false,
        'valor': '420.00',
        'data_vencimento': '2026-11-01',
        'forma_pagamento': 'transferencia',
        'observacoes': 'Ciclo 15',
        'comprovante_url': 'id/boletos/b1/1.pdf',
        'data_pagamento': '2026-11-01',
        'created_at': '2026-10-20T12:00:00Z',
      }).paraModel();
      expect(boleto.valor, 42000);
      expect(boleto.fornecedorAtivo, isFalse);
      expect(boleto.forma, FormaPagamentoBoleto.transferencia);
      expect(boleto.dataPagamento, DateTime(2026, 11, 1));
      expect(boleto.pago, isTrue);
    });
  });

  group('Filtro de boletos', () {
    final boletos = [
      _boleto(
        'pago',
        vencimento: DateTime(2026, 11, 1),
        marca: 'Avon',
        pagoEm: DateTime(2026, 11, 1),
      ),
      _boleto(
        'atrasado',
        vencimento: DateTime(2026, 11, 5),
        marca: 'Eudora',
        fornecedorId: 'f2',
      ),
      _boleto(
        'hoje',
        vencimento: DateTime(2026, 11, 12),
        observacoes: 'Ciclo 15 com desconto',
      ),
      _boleto(
        'futuro',
        vencimento: DateTime(2026, 11, 18),
        marca: 'O Boticário',
        fornecedorId: 'f3',
      ),
      _boleto('dezembro', vencimento: DateTime(2026, 12, 3)),
    ];

    List<String> ids({
      StatusFiltroBoleto status = StatusFiltroBoleto.todos,
      MesAno? mes = const MesAno(2026, 11),
      String busca = '',
      OrdemBoleto ordem = OrdemBoleto.vencimentoProximo,
      String? fornecedorId,
    }) => FiltroBoletos.aplicar(
      boletos,
      status: status,
      mes: mes,
      busca: busca,
      ordem: ordem,
      hoje: hoje,
      fornecedorId: fornecedorId,
    ).map((b) => b.id).toList();

    test('mês pelo vencimento, do mais próximo ao mais distante', () {
      expect(ids(), ['pago', 'atrasado', 'hoje', 'futuro']);
      expect(ids(mes: null), [
        'pago',
        'atrasado',
        'hoje',
        'futuro',
        'dezembro',
      ]);
      expect(ids(ordem: OrdemBoleto.vencimentoDistante).first, 'futuro');
    });

    test('status e contagens', () {
      expect(ids(status: StatusFiltroBoleto.atrasado), ['atrasado']);
      expect(ids(status: StatusFiltroBoleto.venceHoje), ['hoje']);
      expect(ids(status: StatusFiltroBoleto.pendente), ['futuro']);
      expect(ids(status: StatusFiltroBoleto.pago), ['pago']);
      final contagens = FiltroBoletos.contagens(
        boletos,
        mes: const MesAno(2026, 11),
        hoje: hoje,
      );
      expect(contagens[StatusFiltroBoleto.todos], 4);
      expect(contagens[StatusFiltroBoleto.pendente], 1);
      expect(contagens[StatusFiltroBoleto.pago], 1);
    });

    test('busca pela marca e pela observação, sem acento', () {
      expect(ids(busca: 'boticario'), ['futuro']);
      expect(ids(busca: 'CICLO 15'), ['hoje']);
      expect(ids(busca: 'inexistente'), isEmpty);
    });

    test('só do fornecedor (aberta por Fornecedores)', () {
      expect(ids(fornecedorId: 'f2'), ['atrasado']);
      expect(
        FiltroBoletos.contagens(
          boletos,
          mes: null,
          hoje: hoje,
          fornecedorId: 'f1',
        )[StatusFiltroBoleto.todos],
        3,
      );
    });

    test('meses com vencimentos mais o atual, do mais recente', () {
      expect(FiltroBoletos.meses(boletos, hoje: hoje), const [
        MesAno(2026, 12),
        MesAno(2026, 11),
      ]);
    });
  });

  group('Repositório de boletos', () {
    late ServicoBoletosFalso servico;
    late ServicoFornecedoresFalso servicoFornecedores;
    late ServicoAbrirLinkFalso links;
    late RepositorioBoletos repositorio;
    final png = ArquivoComprovante(
      bytes: Uint8List.fromList([1, 2, 3]),
      tipo: TipoComprovante.png,
    );

    setUp(() {
      servico = ServicoBoletosFalso(
        boletos: [boletoDto('b1', comprovante: 'id-ana/boletos/b1/antigo.pdf')],
      );
      servicoFornecedores = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Natura')],
      );
      links = ServicoAbrirLinkFalso();
      repositorio = repositorioBoletosDeTeste(
        servico,
        fornecedores: repositorioFornecedoresDeTeste(servicoFornecedores),
        abrirLink: links,
      );
    });

    Future<ResumoBoleto> b1() async {
      await repositorio.carregar();
      return repositorio.emCache('b1')!;
    }

    test(
      'lançar, pagar e desfazer recarregam boletos e fornecedores',
      () async {
        await repositorio.salvar(
          PedidoBoleto(
            fornecedorId: 'f1',
            valor: 68000,
            vencimento: DateTime(2026, 11, 25),
          ),
        );
        expect(servicoFornecedores.chamadas, contains('listar'));
        expect(repositorio.lista, hasLength(2));

        servicoFornecedores.chamadas.clear();
        await repositorio.pagar('b1', DateTime(2026, 11, 12));
        expect(repositorio.emCache('b1')!.pago, isTrue);
        expect(servicoFornecedores.chamadas, ['listar']);

        await repositorio.desfazerPagamento('b1');
        expect(repositorio.emCache('b1')!.pago, isFalse);
      },
    );

    test('anexar envia, grava e só então remove o antigo', () async {
      final resultado = await repositorio.anexarComprovante(await b1(), png);

      expect((resultado as Sucesso<String>).valor, 'id-ana/boletos/b1/1.png');
      expect(servico.chamadas.skipWhile((c) => c != 'enviar comprovante b1'), [
        'enviar comprovante b1',
        'gravar comprovante b1',
        'remover id-ana/boletos/b1/antigo.pdf',
        'listar',
      ]);
      expect(repositorio.emCache('b1')!.caminhoComprovante, endsWith('1.png'));
    });

    test(
      'se gravar o caminho falhar, apaga o recém-enviado e mantém o antigo',
      () async {
        servico.falharGravacaoComprovante = true;
        final resultado = await repositorio.anexarComprovante(await b1(), png);

        expect(resultado, isA<Erro<String>>());
        expect(servico.removidos, ['id-ana/boletos/b1/1.png']);
        expect(
          servico.boletos.single.comprovanteUrl,
          'id-ana/boletos/b1/antigo.pdf',
        );
      },
    );

    test('arquivo acima de 10 MB nem é enviado', () async {
      final grande = ArquivoComprovante(
        bytes: Uint8List(ArquivoComprovante.limiteBytes + 1),
        tipo: TipoComprovante.pdf,
      );
      final resultado = await repositorio.anexarComprovante(await b1(), grande);
      expect((resultado as Erro).falha.mensagem, contains('10 MB'));
      expect(servico.enviados, isEmpty);
    });

    test('excluir apaga o boleto, o comprovante e recarrega', () async {
      final resultado = await repositorio.excluir(await b1());
      expect(resultado, isA<Sucesso<void>>());
      expect(servico.removidos, ['id-ana/boletos/b1/antigo.pdf']);
      expect(repositorio.lista, isEmpty);
      expect(servicoFornecedores.chamadas, contains('listar'));
    });

    test('excluir boleto que não existe avisa', () async {
      final boleto = await b1();
      servico.boletos = [];
      final resultado = await repositorio.excluir(boleto);
      expect((resultado as Erro).falha.mensagem, 'Boleto não encontrado.');
      expect(servico.removidos, isEmpty);
    });

    test('ver comprovante abre o link temporário', () async {
      await repositorio.abrirComprovante('id-ana/boletos/b1/antigo.pdf');
      expect(links.abertos, ['https://assinada/id-ana/boletos/b1/antigo.pdf']);
    });
  });
}
