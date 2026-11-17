import 'dart:async';
import 'dart:typed_data';

import 'package:sou_consultora/core/dto/resumo_produto_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/gravacao_com_foto.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';
import 'package:sou_consultora/core/service/servico_produtos.dart';

/// Produtos da consultora logada.
///
/// Guarda a última lista carregada (com as URLs das fotos) e avisa em
/// [mudancas] sempre que ela muda. Esquece tudo quando a sessão termina.
class RepositorioProdutos {
  RepositorioProdutos({
    required this._servico,
    required this._fotos,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoProdutos _servico;
  final ServicoFotoDispositivo _fotos;
  final _mudancas = StreamController<List<ResumoProduto>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoProduto>? _lista;

  /// Última lista carregada (null se ainda não carregou).
  List<ResumoProduto>? get lista => _lista;
  Stream<List<ResumoProduto>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoProduto>>> carregar() async {
    final resultado = await _servico.listarResumos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(_publicar(await _comFotos(valor))),
    };
  }

  /// Resumo atualizado de um produto (Sucesso(null) se não existir).
  Future<Resultado<ResumoProduto?>> buscarResumo(String id) async {
    final resultado = await _servico.buscarResumo(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(valor: null) => const Sucesso(null),
      Sucesso(:final valor?) => Sucesso((await _comFotos([valor])).first),
    };
  }

  /// Resumo já carregado na lista (para abrir os detalhes sem esperar a rede).
  ResumoProduto? resumoEmCache(String id) {
    for (final produto in _lista ?? const <ResumoProduto>[]) {
      if (produto.id == id) return produto;
    }
    return null;
  }

  Future<Resultado<Uint8List?>> escolherFoto(OrigemFoto origem) =>
      _fotos.escolherRecortada(origem);

  /// Cria ([id] nulo) ou edita, aplicando [foto]. Em sucesso, recarrega a lista
  /// e devolve o id.
  ///
  /// A foto nova é enviada antes de gravar; se a gravação falhar, ela é apagada.
  /// A foto antiga só é apagada depois que a gravação deu certo.
  Future<Resultado<String>> salvar(
    Produto produto, {
    String? id,
    MudancaFoto foto = const ManterFoto(),
  }) async {
    final resultado = await gravarComFoto(
      caminhoAnterior: produto.caminhoFoto,
      foto: foto,
      enviar: _servico.enviarFoto,
      remover: _servico.removerFoto,
      gravar: (caminho) => id == null
          ? _servico.criar(_comFoto(produto, caminho))
          : _servico.atualizar(id, _comFoto(produto, caminho)),
    );
    if (resultado is Erro<String>) return resultado;
    // A gravação já valeu; se recarregar falhar, a lista atualiza na próxima abertura.
    await carregar();
    return resultado;
  }

  /// Esquece os produtos (ao sair da conta).
  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  Future<List<ResumoProduto>> _comFotos(List<ResumoProdutoDto> dtos) async {
    final caminhos = [for (final dto in dtos) ?dto.fotoUrl];
    final urls = switch (await _servico.urlsDasFotos(caminhos)) {
      Sucesso(:final valor) => valor,
      // Sem as URLs a lista ainda funciona: o card mostra o ícone de reserva.
      Erro() => const <String, String>{},
    };
    return [for (final dto in dtos) dto.paraModel(urlFoto: urls[dto.fotoUrl])];
  }

  List<ResumoProduto> _publicar(List<ResumoProduto> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }

  static Produto _comFoto(Produto produto, String? caminho) => Produto(
    nome: produto.nome,
    fornecedorId: produto.fornecedorId,
    categoriaId: produto.categoriaId,
    precoVendaCentavos: produto.precoVendaCentavos,
    codigo: produto.codigo,
    precoCustoCentavos: produto.precoCustoCentavos,
    durabilidadeDias: produto.durabilidadeDias,
    observacoes: produto.observacoes,
    caminhoFoto: caminho,
  );
}
