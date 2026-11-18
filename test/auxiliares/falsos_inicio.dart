import 'package:sou_consultora/core/dto/lembrete_recompra_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/service/servico_inicio.dart';

import 'falsos_clientes.dart';
import 'falsos_recebimentos.dart';

LembreteRecompraDto lembreteDto({
  String clienteId = 'c1',
  String cliente = 'Carla Menezes',
  String produtoId = 'p1',
  String produto = 'Lily Eau de Parfum 75ml',
  int durabilidade = 60,
  required DateTime ultimaCompra,
}) => LembreteRecompraDto(
  clienteId: clienteId,
  clienteNome: cliente,
  clienteWhatsapp: '11987654321',
  produtoId: produtoId,
  produtoNome: produto,
  durabilidadeDias: durabilidade,
  ultimaCompra: ultimaCompra,
);

class ServicoInicioFalso implements ServicoInicio {
  ServicoInicioFalso({List<LembreteRecompraDto>? lembretes})
    : lembretes = lembretes ?? [];

  List<LembreteRecompraDto> lembretes;
  bool falharRede = false;

  @override
  Future<Resultado<List<LembreteRecompraDto>>> listarLembretes() async {
    if (falharRede) {
      return Erro(
        const FalhaRede(
          'Sem conexão com a internet. Verifique e tente novamente.',
        ),
      );
    }
    return Sucesso(List.of(lembretes));
  }
}

RepositorioInicio repositorioInicioDeTeste({
  required ServicoInicioFalso servico,
  required ServicoRecebimentosFalso recebimentos,
  ServicoWhatsappFalso? whatsapp,
}) => RepositorioInicio(
  servico: servico,
  recebimentos: recebimentos,
  whatsapp: whatsapp ?? ServicoWhatsappFalso(),
);
