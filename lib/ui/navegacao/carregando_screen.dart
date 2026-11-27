// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';

/// Enquanto o app confere o cadastro da consultora (ou falhou ao conferir).
class CarregandoScreen extends StatelessWidget {
  const CarregandoScreen({super.key, required this.acesso});

  final NotificadorAcesso acesso;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.fundo,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: acesso,
          builder: (context, _) => Column(
            children: [
              const Spacer(),
              Image.asset('assets/imagens/logo.png', width: 112, height: 112),
              const SizedBox(height: 24),
              _conteudo(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (acesso.estado != EstadoAcesso.erroVerificacao) {
      return const EstadoCarregandoApp(mensagem: 'Carregando seus dados...');
    }
    return EstadoErroApp(
      mensagem: acesso.mensagemErro ?? 'Não foi possível carregar seus dados.',
      onTentarNovamente: acesso.tentarNovamente,
    );
  }
}
