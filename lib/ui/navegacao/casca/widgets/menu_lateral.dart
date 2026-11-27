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
    required this.caminhoAtual,
    required this.onNavegar,
    this.qtdAtrasadas = 0,
  });

  final ResumoConsultora resumo;
  final String caminhoAtual;

  /// Recebe a rota escolhida; quem chama fecha o menu e navega.
  final ValueChanged<String> onNavegar;

  /// Parcelas atrasadas: selo em A Receber (0 = sem selo).
  final int qtdAtrasadas;

  static const _principais = [
    (RotasApp.inicio, 'Início', Icons.home_rounded),
    (RotasApp.vendas, 'Vendas', Icons.shopping_bag_outlined),
    (RotasApp.clientes, 'Clientes', Icons.people_alt_outlined),
    (RotasApp.produtos, 'Produtos & Estoque', Icons.inventory_2_outlined),
    (RotasApp.servicos, 'Serviços', Icons.spa_outlined),
    (RotasApp.fornecedores, 'Fornecedores', Icons.local_shipping_outlined),
  ];

  static const _financeiros = [
    (RotasApp.aReceber, 'A Receber', Icons.payments_outlined),
    (RotasApp.aPagar, 'A Pagar', Icons.receipt_long_outlined),
    (RotasApp.financeiro, 'Financeiro', Icons.account_balance_wallet_outlined),
  ];

  String? get _rotaAtual => RotasApp.moduloDe(caminhoAtual)?.rota;

  bool _contemRota(List<(String, String, IconData)> itens) =>
      itens.any((item) => item.$1 == _rotaAtual);

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
              padding: EdgeInsets.only(
                top: 12,
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _GrupoMenu(
                  titulo: 'Navegação principal',
                  icone: Icons.grid_view_rounded,
                  itens: _principais.map(_item).toList(),
                ),
                _GrupoMenu(
                  titulo: 'Gestão financeira',
                  icone: Icons.account_balance_wallet_outlined,
                  aberto: _contemRota(_financeiros),
                  itens: _financeiros.map(_item).toList(),
                ),
                ItemMenuLateral(
                  rotulo: 'Configurações',
                  icone: Icons.settings_outlined,
                  onTap: () => onNavegar(RotasApp.perfil),
                ),
              ],
            ),
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
      selo: rota == RotasApp.aReceber && qtdAtrasadas > 0 ? qtdAtrasadas : null,
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
      color: CoresApp.primaria,
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
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 24,
                      color: CoresApp.sobrePrimaria,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resumo.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: CoresApp.sobrePrimaria),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onVerPerfil,
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      foregroundColor: CoresApp.sobrePrimaria,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Ver perfil'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Categoria do menu: fechada até a pessoa escolher abrir.
class _GrupoMenu extends StatelessWidget {
  const _GrupoMenu({
    required this.titulo,
    required this.icone,
    required this.itens,
    this.aberto = false,
  });

  final String titulo;
  final IconData icone;
  final List<Widget> itens;

  /// Começa aberto (ex.: categoria que contém a tela atual).
  final bool aberto;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleMedium;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: aberto,
        leading: Icon(icone, color: CoresApp.sobreSuperficieVariante),
        iconColor: CoresApp.primariaEscura,
        collapsedIconColor: CoresApp.sobreSuperficieVariante,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.only(left: 12),
        title: Text(titulo, style: estilo),
        children: itens,
      ),
    );
  }
}
