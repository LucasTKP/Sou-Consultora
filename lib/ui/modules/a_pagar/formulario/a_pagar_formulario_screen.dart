// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_state.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/widgets/passo_dados_boleto.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/widgets/passo_pagamento_boleto.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Novo boleto ([idBoleto] nulo) ou edição, em 2 passos.
/// Ao salvar, fecha devolvendo `true`.
class APagarFormularioScreen extends StatelessWidget {
  const APagarFormularioScreen({
    super.key,
    this.idBoleto,
    this.fornecedorInicialId,
  });

  final String? idBoleto;

  /// Marca já escolhida (Novo boleto pela lista de uma marca).
  final String? fornecedorInicialId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => APagarFormularioCubit(
        idBoleto: idBoleto,
        fornecedorInicialId: fornecedorInicialId,
      ),
      child: const _FormularioVista(),
    );
  }
}

class _FormularioVista extends StatefulWidget {
  const _FormularioVista();

  @override
  State<_FormularioVista> createState() => _FormularioVistaState();
}

class _FormularioVistaState extends State<_FormularioVista> {
  // Fica aqui (e não no passo) para não perder o texto ao trocar de passo.
  final _observacoes = TextEditingController();

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  APagarFormularioCubit get _cubit => context.read<APagarFormularioCubit>();

  void _aoMudarEstado(BuildContext context, APagarFormularioState estado) {
    if (estado.salvo) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    _cubit.limparAviso();
  }

  /// No passo 2, a seta e o "voltar" do sistema retornam ao passo 1.
  void _voltar() {
    if (_cubit.state.passo == 2) {
      _cubit.voltar();
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _novaMarca() async {
    await context.push(RotasApp.novoFornecedor);
    if (!mounted) return;
    await _cubit.recarregarMarcas();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<APagarFormularioCubit, APagarFormularioState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _observacoes.text = estado.observacoes,
        ),
        BlocListener<APagarFormularioCubit, APagarFormularioState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
      ],
      child: BlocBuilder<APagarFormularioCubit, APagarFormularioState>(
        builder: (context, estado) => PopScope(
          canPop: estado.passo == 1,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) _cubit.voltar();
          },
          child: Scaffold(
            body: Column(
              children: [
                CabecalhoApp(
                  titulo: estado.editando ? 'Editar Boleto' : 'Novo Boleto',
                  subtitulo:
                      'Passo ${estado.passo} de ${APagarFormularioState.totalPassos}',
                  onVoltar: _voltar,
                ),
                Expanded(child: _corpo(estado)),
                if (!estado.carregando && estado.erroCarregar == null)
                  _Rodape(estado: estado),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(APagarFormularioState estado) {
    if (estado.carregando) {
      return const EstadoCarregandoApp(mensagem: 'Carregando dados...');
    }
    final erro = estado.erroCarregar;
    if (erro != null) {
      return EstadoErroApp(mensagem: erro, onTentarNovamente: _cubit.carregar);
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (estado.passo == 1)
          PassoDadosBoleto(estado: estado, onNovaMarca: _novaMarca)
        else
          PassoPagamentoBoleto(estado: estado, observacoes: _observacoes),
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.estado});

  final APagarFormularioState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<APagarFormularioCubit>();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: estado.passo == 1
          ? BotaoApp(
              rotulo: 'Continuar',
              iconeFim: const Icon(Icons.arrow_forward_rounded),
              onPressed: cubit.continuar,
            )
          : BotaoApp(
              rotulo: estado.salvando ? 'Salvando...' : 'Salvar Boleto',
              onPressed: estado.salvando ? null : cubit.salvar,
            ),
    );
  }
}
