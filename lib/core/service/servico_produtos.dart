import 'dart:typed_data';

import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/resumo_produto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto.dart';

/// Acesso a `produtos`, à view `resumo_produtos` e às fotos de produto.
/// Nunca envia `consultora_id`, `id` nem `created_at`: o banco preenche e o RLS confere.
class ServicoProdutos {
  ServicoProdutos({required this._api, DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  final ApiSupabase _api;
  final DateTime Function() _agora;

  static const _tabela = 'produtos';
  static const _view = 'resumo_produtos';
  static const _bucketFotos = 'fotos';

  Future<Resultado<List<ResumoProdutoDto>>> listarResumos() {
    return executarComFalha(() async {
      final linhas = await _api.listar(_view, ordenarPor: 'nome');
      return linhas.map(ResumoProdutoDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os produtos.');
  }

  /// Resumo de um produto (Sucesso(null) se não existir ou não for da consultora).
  Future<Resultado<ResumoProdutoDto?>> buscarResumo(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(_view, coluna: 'id', valor: id);
      return linha == null ? null : ResumoProdutoDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar o produto.');
  }

  /// Cria o produto e devolve o id.
  Future<Resultado<String>> criar(Produto produto) {
    return executarComFalha(
      () async {
        final linha = await _api.inserir(_tabela, produto.paraGravar());
        return linha['id'] as String;
      },
      mensagemPadrao: 'Não foi possível salvar o produto.',
      mensagemDuplicado: Produto.mensagemCodigoDuplicado,
    );
  }

  /// Atualiza o produto [id] e devolve o id.
  Future<Resultado<String>> atualizar(String id, Produto produto) {
    return executarComFalha(
      () async {
        final linha = await _api.atualizar(
          _tabela,
          produto.paraGravar(),
          coluna: 'id',
          valor: id,
        );
        return linha['id'] as String;
      },
      mensagemPadrao: 'Não foi possível salvar o produto.',
      mensagemDuplicado: Produto.mensagemCodigoDuplicado,
    );
  }

  /// Envia a foto para `fotos/<id>/produtos/<momento>.jpg` e devolve o caminho.
  Future<Resultado<String>> enviarFoto(Uint8List bytes) async {
    final id = _api.idUsuario;
    if (id == null) {
      return Erro(
        const FalhaAutenticacao('Sua sessão terminou. Entre novamente.'),
      );
    }
    return executarComFalha(() async {
      final caminho = '$id/produtos/${_agora().millisecondsSinceEpoch}.jpg';
      await _api.enviarArquivo(
        _bucketFotos,
        caminho,
        bytes,
        tipoConteudo: 'image/jpeg',
      );
      return caminho;
    }, mensagemPadrao: 'Não foi possível enviar a foto.');
  }

  Future<Resultado<void>> removerFoto(String caminho) {
    return executarComFalha(
      () => _api.removerArquivos(_bucketFotos, [caminho]),
      mensagemPadrao: 'Não foi possível remover a foto.',
    );
  }

  /// URLs assinadas das fotos (caminho → URL), numa chamada só.
  Future<Resultado<Map<String, String>>> urlsDasFotos(List<String> caminhos) {
    return executarComFalha(
      () => _api.urlsAssinadas(_bucketFotos, caminhos),
      mensagemPadrao: 'Não foi possível carregar as fotos.',
    );
  }
}
