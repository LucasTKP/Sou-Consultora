import 'dart:async';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

/// Fornecedores (marcas) da consultora logada.
///
/// Guarda a última lista carregada e avisa em [mudancas] sempre que ela muda
/// (carregar, salvar). Esquece tudo quando a sessão termina ([sessaoEncerrada]).
class RepositorioFornecedores {
  RepositorioFornecedores({
    required this._servico,
    required this._whatsapp,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoFornecedores _servico;
  final ServicoWhatsapp _whatsapp;
  final _mudancas = StreamController<List<ResumoFornecedor>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoFornecedor>? _lista;

  /// Última lista carregada (null se ainda não carregou).
  List<ResumoFornecedor>? get lista => _lista;
  Stream<List<ResumoFornecedor>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoFornecedor>>> carregar() async {
    final resultado = await _servico.listarResumos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _publicar(valor.map((dto) => dto.paraModel()).toList()),
      ),
    };
  }

  /// Resumo atualizado de um fornecedor (Sucesso(null) se não existir).
  Future<Resultado<ResumoFornecedor?>> buscarResumo(String id) async {
    final resultado = await _servico.buscarResumo(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(valor?.paraModel()),
    };
  }

  /// Resumo já carregado na lista (para abrir os detalhes sem esperar a rede).
  ResumoFornecedor? resumoEmCache(String id) {
    for (final fornecedor in _lista ?? const <ResumoFornecedor>[]) {
      if (fornecedor.id == id) return fornecedor;
    }
    return null;
  }

  /// Cria ([id] nulo) ou edita. Em sucesso, recarrega a lista e devolve o id.
  Future<Resultado<String>> salvar(Fornecedor fornecedor, {String? id}) async {
    final resultado = id == null
        ? await _servico.criar(fornecedor)
        : await _servico.atualizar(id, fornecedor);
    // A gravação já valeu; se recarregar falhar, a lista atualiza na próxima abertura.
    if (resultado is Sucesso<String>) await carregar();
    return resultado;
  }

  Future<Resultado<void>> abrirWhatsapp(String telefone) =>
      _whatsapp.abrirConversa(telefone);

  /// Esquece os fornecedores (ao sair da conta).
  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  List<ResumoFornecedor> _publicar(List<ResumoFornecedor> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
