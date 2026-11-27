// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_comprovante.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// O comprovante em si (vira a imagem compartilhada): valor e data, quem
/// recebeu e pagou, a parcela, a venda com as parcelas e o saldo restante.
class CartaoComprovante extends StatelessWidget {
  const CartaoComprovante({
    super.key,
    required this.detalhe,
    required this.pagamento,
    this.consultora,
  });

  final DetalheParcela detalhe;
  final Pagamento pagamento;
  final Consultora? consultora;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CoresApp.contorno),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 8, color: CoresApp.sucesso),
          _Topo(pagamento: pagamento),
          const _LinhaTracejada(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Partes(
                  detalhe: detalhe,
                  pagamento: pagamento,
                  consultora: consultora,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SeloStatusApp(
                    tamanho: TamanhoSelo.pagina,
                    rotulo:
                        'Parcela ${detalhe.parcela.textoNumero} • '
                        '${MensagemComprovante.situacao(detalhe)}',
                    status: detalhe.parcela.paga
                        ? StatusSelo.sucesso
                        : StatusSelo.primario,
                  ),
                ),
                const Divider(height: 32, color: CoresApp.contorno),
                _Venda(detalhe: detalhe, pagamento: pagamento),
              ],
            ),
          ),
          _Rodape(consultora: consultora),
        ],
      ),
    );
  }
}

class _Topo extends StatelessWidget {
  const _Topo({required this.pagamento});

  final Pagamento pagamento;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final data = pagamento.data;
    final hora =
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CoresApp.sucessoContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: CoresApp.sucesso,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pagamento confirmado',
                    style: estilos.titleSmall?.copyWith(
                      color: CoresApp.sucesso,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VALOR PAGO',
            style: estilos.labelLarge?.copyWith(
              color: CoresApp.sobreSuperficieVariante,
            ),
          ),
          Text(
            FormatadorMoeda.formatar(pagamento.valor),
            style: estilos.displaySmall?.copyWith(color: CoresApp.sucesso),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: 'Data do pagamento: ',
              children: [
                TextSpan(
                  text: '${FormatadorData.curta(data)} às $hora',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: estilos.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Partes extends StatelessWidget {
  const _Partes({
    required this.detalhe,
    required this.pagamento,
    this.consultora,
  });

  final DetalheParcela detalhe;
  final Pagamento pagamento;
  final Consultora? consultora;

  @override
  Widget build(BuildContext context) {
    final chave = consultora?.chavePix;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Dado(rotulo: 'CONSULTORA', valor: consultora?.nome ?? ''),
            ),
            if (chave != null)
              Expanded(
                flex: 2,
                child: _Dado(
                  rotulo: 'CHAVE PIX',
                  valor: FormatadorChavePix.formatar(chave),
                  aDireita: true,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Dado(
                rotulo: 'CLIENTE',
                valor: detalhe.parcela.clienteNome,
              ),
            ),
            Expanded(
              flex: 2,
              child: _Dado(
                rotulo: 'PAGAMENTO',
                valor: pagamento.forma.rotulo,
                aDireita: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado({
    required this.rotulo,
    required this.valor,
    this.aDireita = false,
  });

  final String rotulo;
  final String valor;
  final bool aDireita;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final textos = Column(
      crossAxisAlignment: aDireita
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: estilos.labelMedium?.copyWith(
            color: CoresApp.sobreSuperficieVariante,
          ),
        ),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: aDireita ? TextAlign.end : TextAlign.start,
          style: estilos.bodyLarge,
        ),
      ],
    );
    return textos;
  }
}

class _Venda extends StatelessWidget {
  const _Venda({required this.detalhe, required this.pagamento});

  final DetalheParcela detalhe;
  final Pagamento pagamento;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final venda = detalhe.venda;
    final saldo = detalhe.saldoDaVenda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CoresApp.alertaContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: CoresApp.alerta,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venda ${venda.codigoTexto}',
                    style: estilos.titleMedium,
                  ),
                  Text(
                    '${FormatadorData.curta(venda.dataVenda)} • '
                    '${venda.textoItens} • ${venda.qtdParcelas}x',
                    style: estilos.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TOTAL',
                  style: estilos.labelMedium?.copyWith(
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                ),
                Text(
                  FormatadorMoeda.formatar(venda.total),
                  style: estilos.titleMedium,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final parcela in detalhe.parcelasDaVenda)
          _LinhaParcela(
            parcela: parcela,
            pagamento: parcela.id == pagamento.parcelaId ? pagamento : null,
          ),
        const Divider(height: 24, color: CoresApp.contorno),
        Row(
          children: [
            Expanded(
              child: Text('Saldo restante da venda', style: estilos.titleSmall),
            ),
            Text(
              FormatadorMoeda.formatar(saldo),
              style: estilos.titleLarge?.copyWith(
                color: saldo == 0 ? CoresApp.sucesso : CoresApp.primaria,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinhaParcela extends StatelessWidget {
  const _LinhaParcela({required this.parcela, this.pagamento});

  final ResumoParcela parcela;

  /// Preenchido na parcela deste comprovante.
  final Pagamento? pagamento;

  String get _situacao {
    if (pagamento != null) return 'este pagamento';
    if (parcela.paga) {
      final pagoEm = parcela.ultimoPagamento;
      return pagoEm == null
          ? 'paga'
          : 'paga em ${FormatadorData.diaMesNumerico(pagoEm)}';
    }
    if (parcela.valorPago > 0) return 'parcial';
    return 'em aberto';
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final deste = pagamento;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Parcela ${parcela.textoNumero} • $_situacao',
              style: estilos.bodyMedium?.copyWith(
                color: CoresApp.sobreSuperficieVariante,
              ),
            ),
          ),
          Text(
            FormatadorMoeda.formatar(deste?.valor ?? parcela.valor),
            style: estilos.titleSmall?.copyWith(
              color: deste == null ? null : CoresApp.sucesso,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({this.consultora});

  final Consultora? consultora;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final url = consultora?.urlFoto;
    return Container(
      color: CoresApp.primaria,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Aplicativo',
                  textAlign: TextAlign.center,
                  style: estilos.bodyMedium?.copyWith(
                    color: CoresApp.sobrePrimaria,
                  ),
                ),
                Text(
                  'Sou Consultora',
                  textAlign: TextAlign.center,
                  style: estilos.titleMedium?.copyWith(
                    color: CoresApp.sobrePrimaria,
                  ),
                ),
              ],
            ),
          ),
          if (url != null)
            FotoQuadradaApp(url: url, tamanho: TamanhoAvatar.card),
        ],
      ),
    );
  }
}

/// Linha tracejada que separa o topo do comprovante.
class _LinhaTracejada extends StatelessWidget {
  const _LinhaTracejada();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (_, limites) {
          final quantidade = (limites.maxWidth / 10).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < quantidade; i++)
                Container(width: 5, height: 1.5, color: CoresApp.contorno),
            ],
          );
        },
      ),
    );
  }
}
