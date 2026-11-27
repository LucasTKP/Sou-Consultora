import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/dto/endereco_dto.dart';
import 'package:sou_consultora/core/model/cliente.dart';

/// Espelho da tabela `clientes`, com o endereço embutido (`select('*, enderecos(*)')`).
class ClienteDto {
  const ClienteDto({
    required this.id,
    required this.nome,
    required this.whatsapp,
    required this.createdAt,
    this.enderecoId,
    this.dataNascimento,
    this.observacoes,
    this.endereco,
  });

  factory ClienteDto.fromJson(Map<String, dynamic> json) {
    final endereco = json['enderecos'] as Map<String, dynamic>?;
    return ClienteDto(
      id: json['id'] as String,
      enderecoId: json['endereco_id'] as String?,
      nome: json['nome'] as String,
      whatsapp: json['whatsapp'] as String,
      dataNascimento: ConversoresDto.data(json['data_nascimento']),
      observacoes: json['observacoes'] as String?,
      createdAt: ConversoresDto.momento(json['created_at'])!,
      endereco: endereco == null ? null : EnderecoDto.fromJson(endereco),
    );
  }

  final String id;
  final String? enderecoId;
  final String nome;
  final String whatsapp;
  final DateTime? dataNascimento;
  final String? observacoes;
  final DateTime createdAt;
  final EnderecoDto? endereco;

  Cliente paraModel() {
    return Cliente(
      id: id,
      nome: nome,
      whatsapp: whatsapp,
      dataNascimento: dataNascimento,
      observacoes: observacoes,
      endereco: endereco?.paraModel(),
    );
  }
}
