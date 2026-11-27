// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Seleção de um item de uma lista (cliente, fornecedor, produto...).
///
/// O toque abre uma folha com as opções (e busca, se [buscavel]).
/// [onCadastrar] põe um botão "Cadastrar..." no rodapé da folha (ex.: abrir o
/// cadastro do item que não está na lista); [rotuloCadastrar] é o texto dele.
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
    this.onCadastrar,
    this.rotuloCadastrar = 'Cadastrar',
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
  final VoidCallback? onCadastrar;
  final String rotuloCadastrar;

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
    // Compara o texto (não só o valor): o rótulo pode mudar com o mesmo valor (ex.: contagens).
    final texto = _texto(widget.valor);
    if (_controle.text != texto) _controle.text = texto;
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  String _texto(T? valor) => valor == null ? '' : widget.rotuloDe(valor);

  Future<void> _abrirOpcoes() async {
    final onCadastrar = widget.onCadastrar;
    final resultado = await FolhaInferiorApp.mostrar<Object>(
      context: context,
      titulo: widget.rotulo,
      conteudo: (_) => _ListaOpcoes<T>(
        opcoes: widget.opcoes,
        rotuloDe: widget.rotuloDe,
        selecionada: widget.valor,
        buscavel: widget.buscavel,
      ),
      rodape: onCadastrar == null
          ? null
          : Builder(
              builder: (contexto) => BotaoApp.contorno(
                rotulo: widget.rotuloCadastrar,
                iconeFim: const Icon(Icons.add_rounded),
                onPressed: () =>
                    Navigator.of(contexto).pop(const _PedidoDeCadastro()),
              ),
            ),
    );
    // O cadastro só abre depois de a folha fechar.
    if (resultado is _PedidoDeCadastro) {
      widget.onCadastrar?.call();
    } else if (resultado is T) {
      widget.onChanged(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return CampoTextoApp(
      rotulo: widget.rotulo,
      obrigatorio: widget.obrigatorio,
      opcional: widget.opcional,
      erro: widget.erro,
      somenteLeitura: true,
      placeholder: widget.placeholder,
      controller: _controle,
      onTap: _abrirOpcoes,
      // 8 px até o texto, 24 da seta e 8 até a borda.
      restricaoTrailing: const BoxConstraints.tightFor(width: 40, height: 48),
      estilo: estilos.bodySmall?.copyWith(
        color: CoresApp.sobreSuperficie,
        fontWeight: FontWeight.w500,
      ),
      leading: widget.icone == null
          ? null
          : Icon(widget.icone, size: 24, color: CoresApp.primaria),
      trailing: const SizedBox(
        width: 40,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24,
              color: CoresApp.sobreSuperficieVariante,
            ),
          ),
        ),
      ),
    );
  }
}

/// O botão "Cadastrar" da folha fecha-a devolvendo este marcador.
class _PedidoDeCadastro {
  const _PedidoDeCadastro();
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
        if (_filtradas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum resultado.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CoresApp.sobreSuperficieVariante),
            ),
          ),
        for (final opcao in _filtradas) _item(opcao),
      ],
    );
  }

  Widget _item(T opcao) {
    final selecionada = opcao == widget.selecionada;
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selecionada ? CoresApp.primariaSuave : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).pop(opcao),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.rotuloDe(opcao),
                    style: estilos.bodyLarge?.copyWith(
                      fontWeight: selecionada
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selecionada ? CoresApp.primariaEscura : null,
                    ),
                  ),
                ),
                if (selecionada) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_rounded, color: CoresApp.primaria),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
