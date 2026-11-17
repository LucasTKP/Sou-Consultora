import 'package:sou_consultora/core/model/endereco.dart';

/// Espelho da tabela `enderecos` (sem `consultora_id`, que o app não usa).
class EnderecoDto {
  const EnderecoDto({
    required this.id,
    this.cep,
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.uf,
    this.referencia,
  });

  factory EnderecoDto.fromJson(Map<String, dynamic> json) {
    return EnderecoDto(
      id: json['id'] as String,
      cep: json['cep'] as String?,
      rua: json['rua'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      uf: json['uf'] as String?,
      referencia: json['referencia'] as String?,
    );
  }

  final String id;
  final String? cep;
  final String? rua;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? uf;
  final String? referencia;

  Endereco paraModel() {
    return Endereco(
      cep: cep,
      rua: rua,
      numero: numero,
      complemento: complemento,
      bairro: bairro,
      cidade: cidade,
      uf: uf,
      referencia: referencia,
    );
  }
}
