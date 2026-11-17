// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_icone_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Seleção de um item de uma lista (cliente, fornecedor, produto...).
///
/// O toque abre uma folha com as opções (e busca, se [buscavel]).
/// [onAtalho] mostra o botão ">" ao lado (ex.: abrir o cadastro do item).
class CampoSelecaoApp<T> extends StatefulWidget {
  const CampoSelecaoApp({
    super.key,
    required this.rotulo,
    required this.opcoes,
    required this.rotuloDe,
    required this.onChanged,
    this.valor,
    this.placeholder = 'Selecione',
    this.buscavel = false,
    this.icone,
    this.obrigatorio = false,
    this.opcional = false,
    this.erro,
    this.onAtalho,
    this.dicaAtalho = 'Abrir cadastro',
  });

  final String rotulo;
  final List<T> opcoes;
  final String Function(T opcao) rotuloDe;
  final ValueChanged<T> onChanged;
  final T? valor;
  final String placeholder;
  final bool buscavel;
  final IconData? icone;
  final bool obrigatorio;
  final bool opcional;
  final String? erro;
  final VoidCallback? onAtalho;
  final String dicaAtalho;

  @override
  State<CampoSelecaoApp<T>> createState() => _CampoSelecaoAppState<T>();
}

class _CampoSelecaoAppState<T> extends State<CampoSelecaoApp<T>> {
  late final TextEditingController _controle = TextEditingController(
    text: _texto(widget.valor),
  );

  @override
  void didUpdateWidget(CampoSelecaoApp<T> antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.valor != widget.valor) _controle.text = _texto(widget.valor);
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  String _texto(T? valor) => valor == null ? '' : widget.rotuloDe(valor);

  Future<void> _abrirOpcoes() async {
    final escolhida = await FolhaInferiorApp.mostrar<T>(
      context: context,
      titulo: widget.rotulo,
      conteudo: (_) => _ListaOpcoes<T>(
        opcoes: widget.opcoes,
        rotuloDe: widget.rotuloDe,
        selecionada: widget.valor,
        buscavel: widget.buscavel,
      ),
    );
    if (escolhida != null) widget.onChanged(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final campo = CampoTextoApp(
      rotulo: widget.rotulo,
      obrigatorio: widget.obrigatorio,
      opcional: widget.opcional,
      erro: widget.erro,
      somenteLeitura: true,
      placeholder: widget.placeholder,
      controller: _controle,
      onTap: _abrirOpcoes,
      leading: widget.icone == null
          ? null
          : Icon(widget.icone, color: CoresApp.primaria),
      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
    );
    if (widget.onAtalho == null) return campo;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: campo),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: BotaoIconeApp(
            dica: widget.dicaAtalho,
            onPressed: widget.onAtalho,
          ),
        ),
      ],
    );
  }
}

class _ListaOpcoes<T> extends StatefulWidget {
  const _ListaOpcoes({
    required this.opcoes,
    required this.rotuloDe,
    required this.buscavel,
    this.selecionada,
  });

  final List<T> opcoes;
  final String Function(T opcao) rotuloDe;
  final bool buscavel;
  final T? selecionada;

  @override
  State<_ListaOpcoes<T>> createState() => _ListaOpcoesState<T>();
}

class _ListaOpcoesState<T> extends State<_ListaOpcoes<T>> {
  String _busca = '';

  List<T> get _filtradas {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return widget.opcoes;
    return widget.opcoes
        .where((opcao) => widget.rotuloDe(opcao).toLowerCase().contains(termo))
        .toList();
  }

  void _aoBuscar(String texto) => setState(() => _busca = texto);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.buscavel) ...[
          CampoBuscaApp(placeholder: 'Buscar...', onChanged: _aoBuscar),
          const SizedBox(height: 12),
        ],
        for (final opcao in _filtradas) _item(opcao),
      ],
    );
  }

  Widget _item(T opcao) {
    final selecionada = opcao == widget.selecionada;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.rotuloDe(opcao)),
      trailing: selecionada
          ? const Icon(Icons.check_rounded, color: CoresApp.primaria)
          : null,
      onTap: () => Navigator.of(context).pop(opcao),
    );
  }
}
