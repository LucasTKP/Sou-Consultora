import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/consultora_dto.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/ui/formatadores/formatador_chave_pix.dart';

void main() {
  group('chave Pix', () {
    test('par tipo e chave', () {
      expect(ChavePix.erroDoTipo(null, ''), isNull);
      expect(ChavePix.erroDaChave(null, ''), isNull);
      expect(ChavePix.erroDoTipo(null, 'ana@email.com'), 'Escolha o tipo da chave');
      expect(ChavePix.erroDaChave(TipoChavePix.email, '  '), 'Informe a chave Pix');
    });

    test('telefone', () {
      expect(ChavePix.erroDaChave(TipoChavePix.telefone, '(11) 98765-4321'), isNull);
      expect(ChavePix.erroDaChave(TipoChavePix.telefone, '+55 11 98765-4321'), isNull);
      expect(ChavePix.erroDaChave(TipoChavePix.telefone, '(11) 9876'), 'Telefone inválido');
      expect(ChavePix.normalizar(TipoChavePix.telefone, '(11) 98765-4321'), '+5511987654321');
      expect(ChavePix.normalizar(TipoChavePix.telefone, '+55 (11) 98765-4321'), '+5511987654321');
    });

    test('CPF', () {
      expect(ChavePix.cpfValido('529.982.247-25'), isTrue);
      expect(ChavePix.cpfValido('52998224725'), isTrue);
      expect(ChavePix.cpfValido('529.982.247-24'), isFalse);
      expect(ChavePix.cpfValido('111.111.111-11'), isFalse);
      expect(ChavePix.cpfValido('1234'), isFalse);
      expect(ChavePix.erroDaChave(TipoChavePix.cpf, '111.111.111-11'), 'CPF inválido');
      expect(ChavePix.normalizar(TipoChavePix.cpf, '529.982.247-25'), '52998224725');
    });

    test('e-mail e aleatória', () {
      expect(ChavePix.erroDaChave(TipoChavePix.email, 'ana@email'), 'E-mail inválido');
      expect(ChavePix.normalizar(TipoChavePix.email, ' Ana@Email.COM '), 'ana@email.com');
      expect(ChavePix.erroDaChave(TipoChavePix.aleatoria, '123e4567-e89b-12d3-a456-426614174000'), isNull);
      expect(ChavePix.erroDaChave(TipoChavePix.aleatoria, 'abc'), 'Chave aleatória inválida');
    });

    test('formatação para exibir', () {
      expect(FormatadorChavePix.formatar(const ChavePix(tipo: TipoChavePix.telefone, valor: '+5511987654321')), '(11) 98765-4321');
      expect(FormatadorChavePix.formatar(const ChavePix(tipo: TipoChavePix.cpf, valor: '52998224725')), '529.982.247-25');
    });

    test('tipo do banco', () {
      expect(TipoChavePix.doBanco('aleatoria'), TipoChavePix.aleatoria);
      expect(TipoChavePix.doBanco(null), isNull);
    });
  });

  group('consultora', () {
    test('validações', () {
      expect(Consultora.validarNome('  '), 'Informe o nome');
      expect(Consultora.validarNome('Ana'), isNull);
      expect(Consultora.validarWhatsapp('(11) 9876'), 'Informe o WhatsApp com DDD');
      expect(Consultora.validarWhatsapp('(11) 98765-4321'), isNull);
    });

    test('DTO ida e volta e conversão para model', () {
      final json = {
        'id': 'abc',
        'nome': 'Ana Paula',
        'whatsapp': '11987654321',
        'foto_url': 'abc/perfil-1.jpg',
        'chave_pix': '+5511987654321',
        'tipo_chave_pix': 'telefone',
        'ultimo_codigo_venda': 0,
        'created_at': '2026-11-17T10:00:00.000Z',
      };
      final dto = ConsultoraDto.fromJson(json);
      expect(ConsultoraDto.fromJson(dto.toJson()).toJson(), dto.toJson());

      final consultora = dto.paraModel(urlFoto: 'https://assinada');
      expect(consultora.chavePix?.tipo, TipoChavePix.telefone);
      expect(consultora.caminhoFoto, 'abc/perfil-1.jpg');
      expect(ResumoConsultora.daConsultora(consultora).fotoUrl, 'https://assinada');
      expect(ResumoConsultora.daConsultora(consultora).iniciais, 'AP');
    });

    test('sem chave Pix', () {
      final dto = ConsultoraDto.fromJson({
        'id': 'abc',
        'nome': 'Ana',
        'whatsapp': '11987654321',
        'ultimo_codigo_venda': 0,
        'created_at': '2026-11-17T10:00:00.000Z',
      });
      expect(dto.paraModel().temChavePix, isFalse);
    });
  });
}
