import 'dart:async';
import 'dart:typed_data';

import 'package:sou_consultora/core/dto/consultora_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';
import 'falsos_fornecedores.dart';

ConsultoraDto dtoDeTeste({
  String nome = 'Ana Paula',
  String? foto,
  String? chave,
  String? tipo,
}) {
  return ConsultoraDto(
    id: 'id-ana',
    nome: nome,
    whatsapp: '11987654321',
    fotoUrl: foto,
    chavePix: chave,
    tipoChavePix: tipo,
    ultimoCodigoVenda: 0,
    createdAt: DateTime(2026, 11, 17),
  );
}

const falhaDeRede = FalhaRede(
  'Sem conexão com a internet. Verifique e tente novamente.',
);

/// Service falso: grava em memória e registra as chamadas.
class ServicoConsultoraFalso implements ServicoConsultora {
  ServicoConsultoraFalso({this.registro});

  ConsultoraDto? registro;
  bool falharRede = false;
  String? termosAceitos;
  bool falharAtualizarFoto = false;
  final List<String> chamadas = [];
  final List<String> fotosRemovidas = [];
  int _contador = 0;

  Resultado<T> _ou<T>(T valor) =>
      falharRede ? Erro(falhaDeRede) : Sucesso(valor);

  @override
  Future<Resultado<ConsultoraDto?>> buscarMinha() async {
    chamadas.add('buscar');
    return _ou(registro);
  }

  @override
  Future<Resultado<ConsultoraDto>> criar({
    required String nome,
    required String whatsapp,
    required String termosVersao,
  }) async {
    termosAceitos = termosVersao;
    chamadas.add('criar $nome $whatsapp');
    if (falharRede) return Erro(falhaDeRede);
    return Sucesso(registro = dtoDeTeste(nome: nome));
  }

  @override
  Future<Resultado<ConsultoraDto>> atualizar({
    required String nome,
    required String whatsapp,
    required String? chavePix,
    required String? tipoChavePix,
  }) async {
    chamadas.add('atualizar $nome $whatsapp $chavePix $tipoChavePix');
    if (falharRede) return Erro(falhaDeRede);
    return Sucesso(
      registro = dtoDeTeste(
        nome: nome,
        foto: registro?.fotoUrl,
        chave: chavePix,
        tipo: tipoChavePix,
      ),
    );
  }

  @override
  Future<Resultado<ConsultoraDto>> atualizarFoto(String? caminho) async {
    chamadas.add('atualizarFoto $caminho');
    if (falharRede || falharAtualizarFoto) return Erro(falhaDeRede);
    final atual = registro ?? dtoDeTeste();
    return Sucesso(
      registro = dtoDeTeste(
        nome: atual.nome,
        foto: caminho,
        chave: atual.chavePix,
        tipo: atual.tipoChavePix,
      ),
    );
  }

  @override
  Future<Resultado<String>> enviarFoto(Uint8List bytes) async {
    chamadas.add('enviarFoto');
    return _ou('id-ana/perfil-${++_contador}.jpg');
  }

  @override
  Future<Resultado<void>> removerFoto(String caminho) async {
    fotosRemovidas.add(caminho);
    return const Sucesso(null);
  }

  @override
  Future<Resultado<String>> urlDaFoto(String caminho) async =>
      Sucesso('https://assinada/$caminho');
}

/// Seleção de foto falsa: devolve bytes, null (desistiu) ou erro.
class FotoDispositivoFalsa implements ServicoFotoDispositivo {
  Resultado<Uint8List?> resposta = Sucesso(Uint8List.fromList([1, 2, 3]));
  OrigemFoto? ultimaOrigem;

  @override
  Future<Resultado<Uint8List?>> escolherRecortada(OrigemFoto origem) async {
    ultimaOrigem = origem;
    return resposta;
  }
}

/// Repositório real ligado aos falsos acima.
RepositorioConsultora repositorioDeTeste(
  ServicoConsultoraFalso servico, [
  FotoDispositivoFalsa? fotos,
  ServicoFornecedoresFalso? fornecedores,
]) {
  return RepositorioConsultora(
    servico: servico,
    fotos: fotos ?? FotoDispositivoFalsa(),
    fornecedores: fornecedores ?? ServicoFornecedoresFalso(),
  );
}
