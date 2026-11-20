// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:sou_consultora/ui/widgets/estrutura/rodape_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/modules/a_receber/comprovante/a_receber_comprovante_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/comprovante/a_receber_comprovante_state.dart';
import 'package:sou_consultora/ui/modules/a_receber/comprovante/widgets/cartao_comprovante.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Comprovante de pagamento da parcela, com Compartilhar (imagem + texto).
class AReceberComprovanteScreen extends StatelessWidget {
  const AReceberComprovanteScreen({
    super.key,
    required this.idParcela,
    this.idPagamento,
  });

  final String idParcela;

  /// Null = último pagamento da parcela.
  final String? idPagamento;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AReceberComprovanteCubit(
        idParcela: idParcela,
        idPagamento: idPagamento,
      ),
      child: const _ComprovanteVista(),
    );
  }
}

class _ComprovanteVista extends StatefulWidget {
  const _ComprovanteVista();

  @override
  State<_ComprovanteVista> createState() => _ComprovanteVistaState();
}

class _ComprovanteVistaState extends State<_ComprovanteVista> {
  final _chaveImagem = GlobalKey();

  void _aoMudarEstado(BuildContext context, AReceberComprovanteState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<AReceberComprovanteCubit>().limparAviso();
  }

  Future<void> _compartilhar() async {
    final cubit = context.read<AReceberComprovanteCubit>();
    final png = await _gerarPng();
    if (!mounted) return;
    if (png == null) {
      cubit.falharImagem();
      return;
    }
    await cubit.compartilhar(png);
  }

  /// Foto do cartão (3× para ficar nítida no WhatsApp).
  Future<Uint8List?> _gerarPng() async {
    final limite = _chaveImagem.currentContext?.findRenderObject();
    if (limite is! RenderRepaintBoundary) return null;
    final imagem = await limite.toImage(pixelRatio: 3);
    final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    return dados?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AReceberComprovanteCubit, AReceberComprovanteState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoMudarEstado,
      builder: (context, estado) => Scaffold(
        body: Column(
          children: [
            const CabecalhoApp(titulo: 'Comprovante de Pagamento'),
            Expanded(child: _corpo(context, estado)),
            if (estado.pronto)
              RodapeSeguro(
                child: BotaoApp(
                  rotulo: estado.compartilhando
                      ? 'Preparando...'
                      : 'Compartilhar',
                  onPressed: estado.compartilhando ? null : _compartilhar,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context, AReceberComprovanteState estado) {
    final detalhe = estado.detalhe;
    final pagamento = estado.pagamento;
    if (detalhe != null && pagamento != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: RepaintBoundary(
          key: _chaveImagem,
          // Fundo próprio: o PNG não sai transparente.
          child: ColoredBox(
            color: CoresApp.fundo,
            child: CartaoComprovante(
              detalhe: detalhe,
              pagamento: pagamento,
              consultora: estado.consultora,
            ),
          ),
        ),
      );
    }
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<AReceberComprovanteCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}
