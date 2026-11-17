import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/cliente_dto.dart';
import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/dto/resumo_cliente_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Acesso a `clientes`, `enderecos`, à view `resumo_clientes` e à RPC `salvar_cliente`.
/// Nunca envia `consultora_id`: o banco preenche e o RLS confere.
class ServicoClientes {
  ServicoClientes({required this._api});

  final ApiSupabase _api;

  static const _view = 'resumo_clientes';

  Future<Resultado<List<ResumoClienteDto>>> listarResumos() {
    return executarComFalha(() async {
      final linhas = await _api.listar(_view, ordenarPor: 'nome');
      return linhas.map(ResumoClienteDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar as clientes.');
  }

  /// Resumo de uma cliente (Sucesso(null) se não existir ou não for da consultora).
  Future<Resultado<ResumoClienteDto?>> buscarResumo(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(_view, coluna: 'id', valor: id);
      return linha == null ? null : ResumoClienteDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar a cliente.');
  }

  /// Dados cadastrais com o endereço embutido.
  Future<Resultado<ClienteDto?>> buscarCliente(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(
        'clientes',
        coluna: 'id',
        valor: id,
        selecao: '*, enderecos(*)',
      );
      return linha == null ? null : ClienteDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar os dados da cliente.');
  }

  /// Cria ([id] nulo) ou edita a cliente e o endereço numa única transação. Devolve o id.
  Future<Resultado<String>> salvar({
    required String? id,
    required String nome,
    required String whatsapp,
    required DateTime? dataNascimento,
    required String? observacoes,
    required Map<String, String?>? endereco,
  }) {
    return executarComFalha(() async {
      final retorno = await _api.rpc(
        'salvar_cliente',
        parametros: {
          'p_id': id,
          'p_nome': nome,
          'p_whatsapp': whatsapp,
          'p_data_nascimento': ConversoresDto.textoData(dataNascimento),
          'p_observacoes': observacoes,
          'p_endereco': endereco,
        },
      );
      return retorno as String;
    }, mensagemPadrao: 'Não foi possível salvar a cliente.');
  }
}
