// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/item_menu_lateral.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';

/// Menu lateral com o mapa completo do app.
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.resumo,
    required this.versao,
    required this.caminhoAtual,
    required this.onNavegar,
    required this.onSair,
  });

  final ResumoConsultora resumo;
  final String versao;
  final String caminhoAtual;

  /// Recebe a rota escolhida; quem chama fecha o menu e navega.
  final ValueChanged<String> onNavegar;
  final VoidCallback onSair;

  static const _principais = [
    (RotasApp.inicio, 'Início', Icons.home_rounded),
    (RotasApp.vendas, 'Vendas & Pedidos', Icons.shopping_bag_outlined),
    (RotasApp.clientes, 'Clientes', Icons.people_alt_outlined),
    (RotasApp.produtos, 'Produtos & Estoque', Icons.inventory_2_outlined),
    (RotasApp.servicos, 'Serviços', Icons.spa_outlined),
    (
      RotasApp.fornecedores,
      'Fornecedores & Marcas',
      Icons.local_shipping_outlined,
    ),
  ];

  static const _financeiros = [
    (RotasApp.aReceber, 'A Receber / Cobranças', Icons.payments_outlined),
    (RotasApp.aPagar, 'A Pagar / Boletos', Icons.receipt_long_outlined),
    (
      RotasApp.financeiro,
      'Financeiro & Relatórios',
      Icons.account_balance_wallet_outlined,
    ),
  ];

  String? get _rotaAtual => RotasApp.moduloDe(caminhoAtual)?.rota;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: CoresApp.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _Cabecalho(
            resumo: resumo,
            onVerPerfil: () => onNavegar(RotasApp.perfil),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                const _TituloSecao('Navegação principal'),
                ..._principais.map(_item),
                const Divider(indent: 24, endIndent: 24, height: 24),
                const _TituloSecao('Gestão financeira'),
                ..._financeiros.map(_item),
              ],
            ),
          ),
          _Rodape(
            versao: versao,
            onConfiguracoes: () => onNavegar(RotasApp.perfil),
            onSair: onSair,
          ),
        ],
      ),
    );
  }

  Widget _item((String, String, IconData) dados) {
    final (rota, rotulo, icone) = dados;
    return ItemMenuLateral(
      rotulo: rotulo,
      icone: icone,
      atual: rota == _rotaAtual,
      onTap: () => onNavegar(rota),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.resumo, required this.onVerPerfil});

  final ResumoConsultora resumo;
  final VoidCallback onVerPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF0F4),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarApp(
                    urlImagem: resumo.fotoUrl,
                    iniciais: resumo.iniciais,
                    tamanho: TamanhoAvatar.destaque,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Fechar menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                resumo.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onVerPerfil,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Ver perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: CoresApp.sobreSuperficieVariante,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.versao,
    required this.onConfiguracoes,
    required this.onSair,
  });

  final String versao;
  final VoidCallback onConfiguracoes;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF0F4),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            ItemMenuLateral(
              rotulo: 'Configurações',
              icone: Icons.settings_outlined,
              onTap: onConfiguracoes,
            ),
            ItemMenuLateral(
              rotulo: 'Sair da conta',
              icone: Icons.logout_rounded,
              cor: CoresApp.perigo,
              onTap: onSair,
            ),
            if (versao.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Sou Consultora v$versao',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
