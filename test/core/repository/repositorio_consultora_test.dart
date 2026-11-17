import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';

import '../../auxiliares/falsos_consultora.dart';

void main() {
  test('buscar sem cadastro devolve null e publica null', () async {
    final repositorio = repositorioDeTeste(ServicoConsultoraFalso());
    final mudanca = repositorio.mudancas.first;

    final resultado = await repositorio.buscarMinha();

    expect((resultado as Sucesso).valor, isNull);
    expect(await mudanca, isNull);
  });

  test('buscar com foto gera a URL assinada', () async {
    final repositorio = repositorioDeTeste(ServicoConsultoraFalso(registro: dtoDeTeste(foto: 'id-ana/perfil-1.jpg')));
    final resultado = await repositorio.buscarMinha();
    expect((resultado as Sucesso<Consultora?>).valor?.urlFoto, 'https://assinada/id-ana/perfil-1.jpg');
  });

  test('cadastrar guarda o WhatsApp só com dígitos e publica', () async {
    final servico = ServicoConsultoraFalso();
    final repositorio = repositorioDeTeste(servico);
    final mudanca = repositorio.mudancas.first;

    await repositorio.cadastrar(nome: '  Ana Paula ', whatsapp: '(11) 98765-4321');

    expect(servico.chamadas.last, 'criar Ana Paula 11987654321');
    expect((await mudanca)?.nome, 'Ana Paula');
    expect(repositorio.atual?.nome, 'Ana Paula');
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
    final servico = ServicoConsultoraFalso(registro: dtoDeTeste(foto: 'id-ana/perfil-antiga.jpg'));
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    final resultado = await repositorio.trocarFoto(Uint8List(3));

    expect((resultado as Sucesso<Consultora>).valor.caminhoFoto, 'id-ana/perfil-1.jpg');
    expect(servico.fotosRemovidas, ['id-ana/perfil-antiga.jpg']);
  });

  test('se gravar o cadastro falhar, apaga a foto recém-enviada e mantém a anterior', () async {
    final servico = ServicoConsultoraFalso(registro: dtoDeTeste(foto: 'id-ana/perfil-antiga.jpg'))..falharAtualizarFoto = true;
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    final resultado = await repositorio.trocarFoto(Uint8List(3));

    expect(resultado, isA<Erro<Consultora>>());
    expect(servico.fotosRemovidas, ['id-ana/perfil-1.jpg']);
    expect(repositorio.atual?.caminhoFoto, 'id-ana/perfil-antiga.jpg');
  });

  test('remover foto limpa o cadastro e apaga o arquivo', () async {
    final servico = ServicoConsultoraFalso(registro: dtoDeTeste(foto: 'id-ana/perfil-1.jpg'));
    final repositorio = repositorioDeTeste(servico);
    await repositorio.buscarMinha();

    await repositorio.removerFoto();

    expect(repositorio.atual?.caminhoFoto, isNull);
    expect(servico.fotosRemovidas, ['id-ana/perfil-1.jpg']);
  });

  test('limpar esquece a consultora', () async {
    final repositorio = repositorioDeTeste(ServicoConsultoraFalso(registro: dtoDeTeste()));
    await repositorio.buscarMinha();
    repositorio.limpar();
    expect(repositorio.atual, isNull);
  });
}
