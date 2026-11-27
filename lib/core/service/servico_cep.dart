import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sou_consultora/core/api/cliente_http_com_registro.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/endereco.dart';

/// Consulta de endereço pelo CEP. Só o CEP sai do app.
abstract interface class ServicoCep {
  /// Sucesso(null) = CEP não encontrado.
  Future<Resultado<Endereco?>> buscar(String cep);
}

/// Implementação com o ViaCEP (serviço público e gratuito).
class ServicoCepViaCep implements ServicoCep {
  ServicoCepViaCep({
    http.Client? cliente,
    this.limite = const Duration(seconds: 8),
  }) : _cliente = cliente ?? ClienteHttpComRegistro();

  final http.Client _cliente;
  final Duration limite;

  @override
  Future<Resultado<Endereco?>> buscar(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return const Sucesso(null);
    return executarComFalha(() async {
      final resposta = await _cliente
          .get(Uri.https('viacep.com.br', '/ws/$digitos/json/'))
          .timeout(limite);
      if (resposta.statusCode == 400 || resposta.statusCode == 404) return null;
      if (resposta.statusCode != 200) {
        throw http.ClientException('ViaCEP ${resposta.statusCode}');
      }
      return _paraEndereco(
        digitos,
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
      );
    }, mensagemPadrao: 'Não foi possível consultar o CEP.');
  }

  Endereco? _paraEndereco(String cep, Map<String, dynamic> json) {
    if (json['erro'] != null) return null;
    String? texto(String chave) {
      final valor = (json[chave] as String?)?.trim();
      return valor == null || valor.isEmpty ? null : valor;
    }

    return Endereco(
      cep: cep,
      rua: texto('logradouro'),
      bairro: texto('bairro'),
      cidade: texto('localidade'),
      uf: texto('uf'),
    );
  }
}
