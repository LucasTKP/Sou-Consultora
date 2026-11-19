// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/modules/perfil/editar/editar_perfil_cubit.dart';
import 'package:sou_consultora/ui/modules/perfil/editar/editar_perfil_state.dart';
import 'package:sou_consultora/ui/modules/perfil/widgets/foto_perfil/foto_perfil.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

class EditarPerfilScreen extends StatelessWidget {
  const EditarPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => EditarPerfilCubit(), child: const _EditarPerfilVista());
  }
}

class _EditarPerfilVista extends StatefulWidget {
  const _EditarPerfilVista();

  @override
  State<_EditarPerfilVista> createState() => _EditarPerfilVistaState();
}

class _EditarPerfilVistaState extends State<_EditarPerfilVista> {
  late final EditarPerfilState _inicial = context.read<EditarPerfilCubit>().state;
  late final _nome = TextEditingController(text: _inicial.nome);
  late final _whatsapp = TextEditingController(text: _inicial.whatsapp);
  late final _chave = TextEditingController(text: _inicial.chavePix);

  @override
  void dispose() {
    _nome.dispose();
    _whatsapp.dispose();
    _chave.dispose();
    super.dispose();
  }

  void _aoMudarEstado(BuildContext context, EditarPerfilState estado) {
    // O cubit apaga a chave ao trocar o tipo; o campo acompanha.
    if (_chave.text != estado.chavePix && estado.chavePix.isEmpty) {
      _chave.clear();
    }
    if (estado.salvo) {
      Navigator.of(context).pop();
      return;
    }
    final mensagem = estado.erroGeral;
    if (mensagem == null) return;
    ToastApp.erro(context, mensagem);
    context.read<EditarPerfilCubit>().limparErroGeral();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditarPerfilCubit>();
    return BlocConsumer<EditarPerfilCubit, EditarPerfilState>(
      listener: _aoMudarEstado,
      builder: (context, estado) => Scaffold(
        body: Column(
          children: [
            const CabecalhoApp(titulo: 'Editar Perfil'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: [
                  const Center(child: FotoPerfil(comBotaoAlterar: true)),
                  const SizedBox(height: 32),
                  CampoTextoApp(
                    rotulo: 'Nome completo',
                    obrigatorio: true,
                    controller: _nome,
                    erro: estado.erroNome,
                    onChanged: cubit.alterarNome,
                    capitalizacao: TextCapitalization.words,
                    leading: const Icon(Icons.person_outline_rounded),
                  ),
                  const SizedBox(height: 24),
                  CampoTextoApp(
                    rotulo: 'Telefone / WhatsApp',
                    obrigatorio: true,
                    controller: _whatsapp,
                    erro: estado.erroWhatsapp,
                    teclado: TextInputType.phone,
                    formatadores: [MascaraTelefone()],
                    onChanged: cubit.alterarWhatsapp,
                    leading: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 32),
                  _TituloPix(),
                  const SizedBox(height: 20),
                  CampoSelecaoApp<TipoChavePix>(
                    rotulo: 'Tipo de chave Pix',
                    opcoes: TipoChavePix.values,
                    rotuloDe: (tipo) => tipo.rotulo,
                    valor: estado.tipoPix,
                    erro: estado.erroTipoPix,
                    icone: Icons.tune_rounded,
                    onChanged: cubit.alterarTipoPix,
                  ),
                  const SizedBox(height: 24),
                  CampoTextoApp(
                    rotulo: 'Chave Pix',
                    opcional: true,
                    controller: _chave,
                    erro: estado.erroChavePix,
                    teclado: _tecladoDaChave(estado.tipoPix),
                    formatadores: _mascaraDaChave(estado.tipoPix),
                    onChanged: cubit.alterarChavePix,
                    leading: const Icon(Icons.key_outlined),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: EspacosApp.margemRodape,
              child: BotaoApp(
                rotulo: estado.salvando ? 'Salvando...' : 'Salvar Alterações',
                onPressed: estado.salvando ? null : cubit.salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextInputType _tecladoDaChave(TipoChavePix? tipo) {
    return switch (tipo) {
      TipoChavePix.telefone => TextInputType.phone,
      TipoChavePix.cpf => TextInputType.number,
      TipoChavePix.email => TextInputType.emailAddress,
      _ => TextInputType.text,
    };
  }

  List<TextInputFormatter>? _mascaraDaChave(TipoChavePix? tipo) {
    return tipo == TipoChavePix.telefone ? [MascaraTelefone()] : null;
  }
}

class _TituloPix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSecaoApp(titulo: 'Recebimento via Pix', icone: Icons.qr_code_2_rounded),
        const SizedBox(height: 8),
        Text('Sua chave aparece nos comprovantes enviados às clientes.', style: estilos.bodySmall),
      ],
    );
  }
}
