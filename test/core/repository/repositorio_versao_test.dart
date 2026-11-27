import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/configuracao_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/versao_app.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';
import 'package:sou_consultora/core/service/servico_abrir_link.dart';
import 'package:sou_consultora/core/service/servico_configuracoes.dart';
import 'package:sou_consultora/core/service/servico_info_app.dart';

class _ConfiguracoesFalso implements ServicoConfiguracoes {
  _ConfiguracoesFalso(this.resultado);
  final Resultado<List<ConfiguracaoDto>> resultado;

  @override
  Future<Resultado<List<ConfiguracaoDto>>> listar() async => resultado;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InfoFalso implements ServicoInfoApp {
  _InfoFalso(this.versao, this.plataforma);
  final String versao;
  final PlataformaApp? plataforma;

  @override
  Future<Resultado<InfoApp>> ler() async => Sucesso(
    InfoApp(versao: VersaoApp.tentarLer(versao)!, plataforma: plataforma),
  );
}

class _LinkFalso implements ServicoAbrirLink {
  final abertos = <String>[];

  @override
  Future<Resultado<void>> abrir(String url) async {
    abertos.add(url);
    return const Sucesso(null);
  }
}

const _android = 'https://play.google.com/store/apps/details?id=x';
const _ios = 'https://apps.apple.com/app/id1';

List<ConfiguracaoDto> _minimas({
  String android = '2.0.0',
  String ios = '2.0.0',
}) => [
  ConfiguracaoDto(chave: 'versao_minima_android', valor: android),
  ConfiguracaoDto(chave: 'versao_minima_ios', valor: ios),
];

RepositorioVersao _repo({
  required String versao,
  required PlataformaApp? plataforma,
  Resultado<List<ConfiguracaoDto>>? configuracoes,
  _LinkFalso? link,
  String urlAndroid = _android,
  String urlIos = _ios,
}) {
  return RepositorioVersao(
    configuracoes: _ConfiguracoesFalso(configuracoes ?? Sucesso(_minimas())),
    infoApp: _InfoFalso(versao, plataforma),
    abrirLink: link ?? _LinkFalso(),
    urlLojaAndroid: urlAndroid,
    urlLojaIos: urlIos,
  );
}

bool? _obrigatoria(Resultado<bool> r) => switch (r) {
  Sucesso(:final valor) => valor,
  Erro() => null,
};

void main() {
  group('atualizacaoObrigatoria', () {
    test('abaixo do mínimo exige atualização', () async {
      final r = await _repo(
        versao: '1.9.9',
        plataforma: PlataformaApp.android,
      ).atualizacaoObrigatoria();
      expect(_obrigatoria(r), isTrue);
    });

    test('igual ou acima do mínimo libera', () async {
      for (final v in ['2.0.0', '2.0.1', '3.0.0']) {
        final r = await _repo(
          versao: v,
          plataforma: PlataformaApp.ios,
        ).atualizacaoObrigatoria();
        expect(_obrigatoria(r), isFalse, reason: v);
      }
    });

    test('usa o mínimo da plataforma certa', () async {
      final configuracoes = Sucesso(_minimas(android: '5.0.0', ios: '1.0.0'));
      final android = await _repo(
        versao: '2.0.0',
        plataforma: PlataformaApp.android,
        configuracoes: configuracoes,
      ).atualizacaoObrigatoria();
      final ios = await _repo(
        versao: '2.0.0',
        plataforma: PlataformaApp.ios,
        configuracoes: configuracoes,
      ).atualizacaoObrigatoria();
      expect(_obrigatoria(android), isTrue);
      expect(_obrigatoria(ios), isFalse);
    });

    test('valor ilegível no banco não bloqueia', () async {
      final r = await _repo(
        versao: '1.0.0',
        plataforma: PlataformaApp.android,
        configuracoes: Sucesso(_minimas(android: 'lixo')),
      ).atualizacaoObrigatoria();
      expect(_obrigatoria(r), isFalse);
    });

    test('plataforma desconhecida libera sem consultar', () async {
      final r = await _repo(
        versao: '0.0.1',
        plataforma: null,
      ).atualizacaoObrigatoria();
      expect(_obrigatoria(r), isFalse);
    });

    test(
      'falha ao consultar devolve erro (quem chama decide liberar)',
      () async {
        final r = await _repo(
          versao: '1.0.0',
          plataforma: PlataformaApp.android,
          configuracoes: Erro(const FalhaRede('sem rede')),
        ).atualizacaoObrigatoria();
        expect(r, isA<Erro<bool>>());
      },
    );
  });

  group('abrirLoja', () {
    test('abre o link da plataforma', () async {
      final link = _LinkFalso();
      final android = _repo(
        versao: '1.0.0',
        plataforma: PlataformaApp.android,
        link: link,
      );
      await android.atualizacaoObrigatoria();
      await android.abrirLoja();
      final ios = _repo(
        versao: '1.0.0',
        plataforma: PlataformaApp.ios,
        link: link,
      );
      await ios.atualizacaoObrigatoria();
      await ios.abrirLoja();
      expect(link.abertos, [_android, _ios]);
    });

    test('link vazio ou inválido devolve falha sem abrir', () async {
      final link = _LinkFalso();
      final repo = _repo(
        versao: '1.0.0',
        plataforma: PlataformaApp.android,
        link: link,
        urlAndroid: '',
      );
      await repo.atualizacaoObrigatoria();
      expect(await repo.abrirLoja(), isA<Erro<void>>());
      expect(link.abertos, isEmpty);
    });
  });
}
