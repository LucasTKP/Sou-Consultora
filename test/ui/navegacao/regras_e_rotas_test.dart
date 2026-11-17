import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/regras_de_acesso.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';

import '../../auxiliares/falsos_consultora.dart';

class _AutenticacaoFalsa implements RepositorioAutenticacao {
  _AutenticacaoFalsa({required this.estaLogado});

  @override
  bool estaLogado;
  final controle = StreamController<bool>.broadcast();

  @override
  Stream<bool> get sessaoAtiva => controle.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _esperar() => Future<void>.delayed(Duration.zero);

void main() {
  group('destinoPermitido', () {
    String? destino(EstadoAcesso estado, String rota) => destinoPermitido(estado: estado, destino: rota);

    test('desconectado: só o login', () {
      expect(destino(EstadoAcesso.desconectado, RotasApp.vendas), RotasApp.login);
      expect(destino(EstadoAcesso.desconectado, RotasApp.cadastro), RotasApp.login);
      expect(destino(EstadoAcesso.desconectado, RotasApp.login), isNull);
    });

    test('verificando ou com erro: só o carregando', () {
      for (final estado in [EstadoAcesso.verificando, EstadoAcesso.erroVerificacao]) {
        expect(destino(estado, RotasApp.inicio), RotasApp.carregando);
        expect(destino(estado, RotasApp.cadastro), RotasApp.carregando);
        expect(destino(estado, RotasApp.carregando), isNull);
      }
    });

    test('sem cadastro: só o cadastro', () {
      expect(destino(EstadoAcesso.semCadastro, RotasApp.vendas), RotasApp.cadastro);
      expect(destino(EstadoAcesso.semCadastro, RotasApp.login), RotasApp.cadastro);
      expect(destino(EstadoAcesso.semCadastro, RotasApp.cadastro), isNull);
    });

    test('pronto: rotas de entrada levam ao Início; demais liberadas', () {
      for (final rota in [RotasApp.login, RotasApp.cadastro, RotasApp.carregando]) {
        expect(destino(EstadoAcesso.pronto, rota), RotasApp.inicio, reason: rota);
      }
      expect(destino(EstadoAcesso.pronto, RotasApp.aPagar), isNull);
      expect(destino(EstadoAcesso.pronto, RotasApp.editarPerfil), isNull);
    });
  });

  group('item ativo da barra', () {
    test('módulos da barra', () {
      expect(RotasApp.itemAtivo('/inicio'), ItemBarra.inicio);
      expect(RotasApp.itemAtivo('/clientes/123/compras'), ItemBarra.clientes);
      expect(RotasApp.itemAtivo('/financeiro'), ItemBarra.financeiro);
    });

    test('módulos fora da barra não ativam nenhum item', () {
      for (final rota in [RotasApp.servicos, RotasApp.fornecedores, RotasApp.aReceber, RotasApp.aPagar]) {
        expect(RotasApp.itemAtivo(rota), isNull, reason: rota);
      }
    });

    test('cada item da barra tem uma rota', () {
      expect(ItemBarra.values.map(RotasApp.rotaDoItem), [
        RotasApp.produtos,
        RotasApp.clientes,
        RotasApp.inicio,
        RotasApp.vendas,
        RotasApp.financeiro,
      ]);
    });
  });

  group('NotificadorAcesso', () {
    test('sem sessão começa desconectado', () {
      final acesso = NotificadorAcesso(
        autenticacao: _AutenticacaoFalsa(estaLogado: false),
        consultoras: repositorioDeTeste(ServicoConsultoraFalso()),
      );
      expect(acesso.estado, EstadoAcesso.desconectado);
    });

    test('com sessão e cadastro fica pronto', () async {
      final acesso = NotificadorAcesso(
        autenticacao: _AutenticacaoFalsa(estaLogado: true),
        consultoras: repositorioDeTeste(ServicoConsultoraFalso(registro: dtoDeTeste())),
      );
      expect(acesso.estado, EstadoAcesso.verificando);
      await _esperar();
      expect(acesso.estado, EstadoAcesso.pronto);
    });

    test('sem cadastro, cadastrar libera o app', () async {
      final repositorio = repositorioDeTeste(ServicoConsultoraFalso());
      final acesso = NotificadorAcesso(autenticacao: _AutenticacaoFalsa(estaLogado: true), consultoras: repositorio);
      await _esperar();
      expect(acesso.estado, EstadoAcesso.semCadastro);

      await repositorio.cadastrar(nome: 'Ana', whatsapp: '11987654321');
      await _esperar();
      expect(acesso.estado, EstadoAcesso.pronto);
    });

    test('falha → tentar novamente → pronto', () async {
      final servico = ServicoConsultoraFalso(registro: dtoDeTeste())..falharRede = true;
      final acesso = NotificadorAcesso(autenticacao: _AutenticacaoFalsa(estaLogado: true), consultoras: repositorioDeTeste(servico));
      await _esperar();
      expect(acesso.estado, EstadoAcesso.erroVerificacao);
      expect(acesso.mensagemErro, contains('internet'));

      servico.falharRede = false;
      await acesso.tentarNovamente();
      expect(acesso.estado, EstadoAcesso.pronto);
    });

    test('entrar e sair; renovação de token não refaz a verificação', () async {
      final autenticacao = _AutenticacaoFalsa(estaLogado: false);
      final servico = ServicoConsultoraFalso(registro: dtoDeTeste());
      final repositorio = repositorioDeTeste(servico);
      final acesso = NotificadorAcesso(autenticacao: autenticacao, consultoras: repositorio);

      autenticacao.controle.add(true);
      await _esperar();
      expect(acesso.estado, EstadoAcesso.pronto);

      autenticacao.controle.add(true);
      await _esperar();
      expect(servico.chamadas.where((c) => c == 'buscar'), hasLength(1));

      autenticacao.controle.add(false);
      await _esperar();
      expect(acesso.estado, EstadoAcesso.desconectado);
      expect(repositorio.atual, isNull);
    });
  });
}
