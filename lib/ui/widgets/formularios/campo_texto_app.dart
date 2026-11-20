// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/erro_em_toast.dart';

/// Campo de texto do app com rótulo sobre a borda (padrão do design system).
///
/// O rótulo recebe " *" quando [obrigatorio] e " (Opcional)" quando [opcional].
///
/// **Validação:** o padrão do projeto é validar no Cubit/Model e passar a
/// mensagem em [erro] (testável sem widget e igual para erros do servidor).
/// [validador] existe só para casos pontuais dentro de um `Form`.
class CampoTextoApp extends StatelessWidget {
  const CampoTextoApp({
    super.key,
    this.rotulo,
    this.obrigatorio = false,
    this.opcional = false,
    this.erro,
    this.validador,
    this.controller,
    this.placeholder,
    this.habilitado = true,
    this.somenteLeitura = false,
    this.obscuro = false,
    this.teclado,
    this.formatadores,
    this.onChanged,
    this.onTap,
    this.leading,
    this.trailing,
    this.trailingCompacto = false,
    this.restricaoTrailing,
    this.estilo,
    this.linhas = 1,
    this.acaoTeclado,
    this.capitalizacao = TextCapitalization.none,
    this.focusNode,
  });

  final String? rotulo;
  final bool obrigatorio;
  final bool opcional;

  /// Mensagem de erro exibida abaixo do campo.
  final String? erro;

  /// Validação local opcional (usar só em casos pontuais; ver doc da classe).
  final FormFieldValidator<String>? validador;
  final TextEditingController? controller;
  final String? placeholder;
  final bool habilitado;
  final bool somenteLeitura;
  final bool obscuro;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  /// Encosta [trailing] na borda direita, com pouco espaço até o texto.
  final bool trailingCompacto;

  /// Largura fixa do [trailing]. O texto vai até essa caixa, sem o recuo padrão.
  final BoxConstraints? restricaoTrailing;

  /// Estilo do valor. Padrão: `bodyLarge`.
  final TextStyle? estilo;
  final int linhas;
  final TextInputAction? acaoTeclado;
  final TextCapitalization capitalizacao;

  /// Para mover o foco por código (ex.: ir ao número depois do CEP).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return ErroEmToast(erro: erro, child: _campo(context));
  }

  Widget _campo(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validador,
      // Erro vira toast (ErroEmToast); aqui só a borda fica vermelha.
      forceErrorText: erro == null ? null : '',
      enabled: habilitado,
      readOnly: somenteLeitura,
      // Campo de seleção só abre a folha: sem seleção nem menu de copiar/colar.
      enableInteractiveSelection: !somenteLeitura,
      // Menu do próprio Flutter: o do sistema (SystemContextMenu) quebra quando
      // dois campos tentam abri-lo ao mesmo tempo.
      contextMenuBuilder: (context, estadoEditavel) =>
          AdaptiveTextSelectionToolbar.editableText(
            editableTextState: estadoEditavel,
          ),
      obscureText: obscuro,
      keyboardType: linhas > 1 ? TextInputType.multiline : teclado,
      inputFormatters: formatadores,
      onChanged: onChanged,
      onTap: onTap,
      minLines: linhas,
      maxLines: obscuro ? 1 : linhas,
      textInputAction: acaoTeclado,
      textCapitalization: capitalizacao,
      style: estilo ?? Theme.of(context).textTheme.bodyLarge,
      decoration: _decoracao(context),
    );
  }

  InputDecoration _decoracao(BuildContext context) {
    return InputDecoration(
      label: rotulo == null
          ? null
          : _RotuloCampo(
              rotulo: rotulo!,
              obrigatorio: obrigatorio,
              opcional: opcional,
            ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: placeholder,
      hintStyle: estilo?.copyWith(color: CoresApp.sobreSuperficieVariante),
      prefixIcon: leading,
      suffixIcon: trailing,
      suffixIconConstraints:
          restricaoTrailing ??
          (trailingCompacto
              ? const BoxConstraints.tightFor(width: 32, height: 32)
              : null),
      alignLabelWithHint: linhas > 1,
      contentPadding: EdgeInsets.fromLTRB(
        16,
        18,
        restricaoTrailing != null || trailingCompacto ? 0 : 16,
        18,
      ),
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      errorBorder: _borda(CoresApp.perigo),
      focusedErrorBorder: _borda(CoresApp.perigo, largura: 1.5),
      enabledBorder: _borda(CoresApp.primariaSuave, largura: 1.5),
    );
  }

  OutlineInputBorder _borda(Color cor, {double largura = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cor, width: largura),
    );
  }
}

class _RotuloCampo extends StatelessWidget {
  const _RotuloCampo({
    required this.rotulo,
    required this.obrigatorio,
    required this.opcional,
  });

  final String rotulo;
  final bool obrigatorio;
  final bool opcional;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: CoresApp.primariaEscura);
    return Text.rich(
      TextSpan(
        text: rotulo,
        style: estilo,
        children: [
          if (obrigatorio) const TextSpan(text: ' *'),
          if (opcional)
            TextSpan(
              text: ' (Opcional)',
              style: estilo?.copyWith(
                fontWeight: FontWeight.w400,
                color: CoresApp.sobreSuperficieVariante,
              ),
            ),
        ],
      ),
    );
  }
}
