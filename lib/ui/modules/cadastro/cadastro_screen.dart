// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/marca_padrao.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_cubit.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CadastroCubit(),
      child: const _CadastroVista(),
    );
  }
}

class _CadastroVista extends StatelessWidget {
  const _CadastroVista();

  void _aoMudarEstado(BuildContext context, CadastroState estado) {
    final mensagem = estado.erroGeral;
    if (mensagem == null) return;
    ToastApp.erro(context, mensagem);
    context.read<CadastroCubit>().limparErroGeral();
  }

  void _aoVoltar(BuildContext context, bool saiu) {
    if (!saiu) context.read<CadastroCubit>().voltar();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CadastroCubit>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) => _aoVoltar(context, saiu),
      child: BlocConsumer<CadastroCubit, CadastroState>(
        listenWhen: (antes, depois) => antes.erroGeral != depois.erroGeral,
        listener: _aoMudarEstado,
        builder: (context, estado) => Scaffold(
          body: Column(
            children: [
              CabecalhoApp(titulo: 'Cadastro', onVoltar: cubit.voltar),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  children: [
                    Text(
                      estado.pedirNome
                          ? 'Vamos começar?'
                          : 'Qual é o seu número?',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: CoresApp.primariaEscura),
                    ),
                    const SizedBox(height: 28),
                    if (estado.pedirNome) ...[
                      CampoTextoApp(
                        rotulo: 'Nome completo',
                        obrigatorio: true,
                        erro: estado.erroNome,
                        onChanged: cubit.alterarNome,
                        capitalizacao: TextCapitalization.words,
                        acaoTeclado: TextInputAction.next,
                        leading: const Icon(Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 24),
                    ],
                    CampoTextoApp(
                      rotulo: 'Número de WhatsApp com DDD',
                      obrigatorio: true,
                      placeholder: '(11) 99999-9999',
                      erro: estado.erroWhatsapp,
                      teclado: TextInputType.phone,
                      formatadores: [MascaraTelefone()],
                      onChanged: cubit.alterarWhatsapp,
                      leading: const Icon(Icons.phone_outlined),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Quais marcas você vende?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opcional. Vamos cadastrar cada uma como fornecedor '
                      'para você.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: CoresApp.sobreSuperficieVariante),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final marca in MarcaPadrao.values)
                          FilterChip(
                            label: Text(marca.nome),
                            selected: estado.marcas.contains(marca),
                            onSelected: estado.salvando
                                ? null
                                : (_) => cubit.alternarMarca(marca),
                            selectedColor: CoresApp.primariaSuave,
                            checkmarkColor: CoresApp.primariaEscura,
                            backgroundColor: CoresApp.superficie,
                            side: BorderSide(
                              color: estado.marcas.contains(marca)
                                  ? CoresApp.primaria
                                  : CoresApp.contorno,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + EspacosApp.folgaInferior,
                ),
                child: BotaoApp(
                  rotulo: estado.salvando ? 'Salvando...' : 'Continuar',
                  iconeFim: const Icon(Icons.arrow_forward_rounded),
                  onPressed: estado.salvando ? null : cubit.continuar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
