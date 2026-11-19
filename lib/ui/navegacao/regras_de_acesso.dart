import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';

/// Para onde o app deve ir antes de abrir [destino]; `null` = destino permitido.
///
/// | Estado                          | Única rota possível |
/// |---------------------------------|---------------------|
/// | atualizacaoObrigatoria          | /atualizar          |
/// | desconectado                    | /login              |
/// | verificando / erroVerificacao   | /carregando         |
/// | semCadastro                     | /cadastro           |
/// | pronto                          | qualquer rota do app (login, cadastro e carregando → /inicio) |
String? destinoPermitido({
  required EstadoAcesso estado,
  required String destino,
}) {
  final rotaObrigatoria = switch (estado) {
    EstadoAcesso.atualizacaoObrigatoria => RotasApp.atualizacao,
    EstadoAcesso.desconectado => RotasApp.login,
    EstadoAcesso.verificando ||
    EstadoAcesso.erroVerificacao => RotasApp.carregando,
    EstadoAcesso.semCadastro => RotasApp.cadastro,
    EstadoAcesso.pronto => null,
  };
  if (rotaObrigatoria != null) {
    return destino == rotaObrigatoria ? null : rotaObrigatoria;
  }

  const rotasDeEntrada = {
    RotasApp.login,
    RotasApp.cadastro,
    RotasApp.carregando,
    RotasApp.atualizacao,
  };
  return rotasDeEntrada.contains(destino) ? RotasApp.inicio : null;
}
