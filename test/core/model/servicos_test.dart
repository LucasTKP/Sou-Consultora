import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/resumo_servico_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/duracao_servico.dart';
import 'package:sou_consultora/core/model/filtro_servicos.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/servico.dart';

import '../../auxiliares/falsos_servicos.dart';

void main() {
  test('validações e formato para gravar', () {
    expect(Servico.validarNome(' '), 'Informe o nome do serviço');
    expect(Servico.validarCategoria(null), 'Escolha a categoria');
    expect(Servico.validarPreco(0), 'Informe o preço cobrado');
    final dados = Servico(
      nome: ' Manicure ',
      categoriaId: 's1',
      precoCobradoCentavos: 6500,
      observacoes: ' ',
    ).paraGravar();
    expect(dados['nome'], 'Manicure');
    expect(dados['preco_cobrado'], 65.0);
    expect(dados['custo_materiais'], isNull);
    expect(dados['observacoes'], isNull);
    expect(dados.keys, isNot(contains('consultora_id')));
  });

  test('retorno estimado: 150 − 30 = 120 (80%); sem custo = 100%', () {
    final comCusto = servicoDto(
      '1',
      'Maquiagem',
      preco: 15000,
      custo: 3000,
    ).paraModel();
    expect(comCusto.retorno.valor, 12000);
    expect(comCusto.retorno.porcentagem, 80);
    expect(
      servicoDto('2', 'X', preco: 5000).paraModel().retorno.porcentagem,
      100,
    );
  });

  test('textos de duração', () {
    expect(DuracaoServico.curto(90), '1h 30min');
    expect(DuracaoServico.curto(60), '1h');
    expect(DuracaoServico.curto(45), '45min');
    expect(DuracaoServico.porExtenso(90), '1 hora e 30 minutos');
    expect(DuracaoServico.porExtenso(120), '2 horas');
    expect(DuracaoServico.porExtenso(30), '30 minutos');
  });

  test('filtro por categoria, busca sem acento, ordem e contagens', () {
    final lista = [
      servicoDto('1', 'Esmaltação em Gel'),
      servicoDto(
        '2',
        'Maquiagem Social',
        categoriaId: 's2',
        categoriaNome: 'Maquiagem',
      ),
      servicoDto('3', 'Manicure'),
    ].map((d) => d.paraModel()).toList();
    const unhas = Categoria(id: 's1', nome: 'Unhas');

    expect(
      FiltroServicos.aplicar(
        lista,
        categoria: unhas,
        busca: '',
        ordem: OrdemNome.aZ,
      ).map((s) => s.nome),
      ['Esmaltação em Gel', 'Manicure'],
    );
    expect(
      FiltroServicos.aplicar(
        lista,
        categoria: null,
        busca: 'esmaltacao',
        ordem: OrdemNome.aZ,
      ).single.nome,
      'Esmaltação em Gel',
    );
    expect(
      FiltroServicos.aplicar(
        lista,
        categoria: null,
        busca: '',
        ordem: OrdemNome.zA,
      ).first.nome,
      'Maquiagem Social',
    );
    final contagens = FiltroServicos.contagens(lista);
    expect(contagens.keys.map((c) => c.nome), ['Maquiagem', 'Unhas']);
    expect(contagens[unhas], 2);
  });

  test('DTO com numeric em texto e nulos', () {
    final modelo = ResumoServicoDto.fromJson({
      'id': 'x',
      'categoria_id': 's1',
      'nome': 'Manicure',
      'preco_cobrado': '65.00',
      'custo_materiais': null,
      'duracao_minutos': 90,
      'observacoes': null,
      'foto_url': null,
      'created_at': '2026-11-17T12:00:00Z',
      'categoria_nome': 'Unhas',
    }).paraModel();
    expect(modelo.precoCobrado, 6500);
    expect(modelo.custoMateriais, isNull);
    expect(modelo.duracaoMinutos, 90);
  });

  test(
    'repositório: salvar com foto nova apaga a antiga e recarrega',
    () async {
      final servico = ServicoServicosFalso(
        resumos: [
          servicoDto('1', 'Manicure', fotoUrl: 'u1/servicos/antiga.jpg'),
        ],
      );
      final repositorio = repositorioServicosDeTeste(servico);
      await repositorio.carregar();

      final resultado = await repositorio.salvar(
        repositorio.lista!.single.paraServico(),
        id: '1',
        foto: TrocarFoto(Uint8List.fromList([1])),
      );

      expect(resultado, isA<Sucesso<String>>());
      expect(servico.salvos.single.servico.caminhoFoto, 'u1/servicos/1.jpg');
      expect(servico.fotosRemovidas, ['u1/servicos/antiga.jpg']);
      expect(
        repositorio.lista!.single.urlFoto,
        'https://assinada/u1/servicos/1.jpg',
      );
    },
  );
}
