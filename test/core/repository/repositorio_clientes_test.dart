import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/endereco.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';

import '../../auxiliares/falsos_clientes.dart';

void main() {
  test(
    'salvar grava com WhatsApp só em dígitos, recarrega e emite a lista nova',
    () async {
      final servico = ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')]);
      final repositorio = repositorioClientesDeTeste(servico);
      await repositorio.carregar();
      final emitidas = <List<ResumoCliente>>[];
      final assinatura = repositorio.mudancas.listen(emitidas.add);

      final resultado = await repositorio.salvar(
        nome: ' Bia ',
        whatsapp: '(11) 91234-5678',
        endereco: const Endereco(rua: '  '),
      );
      await Future<void>.delayed(Duration.zero);

      expect(resultado, isA<Sucesso<String>>());
      expect(servico.salvos.single['nome'], 'Bia');
      expect(servico.salvos.single['whatsapp'], '11912345678');
      expect(
        servico.salvos.single['endereco'],
        isNull,
        reason: 'endereço em branco não é gravado',
      );
      expect(emitidas.last.map((c) => c.nome), ['Ana', 'Bia']);
      expect(repositorio.resumoEmCache('nova-1')?.nome, 'Bia');
      await assinatura.cancel();
    },
  );

  test('falha ao salvar não altera o cache', () async {
    final servico = ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')]);
    final repositorio = repositorioClientesDeTeste(servico);
    await repositorio.carregar();
    servico.falharSalvar = true;

    final resultado = await repositorio.salvar(
      nome: 'Bia',
      whatsapp: '11912345678',
    );

    expect(resultado, isA<Erro<String>>());
    expect(repositorio.lista!.map((c) => c.nome), ['Ana']);
    expect(servico.chamadas.where((c) => c == 'listar'), hasLength(1));
  });

  test('sessão encerrada esquece as clientes', () async {
    final sessao = StreamController<void>();
    final repositorio = repositorioClientesDeTeste(
      ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')]),
      sessaoEncerrada: sessao.stream,
    );
    await repositorio.carregar();

    sessao.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(repositorio.lista, isNull);
    expect(repositorio.resumoEmCache('c1'), isNull);
    await sessao.close();
  });
}
