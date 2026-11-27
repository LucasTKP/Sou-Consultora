import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/model/telefone.dart';

/// Cliente da consultora com os dados cadastrais completos.
class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    required this.whatsapp,
    this.dataNascimento,
    this.observacoes,
    this.endereco,
  });

  final String id;
  final String nome;

  /// Só dígitos (DDD + número).
  final String whatsapp;
  final DateTime? dataNascimento;
  final String? observacoes;
  final Endereco? endereco;

  bool get temEndereco => endereco != null && !endereco!.vazio;

  static String? validarNome(String texto) =>
      texto.trim().isEmpty ? 'Informe o nome' : null;

  static String? validarWhatsapp(String texto) {
    if (texto.trim().isEmpty) return 'Informe o WhatsApp';
    return Telefone.valido(texto) ? null : 'WhatsApp inválido';
  }

  /// Nascimento é opcional; se informado, precisa ser uma data real e não futura.
  /// [texto] no formato "dd/mm/aaaa"; [data] é o resultado da leitura (null se inválida).
  static String? validarNascimento(
    String texto,
    DateTime? data, {
    required DateTime hoje,
  }) {
    if (texto.trim().isEmpty) return null;
    if (data == null) return 'Data inválida';
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    return data.isAfter(dia) ? 'Data inválida' : null;
  }

  /// Até duas letras: primeira do primeiro nome + primeira do último ("Dona Carla Menezes" → "DM").
  static String iniciaisDe(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}
