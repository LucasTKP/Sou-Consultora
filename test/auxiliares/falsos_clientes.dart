import 'dart:async';

import 'package:sou_consultora/core/dto/cliente_dto.dart';
import 'package:sou_consultora/core/dto/endereco_dto.dart';
import 'package:sou_consultora/core/dto/resumo_cliente_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/service/servico_cep.dart';
import 'package:sou_consultora/core/service/servico_clientes.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

const falhaRedeClientes = FalhaRede(
  'Sem conexão com a internet. Verifique e tente novamente.',
);

ResumoClienteDto resumoDto(
  String id,
  String nome, {
  int saldo = 0,
  int atrasado = 0,
  int venceHoje = 0,
  int qtdAtrasadas = 0,
  int compras = 0,
  int total = 0,
  DateTime? nascimento,
}) {
  return ResumoClienteDto(
    id: id,
    nome: nome,
    whatsapp: '11987654321',
    dataNascimento: nascimento,
    createdAt: DateTime(2025, 1, 10),
    qtdCompras: compras,
    totalCompras: total,
    saldoDevedor: saldo,
    valorAtrasado: atrasado,
    valorVenceHoje: venceHoje,
    qtdAtrasadas: qtdAtrasadas > 0 ? qtdAtrasadas : (atrasado > 0 ? 1 : 0),
  );
}

/// Service falso em memória: guarda as clientes e registra as chamadas.
class ServicoClientesFalso implements ServicoClientes {
  ServicoClientesFalso({
    List<ResumoClienteDto>? resumos,
    Map<String, ClienteDto>? clientes,
  }) : resumos = resumos ?? [],
       clientes = clientes ?? {};

  List<ResumoClienteDto> resumos;
  Map<String, ClienteDto> clientes;
  bool falharRede = false;
  bool falharSalvar = false;
  final List<String> chamadas = [];
  final List<Map<String, dynamic>> salvos = [];
  int _contador = 0;

  @override
  Future<Resultado<List<ResumoClienteDto>>> listarResumos() async {
    chamadas.add('listar');
    return falharRede ? Erro(falhaRedeClientes) : Sucesso(List.of(resumos));
  }

  @override
  Future<Resultado<ResumoClienteDto?>> buscarResumo(String id) async {
    chamadas.add('resumo $id');
    if (falharRede) return Erro(falhaRedeClientes);
    return Sucesso(resumos.where((r) => r.id == id).firstOrNull);
  }

  @override
  Future<Resultado<ClienteDto?>> buscarCliente(String id) async {
    chamadas.add('cliente $id');
    return falharRede ? Erro(falhaRedeClientes) : Sucesso(clientes[id]);
  }

  @override
  Future<Resultado<String>> salvar({
    required String? id,
    required String nome,
    required String whatsapp,
    required DateTime? dataNascimento,
    required String? observacoes,
    required Map<String, String?>? endereco,
  }) async {
    chamadas.add('salvar');
    if (falharRede || falharSalvar) return Erro(falhaRedeClientes);
    final novoId = id ?? 'nova-${++_contador}';
    salvos.add({
      'id': id,
      'nome': nome,
      'whatsapp': whatsapp,
      'nascimento': dataNascimento,
      'observacoes': observacoes,
      'endereco': endereco,
    });
    resumos = [
      ...resumos.where((r) => r.id != novoId),
      resumoDto(novoId, nome, nascimento: dataNascimento),
    ];
    clientes[novoId] = ClienteDto(
      id: novoId,
      nome: nome,
      whatsapp: whatsapp,
      dataNascimento: dataNascimento,
      observacoes: observacoes,
      createdAt: DateTime(2026, 11, 17),
      endereco: endereco == null
          ? null
          : EnderecoDto(
              id: 'e-$novoId',
              cep: endereco['cep'],
              rua: endereco['rua'],
              numero: endereco['numero'],
              complemento: endereco['complemento'],
              bairro: endereco['bairro'],
              cidade: endereco['cidade'],
              uf: endereco['uf'],
              referencia: endereco['referencia'],
            ),
    );
    return Sucesso(novoId);
  }
}

class ServicoCepFalso implements ServicoCep {
  Resultado<Endereco?> resposta = const Sucesso(
    Endereco(
      cep: '01001000',
      rua: 'Praça da Sé',
      bairro: 'Sé',
      cidade: 'São Paulo',
      uf: 'SP',
    ),
  );
  final List<String> consultas = [];

  @override
  Future<Resultado<Endereco?>> buscar(String cep) async {
    consultas.add(cep);
    return resposta;
  }
}

class ServicoWhatsappFalso implements ServicoWhatsapp {
  bool abre = true;
  final List<String> aberturas = [];

  /// Mensagens enviadas junto (null quando abriu sem mensagem).
  final List<String?> mensagens = [];

  @override
  Future<Resultado<void>> abrirConversa(
    String whatsapp, {
    String? mensagem,
  }) async {
    aberturas.add(whatsapp);
    mensagens.add(mensagem);
    return abre
        ? const Sucesso(null)
        : Erro(const FalhaInesperada('Não foi possível abrir o WhatsApp'));
  }
}

RepositorioClientes repositorioClientesDeTeste(
  ServicoClientesFalso servico, {
  ServicoCepFalso? cep,
  ServicoWhatsappFalso? whatsapp,
  Stream<void>? sessaoEncerrada,
}) {
  return RepositorioClientes(
    servico: servico,
    cep: cep ?? ServicoCepFalso(),
    whatsapp: whatsapp ?? ServicoWhatsappFalso(),
    sessaoEncerrada: sessaoEncerrada,
  );
}
