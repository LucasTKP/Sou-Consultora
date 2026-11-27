import 'package:sou_consultora/core/model/termos_de_uso.dart';

/// Um trecho dos termos: título e parágrafos.
typedef SecaoTermos = ({String titulo, List<String> paragrafos});

/// Texto exibido na tela de termos e no site (`site/`). Ao alterar, atualize
/// `TermosDeUso.versao` e rode `dart run tool/gerar_site.dart`.
///
/// Só Dart puro aqui: o gerador do site importa este arquivo sem o Flutter.
abstract final class TermosConteudo {
  static const termos = <SecaoTermos>[
    (
      titulo: '1. O que é o aplicativo',
      paragrafos: [
        'O Sou Consultora é uma ferramenta para consultoras de beleza '
            'organizarem clientes, produtos, serviços, estoque, vendas, '
            'recebimentos e contas a pagar.',
        'O aplicativo é mantido por ${TermosDeUso.responsavel}. Contato: '
            '${TermosDeUso.emailContato}.',
        'O aplicativo não é banco nem meio de pagamento: ele não movimenta '
            'dinheiro, não faz cobranças em seu nome e não emite nota fiscal.',
        'O aplicativo é independente. Ele não é da Natura, Avon, O Boticário, '
            'Eudora, Tupperware, Mary Kay nem de outra marca citada, e não tem '
            'vínculo com elas. Os nomes e marcas pertencem aos seus donos.',
      ],
    ),
    (
      titulo: '2. Sua conta',
      paragrafos: [
        'Para usar o aplicativo você precisa ter 18 anos ou mais e entrar com '
            'sua conta Google ou Apple.',
        'Você é responsável por informar dados verdadeiros e por proteger o '
            'acesso ao seu aparelho e à sua conta.',
      ],
    ),
    (
      titulo: '3. Seus compromissos',
      paragrafos: [
        'Usar o aplicativo somente para atividades lícitas.',
        'Cadastrar apenas dados de clientes que você tenha o direito de usar, '
            'informar a eles como esses dados são usados e atender aos pedidos '
            'deles, como corrigir ou apagar.',
        'Não anotar informações sensíveis sem necessidade, como dados de '
            'saúde, religião ou opinião política.',
        'Não tentar acessar dados de outras pessoas, copiar o aplicativo ou '
            'prejudicar o seu funcionamento.',
      ],
    ),
    (
      titulo: '4. Seus dados e suas decisões',
      paragrafos: [
        'As informações que você cadastra são suas.',
        'Valores, saldos, vencimentos, lembretes e relatórios são calculados a '
            'partir do que você informou. Confira antes de cobrar ou pagar e '
            'mantenha seus próprios controles fiscais e contábeis.',
        'Mensagens e comprovantes enviados pelo WhatsApp ou por outro '
            'aplicativo são enviados por você.',
      ],
    ),
    (
      titulo: '5. Disponibilidade e responsabilidade',
      paragrafos: [
        'O aplicativo depende de internet e de serviços de terceiros e pode '
            'ficar indisponível, ter falhas ou passar por manutenção.',
        'Trabalhamos para manter o serviço correto e seguro, mas não '
            'garantimos que ele funcione sem interrupções. Isso não limita os '
            'direitos que a lei garante a você.',
      ],
    ),
    (
      titulo: '6. Encerramento',
      paragrafos: [
        'Você pode pedir a exclusão da conta em Meu Perfil, Mais opções, '
            'Apagar Conta.',
        'Podemos suspender contas que descumprirem estes termos ou usarem o '
            'aplicativo de forma ilegal.',
      ],
    ),
    (
      titulo: '7. Mudanças e lei aplicável',
      paragrafos: [
        'Estes termos podem mudar. Mudanças importantes serão avisadas no '
            'aplicativo.',
        'Vale a lei brasileira. Eventuais disputas podem ser resolvidas no '
            'foro do seu domicílio.',
      ],
    ),
  ];

  static const privacidade = <SecaoTermos>[
    (
      titulo: '1. Dados que tratamos',
      paragrafos: [
        'Da sua conta: nome e e-mail informados pelo Google ou pela Apple, '
            'WhatsApp, foto de perfil, chave Pix e marcas que você vende.',
        'Do seu negócio: produtos, serviços, estoque, fornecedores, vendas, '
            'recebimentos, boletos, comprovantes e fotos que você enviar.',
        'Das suas clientes: nome, WhatsApp, data de nascimento, endereço, '
            'observações e histórico de compras.',
        'Técnicos: registros de acesso, como endereço IP, data e hora, e '
            'informações guardadas no aparelho para manter você conectada.',
        'A câmera e as fotos só são acessadas quando você escolhe tirar ou '
            'enviar uma imagem.',
      ],
    ),
    (
      titulo: '2. Para que usamos',
      paragrafos: [
        'Para criar sua conta, fazer o aplicativo funcionar, proteger os '
            'dados, dar suporte e cumprir obrigações legais.',
        'Não vendemos dados, não usamos os dados das suas clientes para '
            'propaganda e não os compartilhamos com outras consultoras.',
      ],
    ),
    (
      titulo: '3. Quem é responsável',
      paragrafos: [
        'Pelos dados da sua conta, o responsável é '
            '${TermosDeUso.responsavel}, que mantém o aplicativo Sou '
            'Consultora.',
        'Pelos dados das suas clientes, a responsável é você. O aplicativo '
            'apenas guarda essas informações para você.',
        'Para consultar, corrigir ou apagar seus dados, escreva para '
            '${TermosDeUso.emailContato}.',
      ],
    ),
    (
      titulo: '4. Com quem compartilhamos',
      paragrafos: [
        'Com os serviços necessários para o aplicativo funcionar: provedores '
            'de hospedagem e armazenamento, Google e Apple (login).',
        'Esses serviços podem armazenar dados em servidores fora do Brasil.',
        'Também podemos entregar dados quando a lei ou uma ordem judicial '
            'exigir.',
      ],
    ),
  ];
}
