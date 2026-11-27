import 'package:sou_consultora/core/dto/resumo_fornecedor_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';

import 'falsos_clientes.dart';

const falhaRedeFornecedores = FalhaRede(
  'Sem conexão com a internet. Verifique e tente novamente.',
);

ResumoFornecedorDto fornecedorDto(
  String id,
  String nome, {
  bool ativo = true,
  String? ramo,
  String? contato,
  String? telefone,
  String? observacoes,
  int qtdEmAberto = 0,
  int valorEmAberto = 0,
  int qtdAtrasados = 0,
  int valorAtrasado = 0,
  int qtdVenceHoje = 0,
  int qtdPagos = 0,
  int valorPagos = 0,
  DateTime? criadoEm,
}) {
  return ResumoFornecedorDto(
    id: id,
    nome: nome,
    ramo: ramo,
    contato: contato,
    telefone: telefone,
    observacoes: observacoes,
    ativo: ativo,
    createdAt: criadoEm ?? DateTime(2023, 3, 10),
    qtdEmAberto: qtdEmAberto,
    valorEmAberto: valorEmAberto,
    qtdAtrasados: qtdAtrasados,
    valorAtrasado: valorAtrasado,
    qtdVenceHoje: qtdVenceHoje,
    qtdPagos: qtdPagos,
    valorPagos: valorPagos,
  );
}

/// Service falso em memória: guarda os fornecedores e registra as chamadas.
class ServicoFornecedoresFalso implements ServicoFornecedores {
  ServicoFornecedoresFalso({List<ResumoFornecedorDto>? resumos})
    : resumos = resumos ?? [];

  List<ResumoFornecedorDto> resumos;
  bool falharRede = false;

  /// Falha específica ao salvar (ex.: nome repetido).
  FalhaApp? falhaAoSalvar;
  final List<String> chamadas = [];
  final List<({String? id, Fornecedor fornecedor})> salvos = [];
  int _contador = 0;

  @override
  Future<Resultado<List<ResumoFornecedorDto>>> listarResumos() async {
    chamadas.add('listar');
    return falharRede ? Erro(falhaRedeFornecedores) : Sucesso(List.of(resumos));
  }

  @override
  Future<Resultado<ResumoFornecedorDto?>> buscarResumo(String id) async {
    chamadas.add('resumo $id');
    if (falharRede) return Erro(falhaRedeFornecedores);
    return Sucesso(resumos.where((r) => r.id == id).firstOrNull);
  }

  @override
  Future<Resultado<String>> criar(Fornecedor fornecedor) =>
      _salvar(null, fornecedor);

  @override
  Future<Resultado<String>> atualizar(String id, Fornecedor fornecedor) =>
      _salvar(id, fornecedor);

  Future<Resultado<String>> _salvar(String? id, Fornecedor fornecedor) async {
    chamadas.add(id == null ? 'criar' : 'atualizar $id');
    if (falharRede) return Erro(falhaRedeFornecedores);
    if (falhaAoSalvar case final falha?) return Erro(falha);
    final novoId = id ?? 'novo-${++_contador}';
    salvos.add((id: id, fornecedor: fornecedor));
    resumos = [
      ...resumos.where((r) => r.id != novoId),
      fornecedorDto(
        novoId,
        fornecedor.nome,
        ativo: fornecedor.ativo,
        ramo: fornecedor.ramo,
        contato: fornecedor.contato,
        telefone: fornecedor.telefone,
        observacoes: fornecedor.observacoes,
      ),
    ];
    return Sucesso(novoId);
  }
}

RepositorioFornecedores repositorioFornecedoresDeTeste(
  ServicoFornecedoresFalso servico, {
  ServicoWhatsappFalso? whatsapp,
  Stream<void>? sessaoEncerrada,
}) {
  return RepositorioFornecedores(
    servico: servico,
    whatsapp: whatsapp ?? ServicoWhatsappFalso(),
    sessaoEncerrada: sessaoEncerrada,
  );
}
