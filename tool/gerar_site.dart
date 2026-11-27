/// Gera o site público (`site/`) a partir do mesmo texto que o app mostra.
///
/// Uso, na raiz do projeto: `dart run tool/gerar_site.dart`
library;

import 'dart:convert';
import 'dart:io';

import 'package:sou_consultora/core/model/termos_de_uso.dart';
import 'package:sou_consultora/ui/modules/termos/termos_conteudo.dart';

const _email = TermosDeUso.emailContato;

void main() {
  for (final MapEntry(key: nome, value: html) in paginasDoSite().entries) {
    File('site/$nome').writeAsStringSync(html);
  }
  File('assets/imagens/logo.png').copySync('site/logo.png');
}

/// Nome do arquivo → HTML. O `estilo.css` é escrito à mão em `site/`.
Map<String, String> paginasDoSite() => {
  'index.html': _pagina('Início', _inicio),
  'termos.html': _pagina(
    'Termos de Uso',
    _documento('Termos de Uso', TermosConteudo.termos),
  ),
  'privacidade.html': _pagina(
    'Política de Privacidade',
    _documento('Política de Privacidade', TermosConteudo.privacidade),
  ),
  'excluir-conta.html': _pagina('Excluir conta', _excluirConta),
};

String _texto(String bruto) =>
    const HtmlEscape(HtmlEscapeMode.element)
        .convert(bruto)
        .replaceAll(_email, '<a href="mailto:$_email">$_email</a>');

String _documento(String titulo, List<SecaoTermos> secoes) {
  final [ano, mes, dia] = TermosDeUso.versao.split('-');
  final corpo = [
    for (final secao in secoes) ...[
      '<h2>${_texto(secao.titulo)}</h2>',
      for (final paragrafo in secao.paragrafos) '<p>${_texto(paragrafo)}</p>',
    ],
  ].join('\n');
  return '''
<article class="cartao">
<h1>$titulo</h1>
<p class="versao">Versão de $dia/$mes/$ano</p>
$corpo
</article>''';
}

const _inicio = '''
<section class="destaque">
<img src="logo.png" alt="Sou Consultora" width="220" height="220">
<h1>Seu negócio de beleza organizado</h1>
<p>Clientes, produtos, vendas e recebimentos da consultora em um só aplicativo.</p>
</section>
<section class="grade">
<div class="cartao"><h2>Clientes</h2><p>Dados, histórico de compras e aniversários.</p></div>
<div class="cartao"><h2>Produtos e serviços</h2><p>Catálogo, preços e controle de estoque.</p></div>
<div class="cartao"><h2>Vendas</h2><p>Descontos, parcelas e comprovantes para enviar à cliente.</p></div>
<div class="cartao"><h2>A receber e a pagar</h2><p>Vencimentos, atrasos e boletos dos fornecedores.</p></div>
</section>''';

const _excluirConta =
    '''
<article class="cartao">
<h1>Excluir conta</h1>
<p>Você pode pedir a exclusão da sua conta do aplicativo Sou Consultora e dos dados dela a qualquer momento.</p>
<h2>Pelo aplicativo</h2>
<p>Abra <strong>Meu Perfil</strong>, toque em <strong>Mais opções</strong> e depois em <strong>Apagar Conta</strong>. A conversa com o suporte abre no WhatsApp com o pedido pronto.</p>
<h2>Por e-mail</h2>
<p>Se não tiver mais o aplicativo, escreva para <a href="mailto:$_email?subject=Excluir%20minha%20conta%20-%20Sou%20Consultora">$_email</a> a partir do e-mail que você usa para entrar.</p>
<h2>O que é apagado</h2>
<p>A conta e tudo o que está nela: perfil, clientes, produtos, serviços, fornecedores, vendas, recebimentos, boletos, fotos e comprovantes. Não há como desfazer.</p>
<p>Podemos manter apenas o que a lei obrigar. Cópias de segurança podem existir por prazo limitado.</p>
</article>''';

String _pagina(String titulo, String conteudo) =>
    '''
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$titulo · Sou Consultora</title>
<link rel="icon" href="logo.png">
<link rel="stylesheet" href="estilo.css">
</head>
<body>
<header>
<a class="marca" href="index.html">Sou Consultora</a>
<nav>
<a href="termos.html">Termos</a>
<a href="privacidade.html">Privacidade</a>
<a href="excluir-conta.html">Excluir conta</a>
</nav>
</header>
<main>
$conteudo
</main>
<footer>Contato: <a href="mailto:$_email">$_email</a></footer>
</body>
</html>
''';
