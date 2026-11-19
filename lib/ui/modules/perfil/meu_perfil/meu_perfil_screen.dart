// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/ui/formatadores/formatador_chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_cubit.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_state.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/widgets/folha_opcoes_conta.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/widgets/linha_dado_perfil.dart';
import 'package:sou_consultora/ui/modules/perfil/widgets/foto_perfil/foto_perfil.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_icone_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

class MeuPerfilScreen extends StatelessWidget {
  const MeuPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MeuPerfilCubit(),
      child: const _MeuPerfilVista(),
    );
  }
}

class _MeuPerfilVista extends StatelessWidget {
  const _MeuPerfilVista();

  Future<void> _copiarPix(BuildContext context, String chave) async {
    await Clipboard.setData(ClipboardData(text: chave));
    if (!context.mounted) return;
    ToastApp.sucesso(context, 'Chave Pix copiada');
  }

  Future<void> _abrirOpcoes(BuildContext context) async {
    final cubit = context.read<MeuPerfilCubit>();
    final acao = await FolhaOpcoesConta.mostrar(context);
    if (acao == AcaoConta.apagar) {
      // A exclusão é pedida ao suporte pelo WhatsApp, com a mensagem pronta.
      await cubit.pedirParaApagarConta();
      return;
    }
    if (acao != AcaoConta.sair || !context.mounted) return;
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Sair da conta?',
      mensagem: 'Você precisará entrar novamente com Google ou Apple.',
      rotuloConfirmar: 'Sair',
      perigo: true,
    );
    if (confirmou) await cubit.sair();
  }

  void _aoAvisar(BuildContext context, MeuPerfilState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<MeuPerfilCubit>().limparAviso();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeuPerfilCubit, MeuPerfilState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      child: _tela(context),
    );
  }

  Widget _tela(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CabecalhoApp(titulo: 'Meu Perfil'),
          Expanded(
            child: BlocBuilder<MeuPerfilCubit, MeuPerfilState>(
              builder: (context, estado) {
                final consultora = estado.consultora;
                if (consultora == null) return const EstadoCarregandoApp();
                return _conteudo(context, consultora);
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: EspacosApp.margemRodape,
            child: Column(
              children: [
                BotaoApp(
                  rotulo: 'Editar Perfil',
                  onPressed: () => context.push(RotasApp.editarPerfil),
                ),
                const SizedBox(height: 12),
                BotaoApp.secundario(
                  rotulo: 'Mais opções',
                  onPressed: () => _abrirOpcoes(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(BuildContext context, Consultora consultora) {
    final estilos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        const Center(child: FotoPerfil()),
        const SizedBox(height: 20),
        Text(
          consultora.nome,
          textAlign: TextAlign.center,
          style: estilos.headlineMedium,
        ),
        const SizedBox(height: 32),
        const TituloSecaoApp(titulo: 'Meus dados', icone: Icons.badge_outlined),
        const SizedBox(height: 16),
        Material(
          color: CoresApp.superficie,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: CoresApp.primariaSuave),
          ),
          child: Column(
            children: [
              LinhaDadoPerfil(
                icone: Icons.person_outline_rounded,
                rotulo: 'Nome completo',
                valor: consultora.nome,
              ),
              const Divider(height: 1),
              LinhaDadoPerfil(
                icone: Icons.phone_outlined,
                rotulo: 'WhatsApp',
                valor: FormatadorTelefone.formatar(consultora.whatsapp),
                corIcone: CoresApp.sucesso,
                corFundoIcone: CoresApp.sucessoContainer,
              ),
              const Divider(height: 1),
              _linhaPix(context, consultora),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linhaPix(BuildContext context, Consultora consultora) {
    final chave = consultora.chavePix;
    return LinhaDadoPerfil(
      icone: Icons.qr_code_2_rounded,
      rotulo: 'Chave Pix',
      valor: chave == null
          ? 'Não cadastrada'
          : FormatadorChavePix.formatar(chave),
      corIcone: CoresApp.alerta,
      corFundoIcone: CoresApp.alertaContainer,
      acao: chave == null
          ? null
          : BotaoIconeApp(
              dica: 'Copiar chave Pix',
              icone: Icons.copy_rounded,
              tamanho: 52,
              onPressed: () => _copiarPix(context, chave.valor),
            ),
    );
  }
}
