import 'dart:async';

import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_abrir_link.dart';
import 'package:sou_consultora/core/service/servico_boletos.dart';
import 'package:sou_consultora/core/service/servico_escolher_comprovante.dart';

/// Boletos (A pagar) da consultora logada.
///
/// Guarda a lista e avisa em [mudancas]. Depois de lançar, editar, pagar,
/// desfazer ou excluir, recarrega a lista e os fornecedores (os números de
/// boletos de cada marca vêm deles).
class RepositorioBoletos {
  RepositorioBoletos({
    required this._servico,
    required this._fornecedores,
    required this._abrirLink,
    required this._escolher,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoBoletos _servico;
  final RepositorioFornecedores _fornecedores;
  final ServicoAbrirLink _abrirLink;
  final ServicoEscolherComprovante _escolher;
  final _mudancas = StreamController<List<ResumoBoleto>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoBoleto>? _lista;

  List<ResumoBoleto>? get lista => _lista;
  Stream<List<ResumoBoleto>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoBoleto>>> carregar() async {
    final resultado = await _servico.listar();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _publicar([for (final dto in valor) dto.paraModel()]),
      ),
    };
  }

  /// Boleto atualizado do banco (Sucesso(null) se não existir).
  Future<Resultado<ResumoBoleto?>> buscar(String id) async {
    final resultado = await _servico.buscar(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(valor?.paraModel()),
    };
  }

  /// Boleto já carregado na lista (abre os detalhes sem esperar a rede).
  ResumoBoleto? emCache(String id) {
    for (final boleto in _lista ?? const <ResumoBoleto>[]) {
      if (boleto.id == id) return boleto;
    }
    return null;
  }

  /// Lança ([id] nulo) ou edita. Devolve o id.
  Future<Resultado<String>> salvar(PedidoBoleto pedido, {String? id}) =>
      _depoisDeGravar(
        id == null ? _servico.criar(pedido) : _servico.atualizar(id, pedido),
      );

  Future<Resultado<String>> pagar(String id, DateTime data) =>
      _depoisDeGravar(_servico.pagar(id, data));

  Future<Resultado<String>> desfazerPagamento(String id) =>
      _depoisDeGravar(_servico.desfazerPagamento(id));

  /// Apaga o boleto e depois o comprovante. Se só a remoção do arquivo
  /// falhar, o boleto continua excluído (o erro fica no log de depuração).
  Future<Resultado<void>> excluir(ResumoBoleto boleto) async {
    final resultado = await _servico.excluir(boleto.id);
    switch (resultado) {
      case Erro(:final falha):
        return Erro(falha);
      case Sucesso(valor: false):
        return Erro(const FalhaValidacao('Boleto não encontrado.'));
      case Sucesso():
        if (boleto.caminhoComprovante case final caminho?) {
          await _servico.removerComprovante(caminho);
        }
        await _recarregar();
        return const Sucesso(null);
    }
  }

  /// Foto (câmera/galeria) ou PDF; Sucesso(null) se a pessoa desistir.
  Future<Resultado<ArquivoComprovante?>> escolherComprovante(
    OrigemComprovante origem,
  ) => _escolher.escolher(origem);

  /// Envia o arquivo, grava o caminho no boleto e só então remove o antigo.
  /// Se a gravação falhar, apaga o recém-enviado.
  Future<Resultado<String>> anexarComprovante(
    ResumoBoleto boleto,
    ArquivoComprovante arquivo,
  ) async {
    final tamanho = ArquivoComprovante.validarTamanho(arquivo.bytes.length);
    if (tamanho != null) return Erro(FalhaValidacao(tamanho));

    final envio = await _servico.enviarComprovante(boleto.id, arquivo);
    if (envio case Erro(:final falha)) return Erro(falha);
    final caminho = (envio as Sucesso<String>).valor;

    final gravacao = await _servico.gravarComprovante(boleto.id, caminho);
    if (gravacao case Erro(:final falha)) {
      await _servico.removerComprovante(caminho);
      return Erro(falha);
    }
    if (boleto.caminhoComprovante case final antigo?) {
      await _servico.removerComprovante(antigo);
    }
    await carregar();
    return Sucesso(caminho);
  }

  /// Abre o comprovante por um link temporário.
  Future<Resultado<void>> abrirComprovante(String caminho) async {
    final link = await _servico.linkComprovante(caminho);
    return switch (link) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => _abrirLink.abrir(valor),
    };
  }

  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  Future<Resultado<String>> _depoisDeGravar(
    Future<Resultado<String>> gravacao,
  ) async {
    final resultado = await gravacao;
    // A gravação já valeu; se recarregar falhar, atualiza na próxima abertura.
    if (resultado is Sucesso<String>) await _recarregar();
    return resultado;
  }

  Future<void> _recarregar() async {
    await Future.wait([carregar(), _fornecedores.carregar()]);
  }

  List<ResumoBoleto> _publicar(List<ResumoBoleto> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
