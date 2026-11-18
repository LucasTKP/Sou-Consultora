import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_state.dart';

/// Lançamento de boleto em 2 passos: novo ([idBoleto] nulo) ou edição.
/// [fornecedorInicialId] já escolhe a marca (Novo boleto pela lista da marca).
class APagarFormularioCubit extends Cubit<APagarFormularioState> {
  APagarFormularioCubit({
    String? idBoleto,
    this.fornecedorInicialId,
    RepositorioBoletos? boletos,
    RepositorioFornecedores? fornecedores,
  }) : _boletos = boletos ?? injetor<RepositorioBoletos>(),
       _fornecedores = fornecedores ?? injetor<RepositorioFornecedores>(),
       super(APagarFormularioState(idBoleto: idBoleto)) {
    carregar();
  }

  final String? fornecedorInicialId;
  final RepositorioBoletos _boletos;
  final RepositorioFornecedores _fornecedores;

  /// Marcas para o seletor e, na edição, os dados do boleto.
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final marcas = await _fornecedores.carregar();
    if (isClosed) return;
    switch (marcas) {
      case Erro(:final falha):
        emit(
          state.copyWith(carregando: false, erroCarregar: () => falha.mensagem),
        );
        return;
      case Sucesso(:final valor):
        emit(state.copyWith(marcas: valor));
    }
    if (state.editando) {
      await _carregarBoleto();
      return;
    }
    emit(
      state.copyWith(carregando: false, fornecedorId: () => _marcaInicial()),
    );
  }

  /// Na volta do atalho "Cadastrar fornecedor": a marca nova aparece.
  Future<void> recarregarMarcas() async {
    final resultado = await _fornecedores.carregar();
    if (isClosed) return;
    if (resultado case Sucesso(:final valor)) {
      emit(state.copyWith(marcas: valor));
    }
  }

  // —— Passo 1 ——

  void alterarMarca(ResumoFornecedor marca) =>
      emit(state.copyWith(fornecedorId: () => marca.id, erroMarca: () => null));

  void alterarValor(int centavos) =>
      emit(state.copyWith(valor: () => centavos, erroValor: () => null));

  void alterarVencimento(DateTime data) =>
      emit(state.copyWith(vencimento: () => data, erroVencimento: () => null));

  /// Vai ao passo 2 se o passo 1 estiver completo.
  void continuar() {
    if (_validarPasso1()) emit(state.copyWith(passo: 2));
  }

  // —— Passo 2 ——

  void voltar() => emit(state.copyWith(passo: 1));

  /// Null = não informar.
  void alterarForma(FormaPagamentoBoleto? forma) =>
      emit(state.copyWith(forma: () => forma));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> salvar() async {
    // O passo 1 já foi validado ao continuar; repete por garantia.
    if (state.salvando || !_validarPasso1()) return;
    emit(state.copyWith(salvando: true));
    final texto = state.observacoes.trim();
    final resultado = await _boletos.salvar(
      PedidoBoleto(
        fornecedorId: state.fornecedorId!,
        valor: state.valor!,
        vencimento: state.vencimento!,
        forma: state.forma,
        observacoes: texto.isEmpty ? null : texto,
      ),
      id: state.idBoleto,
    );
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(salvando: false, aviso: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  /// A marca pedida, se estiver ativa.
  String? _marcaInicial() {
    final id = fornecedorInicialId;
    if (id == null) return null;
    final ativa = state.marcas.any((m) => m.id == id && m.ativo);
    return ativa ? id : null;
  }

  Future<void> _carregarBoleto() async {
    final resultado = await _boletos.buscar(state.idBoleto!);
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
            erroCarregar: () => 'Boleto não encontrado.',
          ),
        );
      case Sucesso(valor: final ResumoBoleto boleto):
        _preencher(boleto);
    }
  }

  void _preencher(ResumoBoleto boleto) {
    emit(
      state.copyWith(
        carregando: false,
        fornecedorId: () => boleto.fornecedorId,
        fornecedorIdOriginal: () => boleto.fornecedorId,
        valor: () => boleto.valor,
        vencimento: () => boleto.vencimento,
        forma: () => boleto.forma,
        observacoes: boleto.observacoes ?? '',
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }

  bool _validarPasso1() {
    final erroMarca = PedidoBoleto.validarFornecedor(state.fornecedorId);
    final erroValor = PedidoBoleto.validarValor(state.valor);
    final erroVencimento = PedidoBoleto.validarVencimento(state.vencimento);
    emit(
      state.copyWith(
        erroMarca: () => erroMarca,
        erroValor: () => erroValor,
        erroVencimento: () => erroVencimento,
      ),
    );
    return erroMarca == null && erroValor == null && erroVencimento == null;
  }
}
