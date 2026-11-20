// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_suporte/botao_suporte_app.dart';

/// Lista ou tela sem dados ("Nenhum cliente cadastrado").
class EstadoVazioApp extends StatelessWidget {
  const EstadoVazioApp({
    super.key,
    required this.titulo,
    this.mensagem,
    this.icone = Icons.inbox_outlined,
    this.acao,
  });

  final String titulo;
  final String? mensagem;
  final IconData icone;

  /// Ex.: botão "Cadastrar primeiro cliente".
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icone: icone,
      corIcone: CoresApp.primaria,
      titulo: titulo,
      mensagem: mensagem,
      acao: acao,
    );
  }
}

/// Layout comum dos estados de tela (ícone, título, mensagem, ação).
class _EstadoBase extends StatelessWidget {
  const _EstadoBase({
    required this.icone,
    required this.corIcone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: CoresApp.primariaSuave,
              child: Icon(icone, size: 36, color: corIcone),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: estilos.titleLarge,
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: estilos.bodyMedium?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 24), acao!],
          ],
        ),
      ),
    );
  }
}

/// Erro ao carregar: "Tentar novamente" (quando há) e, sempre, "Falar com o suporte".
class EstadoErroApp extends StatelessWidget {
  const EstadoErroApp({
    super.key,
    required this.mensagem,
    this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icone: Icons.error_outline_rounded,
      corIcone: CoresApp.perigo,
      titulo: 'Algo deu errado',
      mensagem: mensagem,
      acao: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onTentarNovamente != null) ...[
            OutlinedButton.icon(
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
          ],
          BotaoSuporteApp(detalhe: mensagem),
        ],
      ),
    );
  }
}

/// Módulo ainda não construído.
class EstadoEmConstrucaoApp extends StatelessWidget {
  const EstadoEmConstrucaoApp({super.key, required this.modulo});

  final String modulo;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icone: Icons.construction_rounded,
      corIcone: CoresApp.primaria,
      titulo: '$modulo em construção',
      mensagem: 'Esta parte do app estará disponível em breve.',
    );
  }
}

/// Carregando, com mensagem opcional.
class EstadoCarregandoApp extends StatelessWidget {
  const EstadoCarregandoApp({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: CoresApp.primaria),
          if (mensagem != null) ...[
            const SizedBox(height: 16),
            Text(mensagem!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
