import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/pagamento.dart';

class AReceberComprovanteState {
  const AReceberComprovanteState({
    this.detalhe,
    this.pagamento,
    this.consultora,
    this.carregando = true,
    this.erro,
    this.compartilhando = false,
    this.aviso,
  });

  final DetalheParcela? detalhe;

  /// O pagamento mostrado (o recém-registrado ou o último da parcela).
  final Pagamento? pagamento;

  /// Nome, chave Pix e foto no comprovante.
  final Consultora? consultora;
  final bool carregando;
  final String? erro;
  final bool compartilhando;
  final String? aviso;

  bool get pronto => detalhe != null && pagamento != null;

  AReceberComprovanteState copyWith({
    DetalheParcela? detalhe,
    Pagamento? pagamento,
    bool? carregando,
    String? Function()? erro,
    bool? compartilhando,
    String? Function()? aviso,
  }) {
    return AReceberComprovanteState(
      detalhe: detalhe ?? this.detalhe,
      pagamento: pagamento ?? this.pagamento,
      consultora: consultora,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      compartilhando: compartilhando ?? this.compartilhando,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
