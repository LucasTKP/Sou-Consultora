// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';

/// Fundo da tela de acesso: rosa-pêssego suave com brilhos radiais (como no DS).
class FundoAcesso extends StatelessWidget {
  const FundoAcesso({super.key, required this.filho});

  final Widget filho;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: CoresApp.fundo),
        const CustomPaint(painter: _PintorFundoAcesso()),
        filho,
      ],
    );
  }
}

class _PintorFundoAcesso extends CustomPainter {
  const _PintorFundoAcesso();

  static const _pessego = Color(0xFFF7DDCC);
  static const _rosaClaro = Color(0xFFFFEBF0);
  static const _cremeQuente = Color(0xFFFFF3E5);
  static const _rosaSuave = Color(0xFFFFF6F7);

  @override
  void paint(Canvas canvas, Size size) {
    // Brilho principal atrás do logo (topo/centro) — pêssego quente.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.50, size.height * 0.14),
      raio: size.width * 0.72,
      cor: _pessego.withValues(alpha: 0.85),
    );

    // Glow rosa à direita superior.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.92, size.height * 0.08),
      raio: size.width * 0.55,
      cor: _rosaClaro.withValues(alpha: 0.70),
    );

    // Glow creme à esquerda (meio).
    _brilho(
      canvas,
      centro: Offset(size.width * 0.08, size.height * 0.42),
      raio: size.width * 0.65,
      cor: _cremeQuente.withValues(alpha: 0.55),
    );

    // Glow inferior esquerdo — rosa suave.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.18, size.height * 0.88),
      raio: size.width * 0.70,
      cor: _rosaSuave.withValues(alpha: 0.90),
    );

    // Glow inferior direito.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.88, size.height * 0.92),
      raio: size.width * 0.55,
      cor: _rosaClaro.withValues(alpha: 0.55),
    );

    // Centro mais claro (área do card) — abre o meio.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.50, size.height * 0.52),
      raio: size.width * 0.85,
      cor: const Color(0xFFFFFFFF).withValues(alpha: 0.55),
    );
  }

  void _brilho(
    Canvas canvas, {
    required Offset centro,
    required double raio,
    required Color cor,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [cor, cor.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: centro, radius: raio));
    canvas.drawCircle(centro, raio, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
