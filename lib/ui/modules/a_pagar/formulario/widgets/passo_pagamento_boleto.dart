// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Passo 2: confere marca, vencimento e valor; forma e observação opcionais.
class PassoPagamentoBoleto extends StatelessWidget {
  const PassoPagamentoBoleto({
    super.key,
    required this.estado,
    required this.observacoes,
  });

  final APagarFormularioState estado;
  final TextEditingController observacoes;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<APagarFormularioCubit>();
    final marca = estado.marcaEscolhida;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Conferencia(
          marca: marca,
          vencimento: estado.vencimento!,
          valor: estado.valor!,
        ),
        const SizedBox(height: 24),
        CampoSelecaoApp<FormaPagamentoBoleto?>(
          rotulo: 'Forma de pagamento',
          opcional: true,
          placeholder: 'Selecione como pretende pagar...',
          opcoes: const [...FormaPagamentoBoleto.values, null],
          rotuloDe: (forma) => forma?.rotulo ?? 'Não informar',
          valor: estado.forma,
          icone: Icons.payments_outlined,
          onChanged: cubit.alterarForma,
        ),
        const SizedBox(height: 24),
        AreaTextoApp(
          rotulo: 'Observações',
          opcional: true,
          placeholder: 'Ex: Boleto com desconto se pago até dia 20...',
          controller: observacoes,
          onChanged: cubit.alterarObservacoes,
        ),
      ],
    );
  }
}

class _Conferencia extends StatelessWidget {
  const _Conferencia({
    required this.marca,
    required this.vencimento,
    required this.valor,
  });

  final ResumoFornecedor? marca;
  final DateTime vencimento;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final nome = marca?.nome ?? '';
    return CartaoApp(
      filho: Column(
        children: [
          Row(
            children: [
              AvatarApp(
                iniciais: ResumoFornecedor.iniciaisDe(nome),
                tamanho: TamanhoAvatar.card,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(nome, style: estilos.titleMedium)),
              const SeloStatusApp(
                rotulo: 'Confirmado',
                status: StatusSelo.sucesso,
              ),
            ],
          ),
          const Divider(height: 24, color: CoresApp.contorno),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vencimento', style: estilos.bodySmall),
                    Text(
                      FormatadorData.curta(vencimento),
                      style: estilos.bodyLarge,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Valor total', style: estilos.bodySmall),
                  Text(
                    FormatadorMoeda.formatar(valor),
                    style: estilos.titleLarge?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
