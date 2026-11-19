// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/clientes_dados_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/clientes_dados_state.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/widgets/campo_leitura.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

class ClientesDadosScreen extends StatelessWidget {
  const ClientesDadosScreen({super.key, required this.idCliente});

  final String idCliente;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientesDadosCubit(idCliente: idCliente),
      child: const _DadosVista(),
    );
  }
}

class _DadosVista extends StatelessWidget {
  const _DadosVista();

  void _aoAvisar(BuildContext context, ClientesDadosState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<ClientesDadosCubit>().limparAviso();
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<ClientesDadosCubit>();
    final salvou = await context.push<bool>(RotasApp.editarCliente(id));
    if (salvou == true) await cubit.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientesDadosCubit, ClientesDadosState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final cliente = estado.cliente;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Dados Cadastrais'),
              Expanded(child: _corpo(context, estado)),
              if (cliente != null)
                SafeArea(
                  top: false,
                  minimum: EspacosApp.margemRodape,
                  child: BotaoApp(
                    rotulo: 'Editar',
                    onPressed: () => _editar(context, cliente.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, ClientesDadosState estado) {
    final cliente = estado.cliente;
    if (cliente != null) return _Conteudo(cliente: cliente);
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ClientesDadosCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final nascimento = cliente.dataNascimento;
    final observacoes = cliente.observacoes?.trim() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: AvatarApp(
            iniciais: Cliente.iniciaisDe(cliente.nome),
            tamanho: TamanhoAvatar.destaque,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          cliente.nome,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        const TituloSecaoApp(
          titulo: 'Identificação Pessoal',
          icone: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        CampoLeitura(
          rotulo: 'Nome completo',
          valor: cliente.nome,
          icone: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        CampoLeitura(
          rotulo: 'Telefone / WhatsApp',
          valor: FormatadorTelefone.formatar(cliente.whatsapp),
          icone: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        const _BotaoWhatsapp(),
        if (nascimento != null) ...[
          const SizedBox(height: 20),
          CampoLeitura(
            rotulo: 'Data de aniversário',
            valor: FormatadorData.diaMes(nascimento),
            icone: Icons.cake_outlined,
          ),
        ],
        const SizedBox(height: 32),
        const TituloSecaoApp(
          titulo: 'Endereço de Entrega',
          icone: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 20),
        if (cliente.temEndereco)
          ..._endereco(cliente.endereco!)
        else
          const _SemEndereco(),
        if (observacoes.isNotEmpty) ...[
          const SizedBox(height: 32),
          const TituloSecaoApp(
            titulo: 'Preferências & Observações',
            icone: Icons.favorite_border_rounded,
          ),
          const SizedBox(height: 20),
          CampoLeitura(
            rotulo: 'Notas de venda e pagamento',
            valor: observacoes,
          ),
        ],
      ],
    );
  }

  List<Widget> _endereco(Endereco endereco) {
    final cep = endereco.cep;
    final lugar = endereco.linhaBairroCidade;
    final rua = endereco.linhaRua;
    final referencia = endereco.referencia?.trim() ?? '';
    final linhas = [
      if (cep != null && cep.isNotEmpty)
        CampoLeitura(
          rotulo: 'CEP',
          valor: MascaraCep.formatar(cep),
          icone: Icons.place_outlined,
        ),
      if (lugar != null)
        CampoLeitura(
          rotulo: 'Bairro & Cidade',
          valor: lugar,
          icone: Icons.location_city_outlined,
        ),
      if (rua != null)
        CampoLeitura(
          rotulo: 'Rua / Logradouro',
          valor: rua,
          icone: Icons.home_outlined,
        ),
      if (referencia.isNotEmpty)
        CampoLeitura(
          rotulo: 'Ponto de referência',
          valor: referencia,
          icone: Icons.near_me_outlined,
        ),
    ];
    return [
      for (final (indice, linha) in linhas.indexed) ...[
        if (indice > 0) const SizedBox(height: 20),
        linha,
      ],
    ];
  }
}

class _BotaoWhatsapp extends StatelessWidget {
  const _BotaoWhatsapp();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresApp.sucessoContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: CoresApp.sucesso.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: context.read<ClientesDadosCubit>().abrirWhatsapp,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_rounded, color: CoresApp.sucesso),
              const SizedBox(width: 10),
              Text(
                'Abrir WhatsApp',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: CoresApp.sucesso),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemEndereco extends StatelessWidget {
  const _SemEndereco();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Endereço não cadastrado',
      style: Theme.of(context).textTheme.bodyLarge
          ?.copyWith(color: CoresApp.sobreSuperficieVariante),
    );
  }
}
