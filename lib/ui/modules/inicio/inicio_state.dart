import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

enum CarregamentoInicio { carregando, pronto, erro }

class InicioState {
  const InicioState({
    required this.hoje,
    this.consultora,
    this.carregamento = CarregamentoInicio.carregando,
    this.vendas = const [],
    this.pagamentos = const [],
    this.parcelas = const [],
    this.boletos = const [],
    this.lembretes = const [],
    this.mensagemErro,
    this.aviso,
  });

  final DateTime hoje;

  /// Nome e foto do cumprimento.
  final Consultora? consultora;
  final CarregamentoInicio carregamento;
  final List<ResumoVenda> vendas;
  final List<Pagamento> pagamentos;
  final List<ResumoParcela> parcelas;
  final List<ResumoBoleto> boletos;
  final List<LembreteRecompra> lembretes;
  final String? mensagemErro;
  final AvisoToast? aviso;

  ResumoInicio get resumo => ResumoInicio.calcular(
    vendas: vendas,
    pagamentos: pagamentos,
    parcelas: parcelas,
    boletos: boletos,
    lembretes: lembretes,
    hoje: hoje,
  );

  /// "Bom dia" até 11h59, "Boa tarde" até 17h59, "Boa noite" depois.
  String get saudacao {
    final hora = hoje.hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// "Bom dia, Mariana!" (só a saudação sem o nome).
  String get cumprimento {
    final primeiro = consultora?.nome.trim().split(RegExp(r'\s+')).first ?? '';
    return primeiro.isEmpty ? '$saudacao!' : '$saudacao, $primeiro!';
  }

  InicioState copyWith({
    Consultora? Function()? consultora,
    CarregamentoInicio? carregamento,
    List<ResumoVenda>? vendas,
    List<Pagamento>? pagamentos,
    List<ResumoParcela>? parcelas,
    List<ResumoBoleto>? boletos,
    List<LembreteRecompra>? lembretes,
    String? Function()? mensagemErro,
    AvisoToast? Function()? aviso,
  }) {
    return InicioState(
      hoje: hoje,
      consultora: consultora != null ? consultora() : this.consultora,
      carregamento: carregamento ?? this.carregamento,
      vendas: vendas ?? this.vendas,
      pagamentos: pagamentos ?? this.pagamentos,
      parcelas: parcelas ?? this.parcelas,
      boletos: boletos ?? this.boletos,
      lembretes: lembretes ?? this.lembretes,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
