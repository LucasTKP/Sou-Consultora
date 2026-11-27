/// Aceite dos Termos de Uso e da Política de Privacidade.
abstract final class TermosDeUso {
  /// Data do texto em vigor (aaaa-mm-dd), gravada junto com o aceite.
  /// Mudou o texto → mude a data.
  static const versao = '2026-11-26';

  /// Quem mantém o app (controlador dos dados da conta, pela LGPD).
  static const responsavel = 'Lucas';
  static const emailContato = 'lucasgeansantos@gmail.com';

  static String? validarAceite(bool aceitou) =>
      aceitou ? null : 'Aceite os termos para continuar';
}
