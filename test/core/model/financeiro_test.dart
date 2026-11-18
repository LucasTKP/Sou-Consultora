import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/resumo_financeiro.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_vendas.dart';

void main() {
  final vendas = [
    vendaDto('v1', total: 240000, data: DateTime(2026, 11, 3)),
    vendaDto('v2', total: 300000, data: DateTime(2026, 11, 28, 23, 50)),
    vendaDto('v3', total: 120000, data: DateTime(2026, 10, 15)),
    vendaDto('v4', total: 50000, data: DateTime(2026, 1, 2)),
    // Fora da janela de 12 meses que termina em nov/2026.
    vendaDto('v5', total: 999900, data: DateTime(2025, 11, 30)),
  ].map((v) => v.paraModel()).toList();

  final boletos = [
    boletoDto(
      'pago',
      valor: 42000,
      vencimento: DateTime(2026, 11, 1),
      pagoEm: DateTime(2026, 11, 1),
    ),
    boletoDto('aberto', valor: 68000, vencimento: DateTime(2026, 11, 25)),
    boletoDto('dezembro', valor: 31000, vencimento: DateTime(2026, 12, 5)),
  ].map((b) => b.paraModel()).toList();

  group('MesAno', () {
    test('somar vira o ano nos dois sentidos', () {
      expect(const MesAno(2027, 2).somar(-11), const MesAno(2026, 3));
      expect(const MesAno(2026, 12).somar(1), const MesAno(2027, 1));
      expect(const MesAno(2026, 1).somar(-1), const MesAno(2025, 12));
      expect(const MesAno(2026, 5).somar(0), const MesAno(2026, 5));
    });
  });

  group('ResumoFinanceiro', () {
    test('12 meses até o período, do mais antigo ao mais novo', () {
      final resumo = ResumoFinanceiro.calcular(
        vendas: vendas,
        boletos: boletos,
        periodo: const MesAno(2026, 11),
      );
      expect(resumo.meses, hasLength(12));
      expect(resumo.meses.first.mes, const MesAno(2025, 12));
      expect(resumo.meses.last.mes, const MesAno(2026, 11));
      expect(resumo.meses.last.valor, 540000);
      expect(resumo.meses[10].valor, 120000); // outubro
      expect(resumo.meses[6].valor, 0); // junho, sem vendas
      // A venda de nov/2025 está fora da janela.
      expect(resumo.totalAcumulado, 540000 + 120000 + 50000);
      expect(resumo.maiorMes, 540000);
    });

    test('categorias: vendas do mês e boletos que vencem no mês', () {
      final resumo = ResumoFinanceiro.calcular(
        vendas: vendas,
        boletos: boletos,
        periodo: const MesAno(2026, 11),
      );
      expect(resumo.faturamentoDoMes, 540000);
      // Pago e em aberto contam; o de dezembro não.
      expect(resumo.despesasDoMes, 42000 + 68000);
    });

    test('virada de ano e mês sem nada', () {
      final resumo = ResumoFinanceiro.calcular(
        vendas: vendas,
        boletos: boletos,
        periodo: const MesAno(2027, 2),
      );
      expect(resumo.meses.first.mes, const MesAno(2026, 3));
      expect(resumo.meses.last.mes, const MesAno(2027, 2));
      expect(resumo.faturamentoDoMes, 0);
      expect(resumo.despesasDoMes, 0);
      expect(resumo.totalAcumulado, 540000 + 120000);
    });

    test('sem vendas nem boletos: tudo zero', () {
      final resumo = ResumoFinanceiro.calcular(
        vendas: const [],
        boletos: const [],
        periodo: const MesAno(2026, 11),
      );
      expect(resumo.totalAcumulado, 0);
      expect(resumo.maiorMes, 0);
      expect(resumo.meses.every((m) => m.valor == 0), isTrue);
    });

    test('períodos: os 12 até hoje e os meses com dados, do mais recente', () {
      final periodos = ResumoFinanceiro.periodos(
        vendas: vendas,
        boletos: boletos,
        hoje: DateTime(2026, 11, 18),
      );
      expect(periodos.first, const MesAno(2026, 12)); // boleto de dezembro
      expect(periodos[1], const MesAno(2026, 11));
      expect(periodos, contains(const MesAno(2025, 12)));
      expect(periodos.last, const MesAno(2025, 11)); // venda antiga
      expect(periodos.toSet(), hasLength(periodos.length));
    });
  });

  group('Formatos do Financeiro', () {
    test('abreviado para o rótulo da barra', () {
      expect(FormatadorMoeda.abreviado(0), '0');
      expect(FormatadorMoeda.abreviado(98000), '980');
      expect(FormatadorMoeda.abreviado(540000), '5.4k');
      expect(FormatadorMoeda.abreviado(500000), '5k');
      expect(FormatadorMoeda.abreviado(5482000), '54.8k');
      expect(FormatadorMoeda.abreviado(125000000), '1.3M');
    });

    test('total sem centavos', () {
      expect(FormatadorMoeda.formatarSemCentavos(5482000), 'R\$ 54.820');
      expect(FormatadorMoeda.formatarSemCentavos(5482050), 'R\$ 54.821');
      expect(FormatadorMoeda.formatarSemCentavos(0), 'R\$ 0');
    });
  });
}
