import 'dart:async';
import 'dart:typed_data';

import 'package:sou_consultora/core/dto/resumo_servico_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/servico.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/core/repository/gravacao_com_foto.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';
import 'package:sou_consultora/core/service/servico_servicos.dart';

/// Serviços da consultora logada.
///
/// Guarda a última lista carregada (com as URLs das fotos) e avisa em
/// [mudancas] sempre que ela muda. Esquece tudo quando a sessão termina.
class RepositorioServicos {
  RepositorioServicos({
    required this._servico,
    required this._fotos,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoServicos _servico;
  final ServicoFotoDispositivo _fotos;
  final _mudancas = StreamController<List<ResumoServico>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoServico>? _lista;

  /// Última lista carregada (null se ainda não carregou).
  List<ResumoServico>? get lista => _lista;
  Stream<List<ResumoServico>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoServico>>> carregar() async {
    final resultado = await _servico.listarResumos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(_publicar(await _comFotos(valor))),
    };
  }

  /// Resumo atualizado de um serviço (Sucesso(null) se não existir).
  Future<Resultado<ResumoServico?>> buscarResumo(String id) async {
    final resultado = await _servico.buscarResumo(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(valor: null) => const Sucesso(null),
      Sucesso(:final valor?) => Sucesso((await _comFotos([valor])).first),
    };
  }

  /// Resumo já carregado na lista (para abrir os detalhes sem esperar a rede).
  ResumoServico? resumoEmCache(String id) {
    for (final servico in _lista ?? const <ResumoServico>[]) {
      if (servico.id == id) return servico;
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
    Servico servico, {
    String? id,
    MudancaFoto foto = const ManterFoto(),
  }) async {
    final resultado = await gravarComFoto(
      caminhoAnterior: servico.caminhoFoto,
      foto: foto,
      enviar: _servico.enviarFoto,
      remover: _servico.removerFoto,
      gravar: (caminho) => id == null
          ? _servico.criar(servico.comFoto(caminho))
          : _servico.atualizar(id, servico.comFoto(caminho)),
    );
    if (resultado is Erro<String>) return resultado;
    // A gravação já valeu; se recarregar falhar, a lista atualiza na próxima abertura.
    await carregar();
    return resultado;
  }

  /// Esquece os serviços (ao sair da conta).
  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  Future<List<ResumoServico>> _comFotos(List<ResumoServicoDto> dtos) async {
    final caminhos = [for (final dto in dtos) ?dto.fotoUrl];
    final urls = switch (await _servico.urlsDasFotos(caminhos)) {
      Sucesso(:final valor) => valor,
      // Sem as URLs a lista ainda funciona: o card mostra o ícone de reserva.
      Erro() => const <String, String>{},
    };
    return [for (final dto in dtos) dto.paraModel(urlFoto: urls[dto.fotoUrl])];
  }

  List<ResumoServico> _publicar(List<ResumoServico> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
