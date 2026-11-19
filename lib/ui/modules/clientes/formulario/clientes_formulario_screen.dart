// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/widgets/indicadores/indicador_passos_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Novo cliente ([idCliente] nulo) ou edição. Ao salvar, fecha devolvendo `true`.
class ClientesFormularioScreen extends StatelessWidget {
  const ClientesFormularioScreen({super.key, this.idCliente});

  final String? idCliente;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientesFormularioCubit(idCliente: idCliente),
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
  final _whatsapp = TextEditingController();
  final _nascimento = TextEditingController();
  final _observacoes = TextEditingController();
  final _cep = TextEditingController();
  final _rua = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _referencia = TextEditingController();
  final _focoNumero = FocusNode();

  List<TextEditingController> get _controles => [
    _nome,
    _whatsapp,
    _nascimento,
    _observacoes,
    _cep,
    _rua,
    _numero,
    _complemento,
    _bairro,
    _cidade,
    _referencia,
  ];

  @override
  void dispose() {
    for (final controle in _controles) {
      controle.dispose();
    }
    _focoNumero.dispose();
    super.dispose();
  }

  /// Copia para os campos o que o cubit preencheu (edição carregada ou CEP).
  void _copiarParaCampos(ClientesFormularioState estado) {
    final endereco = estado.endereco;
    _definir(_nome, estado.nome);
    _definir(_whatsapp, estado.whatsapp);
    _definir(_nascimento, estado.nascimento);
    _definir(_observacoes, estado.observacoes);
    _definir(_cep, MascaraCep.formatar(endereco.cep ?? ''));
    _definir(_rua, endereco.rua);
    _definir(_numero, endereco.numero);
    _definir(_complemento, endereco.complemento);
    _definir(_bairro, endereco.bairro);
    _definir(_cidade, endereco.cidade);
    _definir(_referencia, endereco.referencia);
  }

  void _definir(TextEditingController controle, String? texto) {
    final valor = texto ?? '';
    if (controle.text != valor) controle.text = valor;
  }

  void _aoMudarEstado(BuildContext context, ClientesFormularioState estado) {
    if (estado.salvo) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<ClientesFormularioCubit>().limparAviso();
  }

  void _voltar(BuildContext context, ClientesFormularioState estado) {
    if (estado.passo == 2) {
      context.read<ClientesFormularioCubit>().voltarAoPasso1();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClientesFormularioCubit, ClientesFormularioState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _copiarParaCampos(estado),
        ),
        BlocListener<ClientesFormularioCubit, ClientesFormularioState>(
          listenWhen: (antes, depois) =>
              antes.focarNumero != depois.focarNumero,
          listener: (_, _) => _focoNumero.requestFocus(),
        ),
        BlocListener<ClientesFormularioCubit, ClientesFormularioState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
      ],
      child: BlocBuilder<ClientesFormularioCubit, ClientesFormularioState>(
        builder: (context, estado) => PopScope(
          canPop: estado.passo == 1,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) context.read<ClientesFormularioCubit>().voltarAoPasso1();
          },
          child: Scaffold(
            body: Column(
              children: [
                CabecalhoApp(
                  titulo: estado.editando ? 'Editar Cliente' : 'Novo Cliente',
                  onVoltar: () => _voltar(context, estado),
                ),
                Expanded(child: _corpo(context, estado)),
                if (!estado.carregando && estado.erroCarregar == null)
                  _Rodape(estado: estado),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context, ClientesFormularioState estado) {
    if (estado.carregando) {
      return const EstadoCarregandoApp(mensagem: 'Carregando dados...');
    }
    final erro = estado.erroCarregar;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ClientesFormularioCubit>().carregar,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        IndicadorPassosApp(
          passoAtual: estado.passo,
          totalPassos: 2,
          descricao: estado.passo == 1
              ? 'Dados da cliente'
              : 'Endereço (opcional)',
        ),
        const SizedBox(height: 20),
        if (estado.passo == 1)
          ..._passo1(context, estado)
        else
          ..._passo2(context, estado),
      ],
    );
  }

