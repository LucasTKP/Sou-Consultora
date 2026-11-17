import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_state.dart';

/// Novo cliente ([idCliente] nulo) ou edição, nos dois passos.
class ClientesFormularioCubit extends Cubit<ClientesFormularioState> {
  ClientesFormularioCubit({
    String? idCliente,
    RepositorioClientes? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioClientes>(),
       _agora = agora ?? DateTime.now,
       super(
         ClientesFormularioState(
           idCliente: idCliente,
           carregando: idCliente != null,
         ),
       ) {
    if (idCliente != null) carregar();
  }

  final RepositorioClientes _repositorio;
  final DateTime Function() _agora;
  String? _ultimoCepBuscado;

  /// Edição: preenche com os dados atuais da cliente.
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final resultado = await _repositorio.buscarCliente(state.idCliente!);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(carregando: false, erroCarregar: () => falha.mensagem),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erroCarregar: () => 'Cliente não encontrada.',
          ),
        );
      case Sucesso(valor: final Cliente cliente):
        _preencher(cliente);
    }
  }

  void alterarNome(String texto) =>
      emit(state.copyWith(nome: texto, erroNome: () => null));

  void alterarWhatsapp(String texto) =>
      emit(state.copyWith(whatsapp: texto, erroWhatsapp: () => null));

  void alterarNascimento(String texto) =>
      emit(state.copyWith(nascimento: texto, erroNascimento: () => null));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  void alterarRua(String texto) =>
      _alterarEndereco(_copiaEndereco(rua: texto), limparRua: true);

  void alterarNumero(String texto) =>
      _alterarEndereco(_copiaEndereco(numero: texto), limparNumero: true);

  void alterarComplemento(String texto) =>
      _alterarEndereco(_copiaEndereco(complemento: texto));

  void alterarBairro(String texto) =>
      _alterarEndereco(_copiaEndereco(bairro: texto));

  void alterarCidade(String texto) =>
      _alterarEndereco(_copiaEndereco(cidade: texto));

  void alterarUf(String uf) => _alterarEndereco(_copiaEndereco(uf: uf));

  void alterarReferencia(String texto) =>
      _alterarEndereco(_copiaEndereco(referencia: texto));

  /// Guarda o CEP e, com 8 dígitos, preenche rua, bairro, cidade e UF.
  Future<void> alterarCep(String texto) async {
    emit(
      state.copyWith(
        endereco: _copiaEndereco(cep: texto),
        erroCep: () => null,
      ),
    );
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8 || digitos == _ultimoCepBuscado) return;
    _ultimoCepBuscado = digitos;

    emit(state.copyWith(buscandoCep: true));
    final resultado = await _repositorio.buscarCep(digitos);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(buscandoCep: false, aviso: () => falha.mensagem));
      case Sucesso(valor: null):
        emit(
          state.copyWith(buscandoCep: false, aviso: () => 'CEP não encontrado'),
        );
      case Sucesso(valor: final Endereco encontrado):
        _aplicarCep(encontrado);
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  /// Passo 1 → 2, se nome, WhatsApp e nascimento forem válidos.
  void continuar() {
    if (_validarPasso1()) emit(state.copyWith(passo: 2));
  }

  void voltarAoPasso1() => emit(state.copyWith(passo: 1));

  Future<void> salvar() async {
    if (state.salvando) return;
    if (!_validarPasso1()) {
      emit(state.copyWith(passo: 1));
      return;
    }
    if (!_validarEndereco()) return;

    emit(state.copyWith(salvando: true));
    final resultado = await _repositorio.salvar(
      id: state.idCliente,
      nome: state.nome,
      whatsapp: state.whatsapp,
      dataNascimento: FormatadorData.ler(state.nascimento.trim()),
      observacoes: state.observacoes,
      endereco: state.endereco,
    );
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(salvando: false, aviso: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  bool _validarPasso1() {
    final texto = state.nascimento.trim();
    final erroNome = Cliente.validarNome(state.nome);
    final erroWhatsapp = Cliente.validarWhatsapp(state.whatsapp);
    final erroNascimento = Cliente.validarNascimento(
      texto,
      FormatadorData.ler(texto),
      hoje: _agora(),
    );
    emit(
      state.copyWith(
        erroNome: () => erroNome,
        erroWhatsapp: () => erroWhatsapp,
        erroNascimento: () => erroNascimento,
      ),
    );
    return erroNome == null && erroWhatsapp == null && erroNascimento == null;
  }

  bool _validarEndereco() {
    final erros = state.endereco.validar();
    emit(
      state.copyWith(
        erroCep: () => erros.cep,
        erroRua: () => erros.rua,
        erroNumero: () => erros.numero,
      ),
    );
    return erros.cep == null && erros.rua == null && erros.numero == null;
  }

  void _preencher(Cliente cliente) {
    final nascimento = cliente.dataNascimento;
    final endereco = cliente.endereco ?? const Endereco();
    _ultimoCepBuscado = endereco.cep;
    emit(
      state.copyWith(
        carregando: false,
        nome: cliente.nome,
        whatsapp: FormatadorTelefone.formatar(cliente.whatsapp),
        nascimento: nascimento == null ? '' : FormatadorData.curta(nascimento),
        observacoes: cliente.observacoes ?? '',
        endereco: endereco,
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }

  /// O que veio do CEP substitui rua, bairro, cidade e UF (só o que veio preenchido).
  void _aplicarCep(Endereco encontrado) {
    emit(
      state.copyWith(
        buscandoCep: false,
        endereco: _copiaEndereco(
          rua: encontrado.rua,
          bairro: encontrado.bairro,
          cidade: encontrado.cidade,
          uf: encontrado.uf,
        ),
        erroRua: () => null,
        versaoPreenchimento: state.versaoPreenchimento + 1,
        focarNumero: state.focarNumero + 1,
      ),
    );
  }

  void _alterarEndereco(
    Endereco endereco, {
    bool limparRua = false,
    bool limparNumero = false,
  }) {
    emit(
      state.copyWith(
        endereco: endereco,
        erroRua: limparRua ? () => null : null,
        erroNumero: limparNumero ? () => null : null,
      ),
    );
  }

  Endereco _copiaEndereco({
    String? cep,
    String? rua,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? uf,
    String? referencia,
  }) {
    final atual = state.endereco;
    return Endereco(
      cep: cep ?? atual.cep,
      rua: rua ?? atual.rua,
      numero: numero ?? atual.numero,
      complemento: complemento ?? atual.complemento,
      bairro: bairro ?? atual.bairro,
      cidade: cidade ?? atual.cidade,
      uf: uf ?? atual.uf,
      referencia: referencia ?? atual.referencia,
    );
  }
}
