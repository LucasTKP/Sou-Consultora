import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/resumo_fornecedor_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';

/// Acesso a `fornecedores` e à view `resumo_fornecedores`.
/// Nunca envia `consultora_id`, `id` nem `created_at`: o banco preenche e o RLS confere.
class ServicoFornecedores {
  ServicoFornecedores({required this._api});

  final ApiSupabase _api;

  static const _tabela = 'fornecedores';
  static const _view = 'resumo_fornecedores';

  Future<Resultado<List<ResumoFornecedorDto>>> listarResumos() {
    return executarComFalha(() async {
      final linhas = await _api.listar(_view, ordenarPor: 'nome');
      return linhas.map(ResumoFornecedorDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os fornecedores.');
  }

  /// Resumo de um fornecedor (Sucesso(null) se não existir ou não for da consultora).
  Future<Resultado<ResumoFornecedorDto?>> buscarResumo(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(_view, coluna: 'id', valor: id);
      return linha == null ? null : ResumoFornecedorDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar o fornecedor.');
  }

  /// Cria o fornecedor (sempre ativo) e devolve o id.
  Future<Resultado<String>> criar(Fornecedor fornecedor) {
    return executarComFalha(
      () async {
        final linha = await _api.inserir(_tabela, _dados(fornecedor));
        return linha['id'] as String;
      },
      mensagemPadrao: 'Não foi possível salvar o fornecedor.',
      mensagemDuplicado: Fornecedor.mensagemDuplicado,
    );
  }

  /// Atualiza o fornecedor [id], inclusive o status em espera.
  Future<Resultado<String>> atualizar(String id, Fornecedor fornecedor) {
    return executarComFalha(
      () async {
        final linha = await _api.atualizar(
          _tabela,
          {..._dados(fornecedor), 'ativo': fornecedor.ativo},
          coluna: 'id',
          valor: id,
        );
        return linha['id'] as String;
      },
      mensagemPadrao: 'Não foi possível salvar o fornecedor.',
      mensagemDuplicado: Fornecedor.mensagemDuplicado,
    );
  }

  static Map<String, dynamic> _dados(Fornecedor fornecedor) => {
    'nome': fornecedor.nome,
    'ramo': fornecedor.ramo,
    'contato': fornecedor.contato,
    'telefone': fornecedor.telefone,
    'observacoes': fornecedor.observacoes,
  };
}
