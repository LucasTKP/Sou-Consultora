import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gerar_site.dart';

void main() {
  test('o site publicado tem o mesmo texto do app', () {
    for (final MapEntry(key: nome, value: html) in paginasDoSite().entries) {
      expect(
        File('site/$nome').readAsStringSync(),
        html,
        reason: 'site/$nome desatualizado: rode dart run tool/gerar_site.dart',
      );
    }
  });
}
