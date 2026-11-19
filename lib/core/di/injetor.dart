import 'package:get_it/get_it.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';
import 'package:sou_consultora/core/service/servico_dicas.dart';
import 'package:sou_consultora/core/service/servico_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';
import 'package:sou_consultora/core/env/ambiente_app.dart';
import 'package:sou_consultora/core/service/servico_configuracoes.dart';
import 'package:sou_consultora/core/service/servico_info_app.dart';
import 'package:sou_consultora/core/service/servico_abrir_link.dart';
import 'package:sou_consultora/core/service/servico_boletos.dart';
import 'package:sou_consultora/core/service/servico_cep.dart';
import 'package:sou_consultora/core/service/servico_escolher_comprovante.dart';
import 'package:sou_consultora/core/service/servico_clientes.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';
import 'package:sou_consultora/core/service/servico_categorias.dart';
import 'package:sou_consultora/core/service/servico_estoque.dart';
import 'package:sou_consultora/core/service/servico_fornecedores.dart';
import 'package:sou_consultora/core/service/servico_inicio.dart';
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

  if (!injetor.isRegistered<ServicoFornecedores>()) {
    injetor.registerLazySingleton<ServicoFornecedores>(
      () => ServicoFornecedores(api: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoFotoDispositivo>()) {
    injetor.registerLazySingleton<ServicoFotoDispositivo>(
      ServicoFotoDispositivoNativo.new,
    );
  }

  if (!injetor.isRegistered<RepositorioConsultora>()) {
    injetor.registerLazySingleton<RepositorioConsultora>(
      () => RepositorioConsultora(
        servico: injetor(),
        fotos: injetor(),
        fornecedores: injetor(),
      ),
    );
  }

  if (!injetor.isRegistered<ServicoDicas>()) {
    injetor.registerLazySingleton<ServicoDicas>(
      () => ServicoDicasLocal(idUsuario: () => injetor<ApiSupabase>().idUsuario),
    );
  }

  if (!injetor.isRegistered<RepositorioDicas>()) {
    injetor.registerLazySingleton<RepositorioDicas>(
      () => RepositorioDicas(servico: injetor()),
    );
  }

  _registrarVersao();
  _registrarClientes();
  _registrarFornecedores();
  _registrarBoletos();
  _registrarProdutos();
  _registrarVendas();
  _registrarInicio();
}

void _registrarVersao() {
  if (!injetor.isRegistered<ServicoConfiguracoes>()) {
    injetor.registerLazySingleton<ServicoConfiguracoes>(
      () => ServicoConfiguracoes(api: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoInfoApp>()) {
    injetor.registerLazySingleton<ServicoInfoApp>(ServicoInfoAppNativo.new);
  }

  if (!injetor.isRegistered<ServicoAbrirLink>()) {
    injetor.registerLazySingleton<ServicoAbrirLink>(ServicoAbrirLinkNativo.new);
  }

  if (!injetor.isRegistered<RepositorioVersao>()) {
    injetor.registerLazySingleton<RepositorioVersao>(
      () => RepositorioVersao(
        configuracoes: injetor(),
        infoApp: injetor(),
        abrirLink: injetor(),
        urlLojaAndroid: AmbienteApp.urlLojaAndroid,
        urlLojaIos: AmbienteApp.urlLojaIos,
      ),
    );
  }
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

void _registrarBoletos() {
  if (!injetor.isRegistered<ServicoBoletos>()) {
    injetor.registerLazySingleton<ServicoBoletos>(
      () => ServicoBoletos(api: injetor()),
    );
  }

  if (!injetor.isRegistered<ServicoAbrirLink>()) {
    injetor.registerLazySingleton<ServicoAbrirLink>(ServicoAbrirLinkNativo.new);
  }

  if (!injetor.isRegistered<ServicoEscolherComprovante>()) {
    injetor.registerLazySingleton<ServicoEscolherComprovante>(
      ServicoEscolherComprovanteNativo.new,
    );
  }

  if (!injetor.isRegistered<RepositorioBoletos>()) {
    injetor.registerLazySingleton<RepositorioBoletos>(
      () => RepositorioBoletos(
        servico: injetor(),
        fornecedores: injetor(),
        abrirLink: injetor(),
        escolher: injetor(),
        // Consultora nula = sessão encerrada: esquece os boletos da conta anterior.
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

  if (!injetor.isRegistered<ServicoCatalogo>()) {
    injetor.registerLazySingleton<ServicoCatalogo>(
      () => ServicoCatalogo(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioCatalogo>()) {
    injetor.registerLazySingleton<RepositorioCatalogo>(
      () => RepositorioCatalogo(servico: injetor()),
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

void _registrarInicio() {
  if (!injetor.isRegistered<ServicoInicio>()) {
    injetor.registerLazySingleton<ServicoInicio>(
      () => ServicoInicio(api: injetor()),
    );
  }

  if (!injetor.isRegistered<RepositorioInicio>()) {
    injetor.registerLazySingleton<RepositorioInicio>(
      () => RepositorioInicio(
        servico: injetor(),
        recebimentos: injetor(),
        whatsapp: injetor(),
      ),
    );
  }
}
