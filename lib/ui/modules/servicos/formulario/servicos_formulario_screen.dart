// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/duracao_servico.dart';
import 'package:sou_consultora/core/model/margem.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/formulario/servicos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/servicos/formulario/servicos_formulario_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_foto_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_foto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Cadastrar ([idServico] nulo) ou editar serviço. Ao salvar, fecha devolvendo `true`.
class ServicosFormularioScreen extends StatelessWidget {
  const ServicosFormularioScreen({super.key, this.idServico});

  final String? idServico;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicosFormularioCubit(idServico: idServico),
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
  final _observacoes = TextEditingController();

  ServicosFormularioCubit get _cubit => context.read<ServicosFormularioCubit>();

  @override
  void dispose() {
    _nome.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _copiarParaCampos(ServicosFormularioState estado) {
    _nome.text = estado.nome;
    _observacoes.text = estado.observacoes;
  }

  void _aoMudarEstado(BuildContext context, ServicosFormularioState estado) {
    if (estado.salvo) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    _cubit.limparAviso();
  }

  Future<void> _escolherFoto() async {
    final acao = await FolhaFotoApp.mostrar(
      context,
      titulo: 'Foto do Serviço',
      temFoto: _cubit.state.temFoto,
      descricaoRemover: 'Voltar a exibir o ícone',
    );
    switch (acao) {
      case null:
        return;
      case AcaoFoto.camera:
        await _cubit.escolherFoto(OrigemFoto.camera);
      case AcaoFoto.galeria:
        await _cubit.escolherFoto(OrigemFoto.galeria);
      case AcaoFoto.remover:
        _cubit.removerFoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ServicosFormularioCubit, ServicosFormularioState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _copiarParaCampos(estado),
        ),
        BlocListener<ServicosFormularioCubit, ServicosFormularioState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
      ],
      child: BlocBuilder<ServicosFormularioCubit, ServicosFormularioState>(
        builder: (context, estado) => Scaffold(
          body: Column(
            children: [
              CabecalhoApp(
                titulo: estado.editando
                    ? 'Editar Serviço'
                    : 'Cadastrar Serviço',
                onVoltar: () => Navigator.of(context).pop(),
              ),
              Expanded(child: _corpo(estado)),
              if (!estado.carregando && estado.erroCarregar == null)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: BotaoApp(
                    rotulo: estado.salvando ? 'Salvando...' : 'Salvar Serviço',
                    onPressed: estado.salvando ? null : _cubit.salvar,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corpo(ServicosFormularioState estado) {
    if (estado.carregando) {
      return const EstadoCarregandoApp(mensagem: 'Carregando dados...');
    }
    final erro = estado.erroCarregar;
    if (erro != null) {
      return EstadoErroApp(mensagem: erro, onTentarNovamente: _cubit.carregar);
    }
    final retorno = estado.retorno;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _ComoFunciona(),
        const SizedBox(height: 24),
        CampoFotoApp(
          rotuloAcessivel: 'foto do serviço',
          descricao: 'Opcional • aparece na lista de serviços',
          fotoNova: estado.fotoNova,
          urlFoto: estado.urlFotoVisivel,
          onTap: _escolherFoto,
        ),
        const SizedBox(height: 24),
        CampoTextoApp(
          rotulo: 'Nome do serviço',
          obrigatorio: true,
          placeholder: 'Ex: Maquiagem Social',
          controller: _nome,
          erro: estado.erroNome,
          onChanged: _cubit.alterarNome,
          capitalizacao: TextCapitalization.sentences,
          leading: const Icon(Icons.spa_outlined),
        ),
        const SizedBox(height: 24),
        CampoSelecaoApp<Categoria>(
          rotulo: 'Categoria',
          obrigatorio: true,
          placeholder: 'Escolha a categoria',
          opcoes: estado.categorias,
          rotuloDe: (c) => c.nome,
          valor: estado.categoriaEscolhida,
          erro: estado.erroCategoria,
          icone: Icons.category_outlined,
          onChanged: _cubit.alterarCategoria,
        ),
        const SizedBox(height: 24),
        CampoMoedaApp(
          rotulo: 'Preço de venda / cobrado',
          obrigatorio: true,
          centavosIniciais: estado.preco ?? 0,
          erro: estado.erroPreco,
          onChanged: _cubit.alterarPreco,
        ),
        const SizedBox(height: 24),
        CampoMoedaApp(
          rotulo: 'Custo de materiais',
          opcional: true,
          centavosIniciais: estado.custo ?? 0,
          onChanged: _cubit.alterarCusto,
        ),
        if (retorno != null) ...[
          const SizedBox(height: 16),
          _CartaoRetorno(retorno: retorno),
        ],
        const SizedBox(height: 24),
        CampoSelecaoApp<int?>(
          rotulo: 'Duração estimada',
          opcional: true,
          placeholder: DuracaoServico.textoSemDuracao,
          opcoes: const [null, ...DuracaoServico.opcoes],
          rotuloDe: (m) => m == null
              ? DuracaoServico.textoSemDuracao
              : DuracaoServico.porExtenso(m),
          valor: estado.duracaoMinutos,
          icone: Icons.schedule_rounded,
          onChanged: _cubit.alterarDuracao,
        ),
        const SizedBox(height: 24),
        AreaTextoApp(
          rotulo: 'Observações',
          opcional: true,
          placeholder: 'Ex: Inclui cílios postiços e preparação de pele...',
          controller: _observacoes,
          onChanged: _cubit.alterarObservacoes,
        ),
      ],
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como funciona',
              style: estilos.titleSmall?.copyWith(color: CoresApp.primaria),
            ),
            const SizedBox(height: 4),
            Text(
              'Cadastre os procedimentos e atendimentos oferecidos. '
              'O lucro líquido é calculado deduzindo o custo de materiais.',
              style: estilos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoRetorno extends StatelessWidget {
  const _CartaoRetorno({required this.retorno});

  final Margem retorno;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final porcentagem = retorno.porcentagem.round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.sucessoContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.monetization_on_outlined, color: CoresApp.sucesso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Retorno estimado:',
                style: estilos.titleSmall?.copyWith(color: CoresApp.sucesso),
              ),
            ),
            Text(
              '${FormatadorMoeda.formatar(retorno.valor)} ($porcentagem%)',
              style: estilos.titleSmall?.copyWith(color: CoresApp.sucesso),
            ),
          ],
        ),
      ),
    );
  }
}
