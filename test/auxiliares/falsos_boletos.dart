import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_abrir_link.dart';
import 'package:sou_consultora/core/service/servico_boletos.dart';
import 'package:sou_consultora/core/service/servico_escolher_comprovante.dart';

BoletoDto boletoDto(
  String id, {
  String fornecedorId = 'f1',
  String fornecedor = 'Natura',
  bool fornecedorAtivo = true,
  int valor = 68000,
  DateTime? vencimento,
  String? forma,
  String? observacoes,
  String? comprovante,
  DateTime? pagoEm,
}) => BoletoDto(
  id: id,
  fornecedorId: fornecedorId,
  fornecedorNome: fornecedor,
  fornecedorAtivo: fornecedorAtivo,
  valor: valor,
  dataVencimento: vencimento ?? DateTime.now().add(const Duration(days: 7)),
  createdAt: DateTime.now(),
  formaPagamento: forma,
  observacoes: observacoes,
  comprovanteUrl: comprovante,
  dataPagamento: pagoEm,
);

/// Service falso em memória para A pagar; registra cada chamada em [chamadas].
class ServicoBoletosFalso implements ServicoBoletos {
  ServicoBoletosFalso({
    List<BoletoDto>? boletos,
    Map<String, String>? nomesFornecedores,
  }) : boletos = boletos ?? [],
       nomesFornecedores = nomesFornecedores ?? {'f1': 'Natura'};

  List<BoletoDto> boletos;
  final Map<String, String> nomesFornecedores;
  bool falharRede = false;
  FalhaApp? falhaAoGravar;
  bool falharEnvio = false;
  bool falharGravacaoComprovante = false;
  final List<String> chamadas = [];
  final List<({String? id, PedidoBoleto pedido})> salvos = [];
  final List<String> enviados = [];
  final List<String> removidos = [];
  int _contador = 0;

  static const _falha = FalhaRede(
    'Sem conexão com a internet. Verifique e tente novamente.',
  );

  @override
  Future<Resultado<List<BoletoDto>>> listar() async {
    chamadas.add('listar');
    return falharRede ? Erro(_falha) : Sucesso(List.of(boletos));
  }

  @override
  Future<Resultado<BoletoDto?>> buscar(String id) async {
    chamadas.add('buscar $id');
    if (falharRede) return Erro(_falha);
    return Sucesso(boletos.where((b) => b.id == id).firstOrNull);
  }

  @override
  Future<Resultado<String>> criar(PedidoBoleto pedido) => _salvar(null, pedido);

  @override
  Future<Resultado<String>> atualizar(String id, PedidoBoleto pedido) =>
      _salvar(id, pedido);

  Future<Resultado<String>> _salvar(String? id, PedidoBoleto pedido) async {
    chamadas.add(id == null ? 'criar' : 'atualizar $id');
    if (falharRede) return Erro(_falha);
    if (falhaAoGravar case final falha?) return Erro(falha);
    final novoId = id ?? 'novo-${++_contador}';
    final antigo = boletos.where((b) => b.id == novoId).firstOrNull;
    salvos.add((id: id, pedido: pedido));
    _trocar(
      novoId,
      boletoDto(
        novoId,
        fornecedorId: pedido.fornecedorId,
        fornecedor: nomesFornecedores[pedido.fornecedorId] ?? 'Marca',
        valor: pedido.valor,
        vencimento: pedido.vencimento,
        forma: pedido.forma?.valorBanco,
        observacoes: pedido.observacoes,
        comprovante: antigo?.comprovanteUrl,
        pagoEm: antigo?.dataPagamento,
      ),
    );
    return Sucesso(novoId);
  }

  @override
  Future<Resultado<String>> pagar(String id, DateTime data) async {
    chamadas.add('pagar $id');
    if (falharRede) return Erro(_falha);
    if (falhaAoGravar case final falha?) return Erro(falha);
    _alterar(id, pagoEm: () => DateTime(data.year, data.month, data.day));
    return Sucesso(id);
  }

  @override
  Future<Resultado<String>> desfazerPagamento(String id) async {
    chamadas.add('desfazer $id');
    if (falharRede) return Erro(_falha);
    _alterar(id, pagoEm: () => null);
    return Sucesso(id);
  }

  @override
  Future<Resultado<String>> gravarComprovante(
    String id,
    String? caminho,
  ) async {
    chamadas.add('gravar comprovante $id');
    if (falharGravacaoComprovante) return Erro(_falha);
    _alterar(id, comprovante: () => caminho);
    return Sucesso(id);
  }

  @override
  Future<Resultado<bool>> excluir(String id) async {
    chamadas.add('excluir $id');
    if (falharRede) return Erro(_falha);
    final antes = boletos.length;
    boletos = boletos.where((b) => b.id != id).toList();
    return Sucesso(boletos.length < antes);
  }

  @override
  Future<Resultado<String>> enviarComprovante(
    String idBoleto,
    ArquivoComprovante arquivo,
  ) async {
    chamadas.add('enviar comprovante $idBoleto');
    if (falharEnvio) return Erro(_falha);
    final caminho =
        'id-ana/boletos/$idBoleto/${enviados.length + 1}.${arquivo.tipo.extensao}';
    enviados.add(caminho);
    return Sucesso(caminho);
  }

  @override
  Future<Resultado<void>> removerComprovante(String caminho) async {
    chamadas.add('remover $caminho');
    removidos.add(caminho);
    return const Sucesso(null);
  }

  @override
  Future<Resultado<String>> linkComprovante(String caminho) async =>
      Sucesso('https://assinada/$caminho');

  void _trocar(String id, BoletoDto novo) {
    boletos = [
      for (final b in boletos)
        if (b.id != id) b,
      novo,
    ];
  }

  void _alterar(
    String id, {
    DateTime? Function()? pagoEm,
    String? Function()? comprovante,
  }) {
    final b = boletos.firstWhere((b) => b.id == id);
    _trocar(
      id,
      boletoDto(
        b.id,
        fornecedorId: b.fornecedorId,
        fornecedor: b.fornecedorNome,
        fornecedorAtivo: b.fornecedorAtivo,
        valor: b.valor,
        vencimento: b.dataVencimento,
        forma: b.formaPagamento,
        observacoes: b.observacoes,
        comprovante: comprovante != null ? comprovante() : b.comprovanteUrl,
        pagoEm: pagoEm != null ? pagoEm() : b.dataPagamento,
      ),
    );
  }
}

/// Guarda os links em vez de abrir.
class ServicoAbrirLinkFalso implements ServicoAbrirLink {
  final List<String> abertos = [];

  @override
  Future<Resultado<void>> abrir(String url) async {
    abertos.add(url);
    return const Sucesso(null);
  }
}

/// Devolve o [arquivo] configurado (null = a pessoa desistiu).
class EscolherComprovanteFalso implements ServicoEscolherComprovante {
  ArquivoComprovante? arquivo;
  final List<OrigemComprovante> origens = [];

  @override
  Future<Resultado<ArquivoComprovante?>> escolher(
    OrigemComprovante origem,
  ) async {
    origens.add(origem);
    return Sucesso(arquivo);
  }
}

RepositorioBoletos repositorioBoletosDeTeste(
  ServicoBoletosFalso servico, {
  required RepositorioFornecedores fornecedores,
  ServicoAbrirLinkFalso? abrirLink,
  EscolherComprovanteFalso? escolher,
}) => RepositorioBoletos(
  servico: servico,
  fornecedores: fornecedores,
  abrirLink: abrirLink ?? ServicoAbrirLinkFalso(),
  escolher: escolher ?? EscolherComprovanteFalso(),
);
