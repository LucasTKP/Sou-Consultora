// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/termos_de_uso.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/termos/termos_conteudo.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

/// Leitura dos Termos de Uso e da Política de Privacidade (só texto).
class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = FormatadorData.curta(DateTime.parse(TermosDeUso.versao));
    return Scaffold(
      body: Column(
        children: [
          const CabecalhoApp(titulo: 'Termos'),
          Expanded(
            child: SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  Text('Versão de $data'),
                  const SizedBox(height: 20),
                  ..._documento(
                    context,
                    'Termos de Uso',
                    TermosConteudo.termos,
                  ),
                  const SizedBox(height: 16),
                  ..._documento(
                    context,
                    'Política de Privacidade',
                    TermosConteudo.privacidade,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _documento(
    BuildContext context,
    String titulo,
    List<SecaoTermos> secoes,
  ) {
    final estilos = Theme.of(context).textTheme;
    return [
      Text(
        titulo,
        style: estilos.headlineSmall?.copyWith(color: CoresApp.primariaEscura),
      ),
      for (final secao in secoes) ...[
        const SizedBox(height: 16),
        Text(secao.titulo, style: estilos.titleMedium),
        for (final paragrafo in secao.paragrafos) ...[
          const SizedBox(height: 8),
          Text(paragrafo, style: estilos.bodyMedium?.copyWith(height: 1.4)),
        ],
      ],
    ];
  }
}