  List<Widget> _passo1(BuildContext context, ClientesFormularioState estado) {
    final cubit = context.read<ClientesFormularioCubit>();
    return [
      const _Dica(
        icone: Icons.volunteer_activism_outlined,
        texto: 'Cadastre os dados principais para gerenciar vendas, preferências e cobranças.',
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Nome completo da cliente',
        obrigatorio: true,
        placeholder: 'Ex: Mariana Silveira',
        controller: _nome,
        erro: estado.erroNome,
        onChanged: cubit.alterarNome,
        capitalizacao: TextCapitalization.words,
        acaoTeclado: TextInputAction.next,
        leading: const Icon(Icons.person_outline_rounded),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'WhatsApp com DDD',
        obrigatorio: true,
        placeholder: 'Ex: (11) 98765-4321',
        controller: _whatsapp,
        erro: estado.erroWhatsapp,
        teclado: TextInputType.phone,
        formatadores: [MascaraTelefone()],
        onChanged: cubit.alterarWhatsapp,
        acaoTeclado: TextInputAction.next,
        leading: const Icon(Icons.chat_outlined),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Data de nascimento',
        opcional: true,
        placeholder: 'DD/MM/AAAA',
        controller: _nascimento,
        erro: estado.erroNascimento,
        teclado: TextInputType.number,
        formatadores: [MascaraData()],
        onChanged: cubit.alterarNascimento,
        leading: const Icon(Icons.cake_outlined),
      ),
      const SizedBox(height: 24),
      AreaTextoApp(
        rotulo: 'Observações ou preferências',
        opcional: true,
        placeholder: 'Ex: Prefere fragrâncias florais, alérgica a toques doces, melhor horário...',
        controller: _observacoes,
        onChanged: cubit.alterarObservacoes,
      ),
    ];
  }

  List<Widget> _passo2(BuildContext context, ClientesFormularioState estado) {
    final cubit = context.read<ClientesFormularioCubit>();
    return [
      const _Dica(
        icone: Icons.local_shipping_outlined,
        texto: 'Facilite suas entregas: o endereço facilita a entrega dos pedidos.',
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'CEP',
        placeholder: '00000-000',
        controller: _cep,
        erro: estado.erroCep,
        teclado: TextInputType.number,
        formatadores: [MascaraCep()],
        onChanged: cubit.alterarCep,
        leading: const Icon(Icons.search_rounded),
        trailing: estado.buscandoCep
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Endereço (Rua / Avenida)',
        placeholder: 'Ex: Rua das Flores',
        controller: _rua,
        erro: estado.erroRua,
        onChanged: cubit.alterarRua,
        capitalizacao: TextCapitalization.words,
        leading: const Icon(Icons.home_outlined),
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: CampoTextoApp(
              rotulo: 'Número',
              placeholder: '123',
              controller: _numero,
              focusNode: _focoNumero,
              erro: estado.erroNumero,
              onChanged: cubit.alterarNumero,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CampoTextoApp(
              rotulo: 'Complemento',
              opcional: true,
              placeholder: 'Apto, Bloco, Casa 2',
              controller: _complemento,
              onChanged: cubit.alterarComplemento,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Bairro',
        placeholder: 'Ex: Centro',
        controller: _bairro,
        onChanged: cubit.alterarBairro,
        capitalizacao: TextCapitalization.words,
        leading: const Icon(Icons.holiday_village_outlined),
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Cidade',
        placeholder: 'Ex: São Paulo',
        controller: _cidade,
        onChanged: cubit.alterarCidade,
        capitalizacao: TextCapitalization.words,
        leading: const Icon(Icons.location_city_outlined),
      ),
      const SizedBox(height: 24),
      CampoSelecaoApp<String>(
        rotulo: 'Estado / UF',
        opcoes: Endereco.ufs,
        rotuloDe: (uf) => uf,
        valor: estado.endereco.uf,
        icone: Icons.map_outlined,
        buscavel: true,
        onChanged: cubit.alterarUf,
      ),
      const SizedBox(height: 24),
      CampoTextoApp(
        rotulo: 'Ponto de referência',
        opcional: true,
        placeholder: 'Ex: Próximo à padaria São Jorge',
        controller: _referencia,
        onChanged: cubit.alterarReferencia,
        leading: const Icon(Icons.near_me_outlined),
      ),
    ];
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.estado});

  final ClientesFormularioState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientesFormularioCubit>();
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
              rotulo: estado.salvando ? 'Salvando...' : 'Salvar Cliente',
              onPressed: estado.salvando ? null : cubit.salvar,
            ),
    );
  }
}

/// Faixa de orientação no topo de cada passo.
class _Dica extends StatelessWidget {
  const _Dica({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icone, color: CoresApp.primaria, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
