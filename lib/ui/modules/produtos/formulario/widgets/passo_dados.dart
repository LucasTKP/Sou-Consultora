// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_state.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/widgets/campo_foto_produto.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Passo 1: foto, nome, marca, categoria e código.
class PassoDados extends StatelessWidget {
  const PassoDados({
    super.key,
    required this.estado,
    required this.nome,
    required this.codigo,
    required this.onFoto,
    required this.onNovaMarca,
  });

  final ProdutosFormularioState estado;
  final TextEditingController nome;
  final TextEditingController codigo;
  final VoidCallback onFoto;
  final VoidCallback onNovaMarca;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosFormularioCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoFotoProduto(
          fotoNova: estado.fotoNova,
          urlFoto: estado.urlFotoVisivel,
          onTap: onFoto,
        ),
        const SizedBox(height: 24),
        CampoTextoApp(
          rotulo: 'Nome do produto',
          obrigatorio: true,
          placeholder: 'Ex: Kit Lily Eau de Parfum 75ml',
          controller: nome,
          erro: estado.erroNome,
          onChanged: cubit.alterarNome,
          capitalizacao: TextCapitalization.sentences,
          acaoTeclado: TextInputAction.next,
          leading: const Icon(Icons.sell_outlined),
        ),
        const SizedBox(height: 24),
        CampoSelecaoApp<ResumoFornecedor>(
          rotulo: 'Marca / Fornecedor',
          obrigatorio: true,
          placeholder: 'Escolha a marca',
          opcoes: estado.marcasDisponiveis,
          rotuloDe: (marca) => marca.nome,
          valor: estado.marcaEscolhida,
          buscavel: true,
          erro: estado.erroMarca,
          icone: Icons.storefront_outlined,
          onChanged: cubit.alterarMarca,
          onAtalho: onNovaMarca,
          dicaAtalho: 'Cadastrar fornecedor',
        ),
        const SizedBox(height: 24),
        CampoSelecaoApp<Categoria>(
          rotulo: 'Categoria',
          obrigatorio: true,
          placeholder: 'Escolha a categoria',
          opcoes: estado.categorias,
          rotuloDe: (categoria) => categoria.nome,
          valor: estado.categoriaEscolhida,
          erro: estado.erroCategoria,
          icone: Icons.category_outlined,
          onChanged: cubit.alterarCategoria,
        ),
        const SizedBox(height: 24),
        CampoTextoApp(
          rotulo: 'Código / Referência',
          opcional: true,
          placeholder: 'Ex: BOT-74892',
          controller: codigo,
          onChanged: cubit.alterarCodigo,
          capitalizacao: TextCapitalization.characters,
          leading: const Icon(Icons.qr_code_2_rounded),
        ),
      ],
    );
  }
}
