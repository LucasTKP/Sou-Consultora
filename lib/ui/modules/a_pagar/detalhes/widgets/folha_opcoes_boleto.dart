// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// O que foi escolhido na folha de opções do boleto.
enum OpcaoBoleto { editar, comprovante, desfazer, excluir }

/// Folha "Opções do Boleto". [pago] mostra Desfazer pagamento.
abstract final class FolhaOpcoesBoleto {
  static Future<OpcaoBoleto?> mostrar(
    BuildContext context, {
    required bool pago,
  }) {
    return FolhaInferiorApp.mostrar<OpcaoBoleto>(
      context: context,
      titulo: 'Opções do Boleto',
      conteudo: (contexto) => Column(
        children: [
          _opcao(
            contexto,
            OpcaoBoleto.editar,
            Icons.edit_outlined,
            'Editar Boleto',
            'Alterar data de vencimento, valor ou fornecedor',
            CoresApp.primariaSuave,
            CoresApp.primaria,
          ),
          const SizedBox(height: 12),
          _opcao(
            contexto,
            OpcaoBoleto.comprovante,
            Icons.receipt_long_outlined,
            'Baixar / Anexar Comprovante',
            'Visualizar ou enviar comprovante',
            CoresApp.neutroContainer,
            CoresApp.neutro,
          ),
          const SizedBox(height: 12),
          if (pago) ...[
            _opcao(
              contexto,
              OpcaoBoleto.desfazer,
              Icons.undo_rounded,
              'Desfazer Pagamento',
              'O boleto volta a ficar em aberto',
              CoresApp.alertaContainer,
              CoresApp.alerta,
            ),
            const SizedBox(height: 12),
          ],
          _opcao(
            contexto,
            OpcaoBoleto.excluir,
            Icons.delete_outline_rounded,
            'Excluir Boleto',
            'Remover este registro permanentemente',
            CoresApp.perigoContainer,
            CoresApp.perigo,
          ),
        ],
      ),
    );
  }

  static Widget _opcao(
    BuildContext contexto,
    OpcaoBoleto opcao,
    IconData icone,
    String titulo,
    String descricao,
    Color fundo,
    Color cor,
  ) {
    return CartaoListaApp(
      titulo: titulo,
      subtitulo: descricao,
      inicio: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icone, color: cor),
      ),
      onTap: () => Navigator.of(contexto).pop(opcao),
    );
  }
}
