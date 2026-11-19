// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_state.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/widgets/passo_dados.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/widgets/passo_precos.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_foto_app.dart';
import 'package:sou_consultora/ui/widgets/dicas/passo_de_dica.dart';
import 'package:sou_consultora/ui/widgets/dicas/roteiro_dicas.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

/// Novo produto ([idProduto] nulo) ou edição, em 2 passos.
/// Ao salvar, fecha devolvendo `true`.
class ProdutosFormularioScreen extends StatelessWidget {
  const ProdutosFormularioScreen({super.key, this.idProduto});

  final String? idProduto;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProdutosFormularioCubit(idProduto: idProduto),
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
  // Ficam aqui (e não nos passos) para não perder o texto ao trocar de passo.
  final _nome = TextEditingController();
  final _codigo = TextEditingController();
  final _observacoes = TextEditingController();

  // Passo a passo da primeira vez (só no produto novo e uma vez só).
  final _chaveImportar = GlobalKey();
  final _chaveContinuar = GlobalKey();
  late final RoteiroDicas _dicaImportar;
  late final RoteiroDicas _dicaContinuar;

  @override
  void initState() {
    super.initState();
    // Precisam existir antes de os PassoDeDica serem montados.
    _dicaImportar = RoteiroDicas(DicaApp.importarNoFormulario);
    _dicaContinuar = RoteiroDicas(DicaApp.continuarAposImportar);
  }

  @override
  void dispose() {
    _dicaImportar.encerrar();
    _dicaContinuar.encerrar();
    _nome.dispose();
    _codigo.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  ProdutosFormularioCubit get _cubit => context.read<ProdutosFormularioCubit>();

  /// Copia para os campos o que o cubit carregou (edição).
  void _copiarParaCampos(ProdutosFormularioState estado) {
    _nome.text = estado.nome;
    _codigo.text = estado.codigo;
    _observacoes.text = estado.observacoes;
  }

  void _aoMudarEstado(BuildContext context, ProdutosFormularioState estado) {
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

  Future<void> _escolherFoto() async {
    final acao = await FolhaFotoApp.mostrar(
      context,
      titulo: 'Foto do Produto',
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

  Future<void> _importar() async {
    final item = await context.push<ProdutoCatalogo>(RotasApp.importarProduto);
    if (item == null || !mounted) return;
    await _cubit.importar(item);
    // Já preenchido: mostra o que falta (só na primeira vez).
    if (mounted) _dicaContinuar.iniciar([_chaveContinuar], () => mounted);
  }

  /// Ao abrir um produto novo, apresenta o botão de importar (só na primeira vez).
  void _aoCarregar(BuildContext context, ProdutosFormularioState estado) {
    if (estado.editando || estado.erroCarregar != null) return;
    _dicaImportar.iniciar([_chaveImportar], () => mounted);
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
        BlocListener<ProdutosFormularioCubit, ProdutosFormularioState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _copiarParaCampos(estado),
        ),
        BlocListener<ProdutosFormularioCubit, ProdutosFormularioState>(
          listenWhen: (antes, depois) => antes.carregando && !depois.carregando,
          listener: _aoCarregar,
        ),
        BlocListener<ProdutosFormularioCubit, ProdutosFormularioState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
      ],
      child: BlocBuilder<ProdutosFormularioCubit, ProdutosFormularioState>(
        builder: (context, estado) => PopScope(
          canPop: estado.passo == 1,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) _cubit.voltar();
          },
          child: Scaffold(
            body: Column(
              children: [
                CabecalhoApp(
                  titulo: estado.editando ? 'Editar Produto' : 'Novo Produto',
                  subtitulo:
                      'Passo ${estado.passo} de ${ProdutosFormularioState.totalPassos}',
                  onVoltar: _voltar,
                ),
                Expanded(child: _corpo(estado)),
                if (!estado.carregando && estado.erroCarregar == null)
                  _Rodape(
                    estado: estado,
                    onImportar: _importar,
                    chaveImportar: _chaveImportar,
                    chaveContinuar: _chaveContinuar,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(ProdutosFormularioState estado) {
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
          PassoDados(
            estado: estado,
            nome: _nome,
            codigo: _codigo,
            onFoto: _escolherFoto,
            onNovaMarca: _novaMarca,
          )
        else
          PassoPrecos(estado: estado, observacoes: _observacoes),
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.estado,
    required this.onImportar,
    required this.chaveImportar,
    required this.chaveContinuar,
  });

  final ProdutosFormularioState estado;
  final VoidCallback onImportar;

  /// Alvos do passo a passo da primeira vez.
  final GlobalKey chaveImportar;
  final GlobalKey chaveContinuar;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosFormularioCubit>();
    final passo1 = estado.passo == 1;
    return SafeArea(
      top: false,
      minimum: EspacosApp.margemRodape,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (passo1 && !estado.editando) ...[
            PassoDeDica(
              chave: chaveImportar,
              dica: DicaApp.importarNoFormulario,
              titulo: 'Cadastre mais rápido',
              descricao:
                  'Importe o produto do catálogo das marcas. Nome, foto, '
                  'marca e categoria já vêm preenchidos.',
              raio: 28,
              child: BotaoApp.secundario(
                rotulo: 'Importar do catálogo',
                iconeFim: const Icon(Icons.download_rounded),
                onPressed: onImportar,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (passo1)
            PassoDeDica(
              chave: chaveContinuar,
              dica: DicaApp.continuarAposImportar,
              titulo: 'Quase pronto!',
              descricao: 'Confira os dados e toque em Continuar para informar o preço.',
              raio: 28,
              child: BotaoApp(
                rotulo: 'Continuar',
                iconeFim: const Icon(Icons.arrow_forward_rounded),
                onPressed: cubit.continuar,
              ),
            )
          else
            BotaoApp(
              rotulo: estado.salvando ? 'Salvando...' : 'Salvar Produto',
              onPressed: estado.salvando ? null : cubit.salvar,
            ),
        ],
      ),
    );
  }
}
