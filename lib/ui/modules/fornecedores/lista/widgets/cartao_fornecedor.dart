import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/modules/fornecedores/widgets/selo_status_fornecedor.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Card do fornecedor na lista: iniciais, nome, boletos em aberto e selo.
class CartaoFornecedor extends StatelessWidget {
  const CartaoFornecedor({
    super.key,
    required this.fornecedor,
    required this.onTap,
  });

  final ResumoFornecedor fornecedor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: fornecedor.nome,
      subtitulo: fornecedor.textoBoletosEmAberto,
      inicio: AvatarApp(iniciais: fornecedor.iniciais),
      selo: SeloStatusFornecedor(fornecedor: fornecedor),
      onTap: onTap,
    );
  }
}
