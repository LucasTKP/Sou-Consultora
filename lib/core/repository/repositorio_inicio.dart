import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/service/servico_inicio.dart';
import 'package:sou_consultora/core/service/servico_recebimentos.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

/// O que só o Início lê: lembretes de recompra e todos os pagamentos (para o
/// "Recebido no mês"). Vendas, parcelas e boletos vêm dos repositórios deles.
class RepositorioInicio {
  RepositorioInicio({
    required this._servico,
    required this._recebimentos,
    required this._whatsapp,
  });

  final ServicoInicio _servico;
  final ServicoRecebimentos _recebimentos;
  final ServicoWhatsapp _whatsapp;

  Future<Resultado<List<LembreteRecompra>>> lembretes() async {
    final resultado = await _servico.listarLembretes();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso([
        for (final dto in valor) dto.paraModel(),
      ]),
    };
  }

  Future<Resultado<List<Pagamento>>> pagamentos() async {
    final resultado = await _recebimentos.listarTodosPagamentos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso([
        for (final dto in valor) dto.paraModel(),
      ]),
    };
  }

  /// Abre o WhatsApp da cliente com a [mensagem] de recompra.
  Future<Resultado<void>> abrirWhatsapp(String whatsapp, String mensagem) =>
      _whatsapp.abrirConversa(whatsapp, mensagem: mensagem);
}
