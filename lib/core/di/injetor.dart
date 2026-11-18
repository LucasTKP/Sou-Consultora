import 'package:get_it/get_it.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/service/servico_cep.dart';
import 'package:sou_consultora/core/service/servico_clientes.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';
import 'package:sou_consultora/core/service/servico_categorias.dart';
import 'package:sou_consultora/core/service/servico_estoque.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_produtos.dart';
import 'package:sou_consultora/core/service/servico_compartilhar.dart';
import 'package:sou_consultora/core/service/servico_recebimentos.dart';
import 'package:sou_consultora/core/service/servico_servicos.dart';
import 'package:sou_consultora/core/service/servico_vendas.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';
import 'package:sou_consultora/core/service/servico_autenticacao.dart';

final GetIt injetor = GetIt.instance;

/// Registra as dependências compartilhadas do app.
void configurarDependencias() {
  if (!injetor.isRegistered<ApiSupabase>()) {
    injetor.registerLazySingleton<ApiSupabase>(ApiSupabase.new);
  }

  if (!injetor.isRegistered<ServicoAutenticacao>()) {
    injetor.registerLazySingleton<ServicoAutenticacao>(
      () => ServicoAutenticacao(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioAutenticacao>()) {
    injetor.registerLazySingleton<RepositorioAutenticacao>(
      () => RepositorioAutenticacao(servico: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoConsultora>()) {
    injetor.registerLazySingleton<ServicoConsultora>(
      () => ServicoConsultora(api: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoFotoDispositivo>()) {
    injetor.registerLazySingleton<ServicoFotoDispositivo>(
      ServicoFotoDispositivoNativo.new,
    );
  }

  if (!injetor.isRegistered<RepositorioConsultora>()) {
    injetor.registerLazySingleton<RepositorioConsultora>(
      () => RepositorioConsultora(servico: injetor(), fotos: injetor()),
    );
  }

  _registrarClientes();
  _registrarFornecedores();
  _registrarProdutos();
  _registrarVendas();
}

void _registrarClientes() {
  if (!injetor.isRegistered<ServicoClientes>()) {
    injetor.registerLazySingleton<ServicoClientes>(
      () => ServicoClientes(api: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoCep>()) {
    injetor.registerLazySingleton<ServicoCep>(ServicoCepViaCep.new);
  }

  if (!injetor.isRegistered<ServicoWhatsapp>()) {
    injetor.registerLazySingleton<ServicoWhatsapp>(ServicoWhatsappNativo.new);
  }

  if (!injetor.isRegistered<RepositorioClientes>()) {
    injetor.registerLazySingleton<RepositorioClientes>(
      () => RepositorioClientes(
        servico: injetor(),
        cep: injetor(),
        whatsapp: injetor(),
        // Consultora nula = sessão encerrada: esquece as clientes da conta anterior.
        sessaoEncerrada: injetor<RepositorioConsultora>().mudancas.where(
          (consultora) => consultora == null,
        ),
      ),
    );
  }
}

void _registrarFornecedores() {
  if (!injetor.isRegistered<ServicoFornecedores>()) {
    injetor.registerLazySingleton<ServicoFornecedores>(
      () => ServicoFornecedores(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioFornecedores>()) {
    injetor.registerLazySingleton<RepositorioFornecedores>(
      () => RepositorioFornecedores(
        servico: injetor(),
        whatsapp: injetor(),
        // Consultora nula = sessão encerrada: esquece os fornecedores da conta anterior.
        sessaoEncerrada: injetor<RepositorioConsultora>().mudancas.where(
          (consultora) => consultora == null,
        ),
      ),
    );
  }
}

void _registrarProdutos() {
  // Consultora nula = sessão encerrada: esquece os dados da conta anterior.
  Stream<void> sessaoEncerrada() => injetor<RepositorioConsultora>().mudancas
      .where((consultora) => consultora == null);

  if (!injetor.isRegistered<ServicoCategorias>()) {
    injetor.registerLazySingleton<ServicoCategorias>(
      () => ServicoCategorias(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioCategorias>()) {
    injetor.registerLazySingleton<RepositorioCategorias>(
      () => RepositorioCategorias(
        servico: injetor(),
        sessaoEncerrada: sessaoEncerrada(),
      ),
    );
  }

  if (!injetor.isRegistered<ServicoProdutos>()) {
    injetor.registerLazySingleton<ServicoProdutos>(
      () => ServicoProdutos(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioProdutos>()) {
    injetor.registerLazySingleton<RepositorioProdutos>(
      () => RepositorioProdutos(
        servico: injetor(),
        fotos: injetor(),
        sessaoEncerrada: sessaoEncerrada(),
      ),
    );
  }

  if (!injetor.isRegistered<ServicoServicos>()) {
    injetor.registerLazySingleton<ServicoServicos>(
      () => ServicoServicos(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioServicos>()) {
    injetor.registerLazySingleton<RepositorioServicos>(
      () => RepositorioServicos(
        servico: injetor(),
        fotos: injetor(),
        sessaoEncerrada: sessaoEncerrada(),
      ),
    );
  }

  if (!injetor.isRegistered<ServicoEstoque>()) {
    injetor.registerLazySingleton<ServicoEstoque>(
      () => ServicoEstoque(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioEstoque>()) {
    injetor.registerLazySingleton<RepositorioEstoque>(
      () => RepositorioEstoque(servico: injetor(), produtos: injetor()),
    );
  }
}

void _registrarVendas() {
  if (!injetor.isRegistered<ServicoVendas>()) {
    injetor.registerLazySingleton<ServicoVendas>(
      () => ServicoVendas(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioVendas>()) {
    injetor.registerLazySingleton<RepositorioVendas>(
      () => RepositorioVendas(
        servico: injetor(),
        produtos: injetor(),
        clientes: injetor(),
        whatsapp: injetor(),
        // Consultora nula = sessão encerrada: esquece as vendas da conta anterior.
        sessaoEncerrada: injetor<RepositorioConsultora>().mudancas.where(
          (consultora) => consultora == null,
        ),
      ),
    );
  }

  if (!injetor.isRegistered<ServicoCompartilhar>()) {
    injetor.registerLazySingleton<ServicoCompartilhar>(
      ServicoCompartilharNativo.new,
    );
  }

  if (!injetor.isRegistered<ServicoRecebimentos>()) {
    injetor.registerLazySingleton<ServicoRecebimentos>(
      () => ServicoRecebimentos(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioRecebimentos>()) {
    injetor.registerLazySingleton<RepositorioRecebimentos>(
      () => RepositorioRecebimentos(
        vendas: injetor(),
        recebimentos: injetor(),
        repositorioVendas: injetor(),
        clientes: injetor(),
        compartilhar: injetor(),
        sessaoEncerrada: injetor<RepositorioConsultora>().mudancas.where(
          (consultora) => consultora == null,
        ),
      ),
    );
  }
}
