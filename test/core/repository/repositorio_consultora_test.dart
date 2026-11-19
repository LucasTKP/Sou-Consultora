import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/marca_padrao.dart';

import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';

void main() {
  test('buscar sem cadastro devolve null e publica null', () async {
    final repositorio = repositorioDeTeste(ServicoConsultoraFalso());
    final mudanca = repositorio.mudancas.first;

    final resultado = await repositorio.buscarMinha();

    expect((resultado as Sucesso).valor, isNull);
    expect(await mudanca, isNull);
  });

  test('buscar com foto gera a URL assinada', () async {
    final repositorio = repositorioDeTeste(
      ServicoConsultoraFalso(registro: dtoDeTeste(foto: 'id-ana/perfil-1.jpg')),
    );
    final resultado = await repositorio.buscarMinha();
    expect(
      (resultado as Sucesso<Consultora?>).valor?.urlFoto,
      'https://assinada/id-ana/perfil-1.jpg',
    );
  });

  test('cadastrar guarda o WhatsApp só com dígitos e publica', () async {
    final servico = ServicoConsultoraFalso();
    final repositorio = repositorioDeTeste(servico);
    final mudanca = repositorio.mudancas.first;

    await repositorio.cadastrar(
      nome: '  Ana Paula ',
      whatsapp: '(11) 98765-4321',
    );

    expect(servico.chamadas.last, 'criar Ana Paula 11987654321');
    expect((await mudanca)?.nome, 'Ana Paula');
    expect(repositorio.atual?.nome, 'Ana Paula');
  });

  group('cadastrar com marcas', () {
    const nome = 'Ana';
    const whatsapp = '11987654321';

    test('cria um fornecedor por marca marcada, antes de publicar', () async {
      final fornecedores = ServicoFornecedoresFalso();
      final repositorio = repositorioDeTeste(
        ServicoConsultoraFalso(),
        null,
        fornecedores,
      );
      var fornecedoresAoPublicar = -1;
      final assinatura = repositorio.mudancas.listen(
        (_) => fornecedoresAoPublicar = fornecedores.salvos.length,
      );

      await repositorio.cadastrar(
        nome: nome,
        whatsapp: whatsapp,
        marcas: [MarcaPadrao.natura, MarcaPadrao.boticario],
      );
      await Future<void>.delayed(Duration.zero);

      expect(fornecedores.salvos.map((s) => s.fornecedor.nome), [
        'Natura',
        'O Boticário',
      ]);
      expect(fornecedores.salvos.first.fornecedor.ramo, isNotNull);
      expect(fornecedoresAoPublicar, 2);
      await assinatura.cancel();
    });

    test('sem marcas não cria fornecedor nenhum', () async {
      final fornecedores = ServicoFornecedoresFalso();
      await repositorioDeTeste(
        ServicoConsultoraFalso(),
        null,
        fornecedores,
      ).cadastrar(nome: nome, whatsapp: whatsapp);
      expect(fornecedores.chamadas, isEmpty);
    });

    test('falha ao criar marca não impede o cadastro', () async {
      final fornecedores = ServicoFornecedoresFalso()..falharRede = true;
      final repositorio = repositorioDeTeste(
        ServicoConsultoraFalso(),
        null,
        fornecedores,
      );
      final resultado = await repositorio.cadastrar(
        nome: nome,
        whatsapp: whatsapp,
        marcas: [MarcaPadrao.avon],
      );
      expect(resultado, isA<Sucesso<Consultora>>());
      expect(repositorio.atual?.nome, nome);
    });

    test('se o cadastro falha, nenhuma marca é criada', () async {
      final fornecedores = ServicoFornecedoresFalso();
      final repositorio = repositorioDeTeste(
        ServicoConsultoraFalso()..falharRede = true,
        null,
        fornecedores,
      );
      final resultado = await repositorio.cadastrar(
        nome: nome,
        whatsapp: whatsapp,
        marcas: [MarcaPadrao.eudora],
      );
      expect(resultado, isA<Erro<Consultora>>());
      expect(fornecedores.chamadas, isEmpty);
    });
  });

  test('atualizar grava a chave Pix normalizada', () async {
    final servico = ServicoConsultoraFalso(registro: dtoDeTeste());
    final repositorio = repositorioDeTeste(servico);

    await repositorio.atualizar(
      nome: 'Ana',
      whatsapp: '11987654321',
      chavePix: ChavePix.digitada(TipoChavePix.cpf, '529.982.247-25'),
    );

    expect(servico.chamadas.last, 'atualizar Ana 11987654321 52998224725 cpf');
    expect(repositorio.atual?.chavePix?.tipo, TipoChavePix.cpf);
  });

  test('trocar foto envia, aponta o cadastro e apaga a anterior', () async {
    final servico = ServicoConsultoraFalso(
      registro: dtoDeTeste(foto: 'id-ana/perfil-antiga.jpg'),
    );
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    final resultado = await repositorio.trocarFoto(Uint8List(3));

    expect(
      (resultado as Sucesso<Consultora>).valor.caminhoFoto,
      'id-ana/perfil-1.jpg',
    );
    expect(servico.fotosRemovidas, ['id-ana/perfil-antiga.jpg']);
  });

  test('se gravar o cadastro falhar, apaga a foto recém-enviada e mantém a anterior', () async {
    final servico = ServicoConsultoraFalso(
      registro: dtoDeTeste(foto: 'id-ana/perfil-antiga.jpg'),
    )..falharAtualizarFoto = true;
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    final resultado = await repositorio.trocarFoto(Uint8List(3));

    expect(resultado, isA<Erro<Consultora>>());
    expect(servico.fotosRemovidas, ['id-ana/perfil-1.jpg']);
    expect(repositorio.atual?.caminhoFoto, 'id-ana/perfil-antiga.jpg');
  });

  test('remover foto limpa o cadastro e apaga o arquivo', () async {
    final servico = ServicoConsultoraFalso(
      registro: dtoDeTeste(foto: 'id-ana/perfil-1.jpg'),
    );
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    await repositorio.removerFoto();

    expect(repositorio.atual?.caminhoFoto, isNull);
    expect(servico.fotosRemovidas, ['id-ana/perfil-1.jpg']);
  });

  test('limpar esquece a consultora', () async {
    final repositorio = repositorioDeTeste(
      ServicoConsultoraFalso(registro: dtoDeTeste()),
    );
    await repositorio.buscarMinha();
    repositorio.limpar();
    expect(repositorio.atual, isNull);
  });
}
