import 'dart:async';
import 'dart:typed_data';

import 'package:sou_consultora/core/dto/consultora_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/marca_padrao.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/telefone.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';

/// Dados da consultora logada, compartilhados pelo app (menu, perfil...).
///
/// Guarda a versão atual e avisa em [mudancas] a cada alteração.
class RepositorioConsultora {
  RepositorioConsultora({
    required this._servico,
    required this._fotos,
    required this._fornecedores,
  });

  final ServicoConsultora _servico;
  final ServicoFornecedores _fornecedores;
  final ServicoFotoDispositivo _fotos;
  final _mudancas = StreamController<Consultora?>.broadcast();

  Consultora? _atual;

  Consultora? get atual => _atual;
  Stream<Consultora?> get mudancas => _mudancas.stream;

  /// Busca o registro (Sucesso(null) = ainda sem cadastro).
  Future<Resultado<Consultora?>> buscarMinha() async {
    final resultado = await _servico.buscarMinha();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(valor: null) => Sucesso(_publicar(null)),
      Sucesso(valor: final ConsultoraDto dto) => Sucesso(
        _publicar(await _paraModel(dto)),
      ),
    };
  }

  /// Cria o cadastro e, antes de liberar o app, os fornecedores das [marcas]
  /// marcadas. Falha em uma marca não impede o cadastro (ela cadastra depois).
  Future<Resultado<Consultora>> cadastrar({
    required String nome,
    required String whatsapp,
    List<MarcaPadrao> marcas = const [],
  }) async {
    final resultado = await _servico.criar(
      nome: nome.trim(),
      whatsapp: Telefone.digitos(whatsapp),
    );
    if (resultado is Sucesso && marcas.isNotEmpty) {
      await Future.wait(
        marcas.map((marca) => _fornecedores.criar(marca.paraFornecedor())),
      );
    }
    return _publicarResultado(resultado);
  }

  Future<Resultado<Consultora>> atualizar({
    required String nome,
    required String whatsapp,
    ChavePix? chavePix,
  }) async {
    final resultado = await _servico.atualizar(
      nome: nome.trim(),
      whatsapp: Telefone.digitos(whatsapp),
      chavePix: chavePix?.valor,
      tipoChavePix: chavePix?.tipo.valorBanco,
    );
    return _publicarResultado(resultado);
  }

  Future<Resultado<Uint8List?>> escolherFoto(OrigemFoto origem) =>
      _fotos.escolherRecortada(origem);

  /// Envia a nova foto, aponta o cadastro para ela e apaga a anterior.
  Future<Resultado<Consultora>> trocarFoto(Uint8List bytes) async {
    final anterior = _atual?.caminhoFoto;
    final envio = await _servico.enviarFoto(bytes);
    if (envio case Erro(:final falha)) return Erro(falha);
    final caminho = (envio as Sucesso<String>).valor;

    final resultado = await _servico.atualizarFoto(caminho);
    if (resultado is Erro<ConsultoraDto>) {
      await _servico.removerFoto(caminho);
      return Erro(resultado.falha);
    }
    if (anterior != null) await _servico.removerFoto(anterior);
    return _publicarResultado(resultado);
  }

  Future<Resultado<Consultora>> removerFoto() async {
    final anterior = _atual?.caminhoFoto;
    final resultado = await _servico.atualizarFoto(null);
    if (resultado is Sucesso<ConsultoraDto> && anterior != null) {
      await _servico.removerFoto(anterior);
    }
    return _publicarResultado(resultado);
  }

  /// Esquece a consultora (ao sair da conta).
  void limpar() => _publicar(null);

  Future<Resultado<Consultora>> _publicarResultado(
    Resultado<ConsultoraDto> resultado,
  ) async {
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(_publicar(await _paraModel(valor))!),
    };
  }

  Future<Consultora> _paraModel(ConsultoraDto dto) async {
    final caminho = dto.fotoUrl;
    if (caminho == null) return dto.paraModel();
    final url = await _servico.urlDaFoto(caminho);
    // Sem URL (falha de rede), a tela mostra as iniciais.
    return dto.paraModel(urlFoto: url is Sucesso<String> ? url.valor : null);
  }

  Consultora? _publicar(Consultora? consultora) {
    _atual = consultora;
    _mudancas.add(consultora);
    return consultora;
  }
}
