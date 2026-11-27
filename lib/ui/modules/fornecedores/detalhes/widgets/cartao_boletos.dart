// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Resumo dos boletos da marca: em aberto, pagos e atrasados.
class CartaoBoletos extends StatelessWidget {
  const CartaoBoletos({
    super.key,
    required this.fornecedor,
    required this.onVerEmAPagar,
  });

  final ResumoFornecedor fornecedor;
  final VoidCallback onVerEmAPagar;

  @override
  Widget build(BuildContext context) {
    return _Moldura(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: CoresApp.primaria),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boletos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onVerEmAPagar,
                child: const Text('Ver em A pagar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Bloco(
                  titulo: 'Em aberto',
                  valor: fornecedor.valorEmAberto,
                  quantidade: fornecedor.qtdEmAberto,
                  fundo: CoresApp.alertaContainer,
                  cor: CoresApp.alerta,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Bloco(
                  titulo: 'Pagos',
                  valor: fornecedor.valorPagos,
                  quantidade: fornecedor.qtdPagos,
                  fundo: CoresApp.sucessoContainer,
                  cor: CoresApp.sucesso,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Bloco(
                  titulo: 'Atrasados',
                  valor: fornecedor.valorAtrasado,
                  quantidade: fornecedor.qtdAtrasados,
                  fundo: CoresApp.perigoContainer,
                  cor: CoresApp.perigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.titulo,
    required this.valor,
    required this.quantidade,
    required this.fundo,
    required this.cor,
  });

  final String titulo;
  final int valor;
  final int quantidade;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final rotuloQuantidade = quantidade == 1
        ? '1 boleto'
        : '$quantidade boletos';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FormatadorMoeda.formatar(valor),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ),
          Text(rotuloQuantidade, style: TextStyle(fontSize: 13, color: cor)),
        ],
      ),
    );
  }
}

/// Card branco com borda suave usado nas seções dos detalhes.
class _Moldura extends StatelessWidget {
  const _Moldura({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.primariaSuave),
      ),
      child: child,
    );
  }
}
