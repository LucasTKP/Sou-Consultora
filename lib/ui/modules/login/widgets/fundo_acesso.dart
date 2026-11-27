// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Fundo da tela de acesso: degradê rosa e pêssego, com halo claro na marca.
class FundoAcesso extends StatelessWidget {
  const FundoAcesso({super.key, required this.filho});

  final Widget filho;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _PintorFundoAcesso()),
        filho,
      ],
    );
  }
}

class _PintorFundoAcesso extends CustomPainter {
  const _PintorFundoAcesso();

  static const _blush = Color(0xFFF6B7C8);
  static const _rosa = Color(0xFFE25A86);
  static const _pessego = Color(0xFFF3A888);
  static const _base = Color(0xFFF8D0C4);
  static const _berry = Color(0xFFB0396F);
  static const _halo = Color(0xFFFFF6F4);

  @override
  void paint(Canvas canvas, Size size) {
    final retangulo = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_blush, _rosa, _pessego, _base],
        stops: [0.0, 0.42, 0.74, 1.0],
      ).createShader(retangulo);
    canvas.drawRect(retangulo, base);

    // Palco claro atrás da logo, para o magenta não se misturar com o rosa.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.50, size.height * 0.30),
      raio: size.width * 0.58,
      cor: _halo.withValues(alpha: 0.82),
    );

    // Berry no canto superior direito.
    _brilho(
      canvas,
      centro: Offset(size.width * 1.05, size.height * -0.02),
      raio: size.width * 0.72,
      cor: _berry.withValues(alpha: 0.48),
    );

    // Pêssego quente na lateral esquerda, na altura do cartão.
    _brilho(
      canvas,
      centro: Offset(size.width * -0.12, size.height * 0.46),
      raio: size.width * 0.62,
      cor: const Color(0xFFF6B07A).withValues(alpha: 0.42),
    );

    // Rosa fechado no rodapé, para os botões sentarem em cor.
    _brilho(
      canvas,
      centro: Offset(size.width * 0.72, size.height * 1.04),
      raio: size.width * 0.78,
      cor: _rosa.withValues(alpha: 0.38),
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
      ).createShader(Rect.fromCircle(center: centro, radius: raio));
    canvas.drawCircle(centro, raio, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
