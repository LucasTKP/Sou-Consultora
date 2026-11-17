import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

import '../../auxiliares/falsos_fornecedores.dart';

void main() {
  test('salvar grava, recarrega e emite a lista nova', () async {
    final servico = ServicoFornecedoresFalso(
      resumos: [fornecedorDto('f1', 'Natura')],
    );
    final repositorio = repositorioFornecedoresDeTeste(servico);
    await repositorio.carregar();
    final emitidas = <List<ResumoFornecedor>>[];
    final assinatura = repositorio.mudancas.listen(emitidas.add);

    final resultado = await repositorio.salvar(Fornecedor(nome: 'Hinode'));
    await Future<void>.delayed(Duration.zero);

    expect(resultado, isA<Sucesso<String>>());
    expect(servico.chamadas, ['listar', 'criar', 'listar']);
    expect(emitidas.last.map((f) => f.nome), ['Natura', 'Hinode']);
    expect(repositorio.resumoEmCache('novo-1')?.nome, 'Hinode');
    await assinatura.cancel();
  });

  test('editar com id usa atualizar', () async {
    final servico = ServicoFornecedoresFalso(
      resumos: [fornecedorDto('f1', 'Natura')],
    );
    final repositorio = repositorioFornecedoresDeTeste(servico);

    await repositorio.salvar(
      Fornecedor(nome: 'Natura', ativo: false),
      id: 'f1',
    );

    expect(servico.chamadas.first, 'atualizar f1');
    expect(repositorio.resumoEmCache('f1')?.emEspera, isTrue);
  });

  test('falha ao salvar não altera o cache', () async {
    final servico = ServicoFornecedoresFalso(
      resumos: [fornecedorDto('f1', 'Natura')],
    );
    final repositorio = repositorioFornecedoresDeTeste(servico);
    await repositorio.carregar();
    servico.falharRede = true;

    final resultado = await repositorio.salvar(Fornecedor(nome: 'Hinode'));

    expect(resultado, isA<Erro<String>>());
    expect(repositorio.lista!.map((f) => f.nome), ['Natura']);
  });

  test('sessão encerrada limpa o cache', () async {
    final sessao = StreamController<void>();
    final repositorio = repositorioFornecedoresDeTeste(
      ServicoFornecedoresFalso(resumos: [fornecedorDto('f1', 'Natura')]),
      sessaoEncerrada: sessao.stream,
    );
    await repositorio.carregar();

    sessao.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(repositorio.lista, isNull);
    await sessao.close();
  });
}
