import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';
import 'package:sou_consultora/core/service/servico_dicas.dart';

import '../../auxiliares/falsos_dicas.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ServicoDicasLocal', () {
    test('lembra que a dica foi vista', () async {
      final servico = ServicoDicasLocal(idUsuario: () => 'ana');

      expect(await servico.jaViu(DicaApp.importarNoFormulario), isFalse);
      await servico.marcarComoVista(DicaApp.importarNoFormulario);
      expect(await servico.jaViu(DicaApp.importarNoFormulario), isTrue);
      // Outra dica continua pendente.
      expect(await servico.jaViu(DicaApp.importarNaLista), isFalse);
    });

    test('cada consultora tem as suas dicas, no mesmo aparelho', () async {
      var usuario = 'ana';
      final servico = ServicoDicasLocal(idUsuario: () => usuario);

      await servico.marcarComoVista(DicaApp.importarNoFormulario);
      usuario = 'bia';
      expect(await servico.jaViu(DicaApp.importarNoFormulario), isFalse);
      usuario = 'ana';
      expect(await servico.jaViu(DicaApp.importarNoFormulario), isTrue);
    });

    test('guarda sob uma chave estável', () async {
      await ServicoDicasLocal(idUsuario: () => 'ana')
          .marcarComoVista(DicaApp.continuarAposImportar);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dica_ana_continuar_apos_importar'), isTrue);
    });
  });

  group('RepositorioDicas', () {
    test('mostra uma vez só', () async {
      final repositorio = repositorioDicasDeTeste();

      expect(await repositorio.deveMostrar(DicaApp.importarNaLista), isTrue);
      await repositorio.marcarComoVista(DicaApp.importarNaLista);
      expect(await repositorio.deveMostrar(DicaApp.importarNaLista), isFalse);
    });

    test('falha ao ler: não mostra (não repete a cada abertura)', () async {
      final servico = ServicoDicasFalso()..falhar = true;
      expect(
        await repositorioDicasDeTeste(servico)
            .deveMostrar(DicaApp.importarNaLista),
        isFalse,
      );
    });

    test('falha ao gravar não derruba o app', () async {
      final servico = ServicoDicasFalso()..falhar = true;
      await repositorioDicasDeTeste(servico)
          .marcarComoVista(DicaApp.importarNaLista);
    });

    test('marcar todas como vistas desliga todas as dicas', () async {
      final servico = ServicoDicasFalso();
      final repositorio = repositorioDicasDeTeste(servico);

      await repositorio.marcarTodasComoVistas();

      expect(servico.vistas, DicaApp.values.toSet());
    });
  });
}
