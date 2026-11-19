import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Cadastro/edição da cliente em dois passos (dados → endereço).
class ClientesFormularioState {
  const ClientesFormularioState({
    this.idCliente,
    this.carregando = false,
    this.erroCarregar,
    this.passo = 1,
    this.nome = '',
    this.whatsapp = '',
    this.nascimento = '',
    this.observacoes = '',
    this.endereco = const Endereco(),
    this.erroNome,
    this.erroWhatsapp,
    this.erroNascimento,
    this.erroCep,
    this.erroRua,
    this.erroNumero,
    this.buscandoCep = false,
    this.aviso,
    this.versaoPreenchimento = 0,
    this.focarNumero = 0,
    this.salvando = false,
    this.salvo = false,
  });

  /// Null = cliente nova.
  final String? idCliente;

  /// Edição: buscando os dados atuais.
  final bool carregando;
  final String? erroCarregar;

  final int passo;
  final String nome;
  final String whatsapp;

  /// Texto digitado "dd/mm/aaaa".
  final String nascimento;
  final String observacoes;
  final Endereco endereco;

  final String? erroNome;
  final String? erroWhatsapp;
  final String? erroNascimento;
  final String? erroCep;
  final String? erroRua;
  final String? erroNumero;

  final bool buscandoCep;

  /// Mensagem passageira (falha ao salvar, CEP não encontrado). Exibida uma vez.
  final AvisoToast? aviso;

  /// Muda quando os campos são preenchidos pelo cubit (edição carregada, CEP):
  /// a tela copia os valores para os campos de texto.
  final int versaoPreenchimento;

  /// Muda quando o foco deve ir para o número (depois do CEP).
  final int focarNumero;

  final bool salvando;
  final bool salvo;

  bool get editando => idCliente != null;

  ClientesFormularioState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    int? passo,
    String? nome,
    String? whatsapp,
    String? nascimento,
    String? observacoes,
    Endereco? endereco,
    String? Function()? erroNome,
    String? Function()? erroWhatsapp,
    String? Function()? erroNascimento,
    String? Function()? erroCep,
    String? Function()? erroRua,
    String? Function()? erroNumero,
    bool? buscandoCep,
    AvisoToast? Function()? aviso,
    int? versaoPreenchimento,
    int? focarNumero,
    bool? salvando,
    bool? salvo,
  }) {
    return ClientesFormularioState(
      idCliente: idCliente,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      passo: passo ?? this.passo,
      nome: nome ?? this.nome,
      whatsapp: whatsapp ?? this.whatsapp,
      nascimento: nascimento ?? this.nascimento,
      observacoes: observacoes ?? this.observacoes,
      endereco: endereco ?? this.endereco,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroWhatsapp: erroWhatsapp != null ? erroWhatsapp() : this.erroWhatsapp,
      erroNascimento: erroNascimento != null
          ? erroNascimento()
          : this.erroNascimento,
      erroCep: erroCep != null ? erroCep() : this.erroCep,
      erroRua: erroRua != null ? erroRua() : this.erroRua,
      erroNumero: erroNumero != null ? erroNumero() : this.erroNumero,
      buscandoCep: buscandoCep ?? this.buscandoCep,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
      focarNumero: focarNumero ?? this.focarNumero,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
    );
  }
}
