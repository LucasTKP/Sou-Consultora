// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_state.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Passo 1: marca (com atalho para cadastrar), valor e vencimento.
class PassoDadosBoleto extends StatelessWidget {
  const PassoDadosBoleto({
    super.key,
    required this.estado,
    required this.onNovaMarca,
  });

  final APagarFormularioState estado;
  final VoidCallback onNovaMarca;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<APagarFormularioCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoSelecaoApp<ResumoFornecedor>(
          rotulo: 'Fornecedor / Marca',
          obrigatorio: true,
          placeholder: 'Selecione a marca ou distribuidora',
          opcoes: estado.marcasDisponiveis,
          rotuloDe: (marca) => marca.nome,
          valor: estado.marcaEscolhida,
          buscavel: true,
          erro: estado.erroMarca,
          icone: Icons.storefront_outlined,
          onChanged: cubit.alterarMarca,
          onCadastrar: onNovaMarca,
          rotuloCadastrar: 'Cadastrar fornecedor',
        ),
        const SizedBox(height: 24),
        CampoMoedaApp(
          rotulo: 'Valor do boleto',
          obrigatorio: true,
          centavosIniciais: estado.valor ?? 0,
          erro: estado.erroValor,
          onChanged: cubit.alterarValor,
        ),
        const SizedBox(height: 24),
        CampoDataApp(
          rotulo: 'Data de Vencimento',
          obrigatorio: true,
          data: estado.vencimento,
          erro: estado.erroVencimento,
          onChanged: cubit.alterarVencimento,
        ),
      ],
    );
  }
}
