// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/durabilidade.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Passo 2: resumo do produto, preços, durabilidade e observações.
class PassoPrecos extends StatelessWidget {
  const PassoPrecos({
    super.key,
    required this.estado,
    required this.observacoes,
  });

  final ProdutosFormularioState estado;
  final TextEditingController observacoes;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosFormularioCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResumoProduto(estado: estado),
        const SizedBox(height: 24),
        CampoMoedaApp(
          rotulo: 'Preço de custo',
          opcional: true,
          centavosIniciais: estado.precoCusto ?? 0,
          onChanged: cubit.alterarPrecoCusto,
        ),
        const SizedBox(height: 24),
        CampoMoedaApp(
          rotulo: 'Preço de venda',
          obrigatorio: true,
          centavosIniciais: estado.precoVenda ?? 0,
          erro: estado.erroPrecoVenda,
          onChanged: cubit.alterarPrecoVenda,
        ),
        const SizedBox(height: 24),
        CampoSelecaoApp<int?>(
          rotulo: 'Quanto tempo dura? (Previsão)',
          opcional: true,
          placeholder: Durabilidade.textoSemPrevisao,
          opcoes: const [null, ...Durabilidade.opcoes],
          rotuloDe: (dias) => dias == null
              ? Durabilidade.textoSemPrevisao
              : Durabilidade.texto(dias),
          valor: estado.durabilidadeDias,
          icone: Icons.schedule_rounded,
          onChanged: cubit.alterarDurabilidade,
        ),
        const SizedBox(height: 8),
        const _DicaRecompra(),
        const SizedBox(height: 24),
        AreaTextoApp(
          rotulo: 'Observações / Fragrância',
          opcional: true,
          placeholder: 'Ex: Fragrância floral, acompanha creme acetinado...',
          controller: observacoes,
          onChanged: cubit.alterarObservacoes,
        ),
      ],
    );
  }
}

class _ResumoProduto extends StatelessWidget {
  const _ResumoProduto({required this.estado});

  final ProdutosFormularioState estado;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final detalhes = [
      ?estado.marcaEscolhida?.nome,
      ?estado.categoriaEscolhida?.nome,
    ].join(' • ');
    final preco = estado.precoVenda;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURANDO PRODUTO',
                    style: estilos.labelSmall?.copyWith(
                      color: CoresApp.sobreSuperficieVariante,
                    ),
                  ),
                  Text(estado.nome.trim(), style: estilos.titleMedium),
                  if (detalhes.isNotEmpty)
                    Text(detalhes, style: estilos.bodySmall),
                ],
              ),
            ),
            if (preco != null && preco > 0)
              Text(
                FormatadorMoeda.formatar(preco),
                style: estilos.titleSmall?.copyWith(color: CoresApp.primaria),
              ),
          ],
        ),
      ),
    );
  }
}

class _DicaRecompra extends StatelessWidget {
  const _DicaRecompra();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.tips_and_updates_outlined,
          size: 18,
          color: CoresApp.primaria,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ajuda você a lembrar de oferecer reposição para a cliente na hora certa!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
