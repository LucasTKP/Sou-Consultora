// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// O que foi escolhido na folha de opções da venda.
enum OpcaoVenda { cobrar, recibo, cancelar }

/// Folha "Opções da venda" (Vendas e A receber): cobrar no WhatsApp, gerar
/// recibo e cancelar.
/// [podeCobrar] some na venda quitada; [temRecibo] some sem pagamento.
abstract final class FolhaOpcoesVenda {
  static Future<OpcaoVenda?> mostrar(
    BuildContext context, {
    required bool podeCobrar,
    required bool temRecibo,
  }) {
    return FolhaInferiorApp.mostrar<OpcaoVenda>(
      context: context,
      titulo: 'Opções da Venda',
      conteudo: (contexto) => Column(
        children: [
          if (podeCobrar) ...[
            _opcao(
              contexto,
              OpcaoVenda.cobrar,
              Icons.chat_outlined,
              'Cobrar no WhatsApp',
              'Lembrete da parcela em aberto',
              CoresApp.sucessoContainer,
              CoresApp.sucesso,
            ),
            const SizedBox(height: 12),
          ],
          if (temRecibo) ...[
            _opcao(
              contexto,
              OpcaoVenda.recibo,
              Icons.receipt_long_outlined,
              'Gerar Recibo / Comprovante',
              'Comprovante do último pagamento',
              CoresApp.neutroContainer,
              CoresApp.neutro,
            ),
            const SizedBox(height: 12),
          ],
          _opcao(
            contexto,
            OpcaoVenda.cancelar,
            Icons.delete_outline_rounded,
            'Cancelar Venda',
            'Apaga tudo e devolve o estoque',
            CoresApp.perigoContainer,
            CoresApp.perigo,
          ),
          const SizedBox(height: 16),
          BotaoApp.secundario(
            rotulo: 'Fechar',
            onPressed: () => Navigator.of(contexto).pop(),
          ),
        ],
      ),
    );
  }

  static Widget _opcao(
    BuildContext contexto,
    OpcaoVenda opcao,
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
