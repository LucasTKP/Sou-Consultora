import 'dart:typed_data';

import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/consultora_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Acesso à tabela `consultoras` e às fotos de perfil no bucket `fotos`.
class ServicoConsultora {
  ServicoConsultora({required this._api, DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  final ApiSupabase _api;
  final DateTime Function() _agora;

  static const _tabela = 'consultoras';
  static const _bucketFotos = 'fotos';

  /// Registro da consultora logada (Sucesso(null) quando ainda não se cadastrou).
  Future<Resultado<ConsultoraDto?>> buscarMinha() {
    return _comUsuario((id) async {
      final linha = await _api.buscarUm(_tabela, coluna: 'id', valor: id);
      return linha == null ? null : ConsultoraDto.fromJson(linha);
    }, 'Não foi possível carregar seus dados.');
  }

  /// Cria o registro. O id é preenchido pelo banco com o usuário logado.
  Future<Resultado<ConsultoraDto>> criar({required String nome, required String whatsapp}) {
    return executarComFalha(
      () async => ConsultoraDto.fromJson(await _api.inserir(_tabela, {'nome': nome, 'whatsapp': whatsapp})),
      mensagemPadrao: 'Não foi possível concluir o cadastro.',
    );
  }

  Future<Resultado<ConsultoraDto>> atualizar({
    required String nome,
    required String whatsapp,
    required String? chavePix,
    required String? tipoChavePix,
  }) {
    final dados = {'nome': nome, 'whatsapp': whatsapp, 'chave_pix': chavePix, 'tipo_chave_pix': tipoChavePix};
    return _atualizar(dados, 'Não foi possível salvar as alterações.');
  }

  /// Grava o caminho da foto (null remove).
  Future<Resultado<ConsultoraDto>> atualizarFoto(String? caminho) {
    return _atualizar({'foto_url': caminho}, 'Não foi possível atualizar a foto.');
  }

  /// Envia a foto para `fotos/<id>/perfil-<momento>.jpg` e devolve o caminho.
  Future<Resultado<String>> enviarFoto(Uint8List bytes) {
    return _comUsuario((id) async {
      final caminho = '$id/perfil-${_agora().millisecondsSinceEpoch}.jpg';
      await _api.enviarArquivo(_bucketFotos, caminho, bytes, tipoConteudo: 'image/jpeg');
      return caminho;
    }, 'Não foi possível enviar a foto.');
  }

  Future<Resultado<void>> removerFoto(String caminho) {
    return executarComFalha(
      () => _api.removerArquivos(_bucketFotos, [caminho]),
      mensagemPadrao: 'Não foi possível remover a foto.',
    );
  }

  Future<Resultado<String>> urlDaFoto(String caminho) {
    return executarComFalha(
      () => _api.urlAssinada(_bucketFotos, caminho),
      mensagemPadrao: 'Não foi possível carregar a foto.',
    );
  }

  Future<Resultado<ConsultoraDto>> _atualizar(Map<String, dynamic> dados, String mensagemPadrao) {
    return _comUsuario(
      (id) async => ConsultoraDto.fromJson(await _api.atualizar(_tabela, dados, coluna: 'id', valor: id)),
      mensagemPadrao,
    );
  }

  Future<Resultado<T>> _comUsuario<T>(Future<T> Function(String id) acao, String mensagemPadrao) async {
    final id = _api.idUsuario;
    if (id == null) return const Erro(FalhaAutenticacao('Sua sessão terminou. Entre novamente.'));
    return executarComFalha(() => acao(id), mensagemPadrao: mensagemPadrao);
  }
}
