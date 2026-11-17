import 'dart:typed_data';

import 'package:sou_consultora/core/dto/resumo_servico_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/servico.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/service/servico_servicos.dart';

import 'falsos_consultora.dart';

ResumoServicoDto servicoDto(
  String id,
  String nome, {
  int preco = 15000,
  int? custo,
  int? duracao,
  String categoriaId = 's1',
  String categoriaNome = 'Unhas',
  String? observacoes,
  String? fotoUrl,
}) => ResumoServicoDto(
  id: id,
  categoriaId: categoriaId,
  nome: nome,
  precoCobrado: preco,
  custoMateriais: custo,
  duracaoMinutos: duracao,
  observacoes: observacoes,
  fotoUrl: fotoUrl,
  createdAt: DateTime(2026, 1, 10),
  categoriaNome: categoriaNome,
);

/// Service falso em memória: guarda os serviços e registra as chamadas.
class ServicoServicosFalso implements ServicoServicos {
  ServicoServicosFalso({List<ResumoServicoDto>? resumos})
    : resumos = resumos ?? [];

  List<ResumoServicoDto> resumos;
  bool falharRede = false;
  final List<({String? id, Servico servico})> salvos = [];
  final List<String> fotosRemovidas = [];
  int _contador = 0;

  static const _falha = FalhaRede(
    'Sem conexão com a internet. Verifique e tente novamente.',
  );

  @override
  Future<Resultado<List<ResumoServicoDto>>> listarResumos() async =>
      falharRede ? Erro(_falha) : Sucesso(List.of(resumos));

  @override
  Future<Resultado<ResumoServicoDto?>> buscarResumo(String id) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(resumos.where((r) => r.id == id).firstOrNull);
  }

  @override
  Future<Resultado<String>> criar(Servico servico) => _salvar(null, servico);

  @override
  Future<Resultado<String>> atualizar(String id, Servico servico) =>
      _salvar(id, servico);

  @override
  Future<Resultado<String>> enviarFoto(Uint8List bytes) async =>
      falharRede ? Erro(_falha) : Sucesso('u1/servicos/${++_contador}.jpg');

  @override
  Future<Resultado<void>> removerFoto(String caminho) async {
    fotosRemovidas.add(caminho);
    return const Sucesso(null);
  }

  @override
  Future<Resultado<Map<String, String>>> urlsDasFotos(
    List<String> caminhos,
  ) async => Sucesso({for (final c in caminhos) c: 'https://assinada/$c'});

  Future<Resultado<String>> _salvar(String? id, Servico servico) async {
    if (falharRede) return Erro(_falha);
    final novoId = id ?? 'novo-${++_contador}';
    salvos.add((id: id, servico: servico));
    final categoriaNome = servico.categoriaId == 's2' ? 'Maquiagem' : 'Unhas';
    resumos = [
      ...resumos.where((r) => r.id != novoId),
      servicoDto(
        novoId,
        servico.nome,
        preco: servico.precoCobradoCentavos,
        custo: servico.custoMateriaisCentavos,
        duracao: servico.duracaoMinutos,
        categoriaId: servico.categoriaId,
        categoriaNome: categoriaNome,
        observacoes: servico.observacoes,
        fotoUrl: servico.caminhoFoto,
      ),
    ];
    return Sucesso(novoId);
  }
}

RepositorioServicos repositorioServicosDeTeste(
  ServicoServicosFalso servico, {
  FotoDispositivoFalsa? fotos,
}) => RepositorioServicos(
  servico: servico,
  fotos: fotos ?? FotoDispositivoFalsa(),
);
