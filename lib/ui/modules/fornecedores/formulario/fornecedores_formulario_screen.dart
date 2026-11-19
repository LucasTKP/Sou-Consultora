// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_state.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Novo fornecedor ([idFornecedor] nulo) ou edição. Ao salvar, fecha devolvendo `true`.
class FornecedoresFormularioScreen extends StatelessWidget {
  const FornecedoresFormularioScreen({super.key, this.idFornecedor});

  final String? idFornecedor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FornecedoresFormularioCubit(idFornecedor: idFornecedor),
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
  final _nome = TextEditingController();
  final _ramo = TextEditingController();
  final _contato = TextEditingController();
  final _telefone = TextEditingController();
  final _observacoes = TextEditingController();

  List<TextEditingController> get _controles => [
    _nome,
    _ramo,
    _contato,
    _telefone,
    _observacoes,
  ];

  @override
  void dispose() {
    for (final controle in _controles) {
      controle.dispose();
    }
    super.dispose();
  }

  /// Copia para os campos o que o cubit carregou (edição).
  void _copiarParaCampos(FornecedoresFormularioState estado) {
    _nome.text = estado.nome;
    _ramo.text = estado.ramo;
    _contato.text = estado.contato;
    _telefone.text = estado.telefone;
    _observacoes.text = estado.observacoes;
  }

  void _aoMudarEstado(
    BuildContext context,
    FornecedoresFormularioState estado,
  ) {
    if (estado.salvo) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<FornecedoresFormularioCubit>().limparAviso();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FornecedoresFormularioCubit, FornecedoresFormularioState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _copiarParaCampos(estado),
        ),
        BlocListener<FornecedoresFormularioCubit, FornecedoresFormularioState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
      ],
      child:
          BlocBuilder<FornecedoresFormularioCubit, FornecedoresFormularioState>(
            builder: (context, estado) => Scaffold(
              body: Column(
                children: [
                  CabecalhoApp(
                    titulo: estado.editando
                        ? 'Editar Fornecedor'
                        : 'Novo Fornecedor',
                    onVoltar: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: _corpo(context, estado)),
                  if (!estado.carregando && estado.erroCarregar == null)
                    _Rodape(estado: estado),
                ],
              ),
            ),
          ),
    );
  }

  Widget _corpo(BuildContext context, FornecedoresFormularioState estado) {
    if (estado.carregando) {
      return const EstadoCarregandoApp(mensagem: 'Carregando dados...');
    }
    final erro = estado.erroCarregar;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<FornecedoresFormularioCubit>().carregar,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: _campos(context, estado),
    );
  }

  List<Widget> _campos(
    BuildContext context,
    FornecedoresFormularioState estado,
  ) {
    final cubit = context.read<FornecedoresFormularioCubit>();
    return [
      CampoTextoApp(
        rotulo: 'Nome da marca / fornecedor',
        obrigatorio: true,
        placeholder: 'Ex: Natura, Boticário, Avon',
        controller: _nome,
        erro: estado.erroNome,
        onChanged: cubit.alterarNome,
        capitalizacao: TextCapitalization.words,
        acaoTeclado: TextInputAction.next,
        leading: const Icon(Icons.storefront_outlined),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Ramo',
        opcional: true,
        placeholder: 'Ex: Cosméticos e perfumaria',
        controller: _ramo,
        onChanged: cubit.alterarRamo,
        capitalizacao: TextCapitalization.sentences,
        acaoTeclado: TextInputAction.next,
        leading: const Icon(Icons.category_outlined),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Contato / representante',
        opcional: true,
        placeholder: 'Ex: Mariana - Supervisora',
        controller: _contato,
        onChanged: cubit.alterarContato,
        capitalizacao: TextCapitalization.words,
        acaoTeclado: TextInputAction.next,
        leading: const Icon(Icons.person_outline_rounded),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Telefone / WhatsApp',
        opcional: true,
        placeholder: 'Ex: (11) 98765-4321',
        controller: _telefone,
        erro: estado.erroTelefone,
        teclado: TextInputType.phone,
        formatadores: [MascaraTelefone()],
        onChanged: cubit.alterarTelefone,
        leading: const Icon(Icons.phone_outlined),
      ),
      const SizedBox(height: 24),
      AreaTextoApp(
        rotulo: 'Observações',
        opcional: true,
        placeholder: 'Ex: Fechamento de ciclo às terças, pedido mínimo...',
        controller: _observacoes,
        onChanged: cubit.alterarObservacoes,
      ),
      if (estado.editando) ...[
        const SizedBox(height: 24),
        InterruptorApp(
          rotulo: 'Em espera',
          descricao: 'Para deixar de usar a marca sem perder o histórico.',
          valor: estado.emEspera,
          onChanged: cubit.alterarEmEspera,
        ),
      ],
    ];
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.estado});

  final FornecedoresFormularioState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FornecedoresFormularioCubit>();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotaoApp(
            rotulo: estado.salvando ? 'Salvando...' : 'Salvar',
            onPressed: estado.salvando ? null : cubit.salvar,
          ),
          const SizedBox(height: 12),
          BotaoApp.secundario(
            rotulo: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
