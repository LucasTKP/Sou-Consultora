// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/model/marca_padrao.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dicas/passo_de_dica.dart';
import 'package:sou_consultora/ui/widgets/dicas/roteiro_dicas.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';

/// Escolhe um produto do catálogo das marcas. Ao tocar, fecha devolvendo o
/// [ProdutoCatalogo] para o cadastro de produto preencher os campos.
class ProdutosImportarScreen extends StatelessWidget {
  const ProdutosImportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProdutosImportarCubit(),
      child: const _ImportarVista(),
    );
  }
}

class _ImportarVista extends StatefulWidget {
  const _ImportarVista();

  @override
  State<_ImportarVista> createState() => _ImportarVistaState();
}

class _ImportarVistaState extends State<_ImportarVista> {
  // Passo a passo da primeira vez: busca → marcas → primeiro produto.
  final _chaveBusca = GlobalKey();
  final _chaveMarcas = GlobalKey();
  final _chavePrimeiro = GlobalKey();
  late final RoteiroDicas _roteiro;

  @override
  void initState() {
    super.initState();
    // Precisa existir antes de os PassoDeDica serem montados.
    _roteiro = RoteiroDicas(DicaApp.importarNaLista);
  }

  @override
  void dispose() {
    _roteiro.encerrar();
    super.dispose();
  }

  /// Começa quando a lista aparece pela primeira vez (há um produto para apontar).
  void _aoCarregar(BuildContext context, ProdutosImportarState estado) {
    _roteiro.iniciar([
      _chaveBusca,
      _chaveMarcas,
      _chavePrimeiro,
    ], () => mounted);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosImportarCubit>();
    return BlocListener<ProdutosImportarCubit, ProdutosImportarState>(
      listenWhen: (antes, depois) =>
          antes.carregando &&
          !depois.carregando &&
          depois.erro == null &&
          depois.itens.isNotEmpty,
      listener: _aoCarregar,
      child: Scaffold(
        body: Column(
          children: [
            const CabecalhoApp(titulo: 'Importar do catálogo'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: PassoDeDica(
                chave: _chaveBusca,
                dica: DicaApp.importarNaLista,
                titulo: 'Busque pelo nome',
                descricao: 'Digite parte do nome ou do código do produto.',
                child: CampoBuscaApp(
                  placeholder: 'Buscar por nome...',
                  onChanged: cubit.alterarBusca,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FiltroMarca(chave: _chaveMarcas),
            const SizedBox(height: 4),
            Expanded(child: _Lista(chavePrimeiro: _chavePrimeiro)),
          ],
        ),
      ),
    );
  }
}

class _FiltroMarca extends StatelessWidget {
  const _FiltroMarca({required this.chave});

  final GlobalKey chave;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosImportarCubit>();
    final escolhida = context.select<ProdutosImportarCubit, String?>(
      (c) => c.state.marca,
    );
    final chips = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            rotulo: 'Todas',
            selecionado: escolhida == null,
            onTap: () => cubit.alterarMarca(null),
          ),
          for (final marca in MarcaPadrao.values)
            _Chip(
              rotulo: marca.nome,
              selecionado: escolhida == marca.nome,
              onTap: () => cubit.alterarMarca(marca.nome),
            ),
        ],
      ),
    );
    return PassoDeDica(
      chave: chave,
      dica: DicaApp.importarNaLista,
      titulo: 'Filtre pela marca',
      descricao:
          'Escolha Natura, Avon, O Boticário, Eudora, Mary Kay ou Tupperware.',
      raio: 12,
      child: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: (_) => onTap(),
        selectedColor: CoresApp.primariaSuave,
        backgroundColor: CoresApp.superficie,
        side: BorderSide(
          color: selecionado ? CoresApp.primaria : CoresApp.contorno,
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.chavePrimeiro});

  /// Destaca o primeiro produto no passo a passo da primeira vez.
  final GlobalKey chavePrimeiro;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosImportarCubit>();
    return BlocBuilder<ProdutosImportarCubit, ProdutosImportarState>(
      builder: (context, estado) {
        if (estado.carregando && estado.itens.isEmpty) {
          return const EstadoCarregandoApp(mensagem: 'Carregando catálogo...');
        }
        if (estado.erro case final erro?) {
          return EstadoErroApp(
            mensagem: erro,
            onTentarNovamente: cubit.carregar,
          );
        }
        if (estado.itens.isEmpty) {
          return const EstadoVazioApp(
            titulo: 'Nenhum produto encontrado',
            mensagem: 'Tente outro nome ou outra marca.',
            icone: Icons.search_off_rounded,
          );
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            for (final (indice, produto) in estado.itens.indexed) ...[
              if (indice == 0)
                PassoDeDica(
                  chave: chavePrimeiro,
                  dica: DicaApp.importarNaLista,
                  titulo: 'Toque no produto',
                  descricao:
                      'Escolha o que você vende e volte ao cadastro com tudo '
                      'preenchido.',
                  child: _CartaoCatalogo(
                    produto: produto,
                    jaTem: estado.jaTem(produto),
                  ),
                )
              else
                _CartaoCatalogo(produto: produto, jaTem: estado.jaTem(produto)),
              const SizedBox(height: 12),
            ],
            if (estado.possivelTerMais)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Mostrando os primeiros ${ProdutosImportarState.limite}. '
                  'Refine a busca para ver outros.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartaoCatalogo extends StatelessWidget {
  const _CartaoCatalogo({required this.produto, required this.jaTem});

  final ProdutoCatalogo produto;

  /// A consultora já cadastrou este produto: não deixa importar de novo.
  final bool jaTem;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: produto.nome,
      subtitulo: '${produto.marca} · Cód. ${produto.codigo}',
      inicio: FotoQuadradaApp(url: produto.urlFoto),
      selo: jaTem
          ? const SeloStatusApp(
              rotulo: 'Já cadastrado',
              status: StatusSelo.sucesso,
            )
          : null,
      mostrarSeta: !jaTem,
      onTap: () => jaTem
          ? ToastApp.mostrar(
              context,
              const AvisoToast.aviso('Você já tem este produto cadastrado.'),
            )
          : context.pop(produto),
    );
  }
}
