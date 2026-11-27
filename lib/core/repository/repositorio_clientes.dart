import 'dart:async';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/model/telefone.dart';
import 'package:sou_consultora/core/service/servico_cep.dart';
import 'package:sou_consultora/core/service/servico_clientes.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

/// Carteira de clientes da consultora logada.
///
/// Guarda a última lista carregada e avisa em [mudancas] sempre que ela muda
/// (carregar, salvar). Esquece tudo quando a sessão termina ([sessaoEncerrada]).
class RepositorioClientes {
  RepositorioClientes({
    required this._servico,
    required this._cep,
    required this._whatsapp,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoClientes _servico;
  final ServicoCep _cep;
  final ServicoWhatsapp _whatsapp;
  final _mudancas = StreamController<List<ResumoCliente>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoCliente>? _lista;

  /// Última lista carregada (null se ainda não carregou).
  List<ResumoCliente>? get lista => _lista;
  Stream<List<ResumoCliente>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoCliente>>> carregar() async {
    final resultado = await _servico.listarResumos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _publicar(valor.map((dto) => dto.paraModel()).toList()),
      ),
    };
  }

  /// Resumo atualizado de uma cliente (Sucesso(null) se não existir).
  Future<Resultado<ResumoCliente?>> buscarResumo(String id) async {
    final resultado = await _servico.buscarResumo(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(valor?.paraModel()),
    };
  }

  /// Resumo já carregado na lista (para abrir os detalhes sem esperar a rede).
  ResumoCliente? resumoEmCache(String id) {
    for (final cliente in _lista ?? const <ResumoCliente>[]) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  Future<Resultado<Cliente?>> buscarCliente(String id) async {
    final resultado = await _servico.buscarCliente(id);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(valor?.paraModel()),
    };
  }

  /// Cria ([id] nulo) ou edita. Em sucesso, recarrega a lista e devolve o id.
  Future<Resultado<String>> salvar({
    String? id,
    required String nome,
    required String whatsapp,
    DateTime? dataNascimento,
    String? observacoes,
    Endereco? endereco,
  }) async {
    final resultado = await _servico.salvar(
      id: id,
      nome: nome.trim(),
      whatsapp: Telefone.digitos(whatsapp),
      dataNascimento: dataNascimento,
      observacoes: observacoes,
      endereco: endereco?.paraGravar(),
    );
    // A gravação já valeu; se recarregar falhar, a lista atualiza na próxima abertura.
    if (resultado is Sucesso<String>) await carregar();
    return resultado;
  }

  Future<Resultado<Endereco?>> buscarCep(String cep) => _cep.buscar(cep);

  Future<Resultado<void>> abrirWhatsapp(String whatsapp) =>
      _whatsapp.abrirConversa(whatsapp);

  /// Esquece as clientes (ao sair da conta).
  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  List<ResumoCliente> _publicar(List<ResumoCliente> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
