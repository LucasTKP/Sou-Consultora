import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/marca_padrao.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_cubit.dart';

import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';

class _AutenticacaoFalsa implements RepositorioAutenticacao {
  @override
  ResumoConsultora resumoDaConsultora() =>
      const ResumoConsultora(nome: 'Ana Paula');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'marcar e desmarcar; o cadastro leva as marcas na ordem do catálogo',
    () async {
      final fornecedores = ServicoFornecedoresFalso();
      final cubit = CadastroCubit(
        autenticacao: _AutenticacaoFalsa(),
        consultoras: repositorioDeTeste(
          ServicoConsultoraFalso(),
          null,
          fornecedores,
        ),
      );

      cubit
        ..alternarMarca(MarcaPadrao.maryKay)
        ..alternarMarca(MarcaPadrao.natura)
        ..alternarMarca(MarcaPadrao.avon)
        ..alternarMarca(MarcaPadrao.avon); // desmarca
      expect(cubit.state.marcas, {MarcaPadrao.maryKay, MarcaPadrao.natura});

      cubit.alterarWhatsapp('(11) 98765-4321');
      await cubit.continuar();

      expect(fornecedores.salvos.map((s) => s.fornecedor.nome), [
        'Natura',
        'Mary Kay',
      ]);
      await cubit.close();
    },
  );
}
