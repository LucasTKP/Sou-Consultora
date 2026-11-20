# Cards de lista — padrão obrigatório

Todo card de lista do app (clientes, recebimentos, boletos, vendas, produtos, serviços, fornecedores…) segue o mesmo desenho. Quem criar ou alterar um card **não** monta layout próprio: usa `CartaoListaApp` e, para a situação, `LinhaSituacaoApp`.

## Estrutura

```
[ foto 56 ]  Nome da cliente ou do item            >
             Status em cor · detalhe · detalhe
```

1. **Foto/avatar**: `TamanhoAvatar.card` (56 px). `miniatura` (40 px) só em linhas dentro de um detalhe ou formulário, nunca em card de lista.
2. **Linha 1 (título)**: só o nome, com a **largura toda** (até a seta). Nada de selo, valor ou status à direita disputando espaço com ele.
3. **Linha 2 (situação)**: **uma linha só**, via `LinhaSituacaoApp`: o status em cor e negrito, seguido dos detalhes em texto normal separados por ` · `.
   - Exemplo: `Atrasado (15/10) · R$ 120,00`, `2 atrasadas · R$ 1.250,00`, `Em dia · Última compra há 3 dias`.
   - Quando o card mostra um valor, **ele é o último item**: nada depois do valor (não cabe). Dado extra (ex.: nº da parcela) vai para a tela de detalhe.
   - Ordem de importância: o que passa do espaço é cortado com reticências **no fim**, nunca o status.
4. **Status curto**: uma ou duas palavras mais, no máximo, a data ou o valor. Nada de frase ("Parcela atrasada" + "Deve R$ X" ao mesmo tempo = ambíguo; escolha um).
5. **Cor do status** vem do `StatusSelo` (`status.corTexto`): sucesso, alerta, perigo, neutro, primário. Não invente cor por card.
6. **Seta** (`>`) só quando o card abre algo.

## O que não fazer

- Selo (chip) à direita do card ou ao lado do nome: ele limita nome e segunda linha ao mesmo tempo e fica desalinhado.
- Selo grande ou de página (`TamanhoSelo.pagina`) em card.
- Subtítulo e status em linhas separadas quando cabem na mesma.
- Texto que depende do tamanho de fonte do celular: o app ignora o ajuste de fonte do sistema (`main.dart`), então o layout deve caber no tamanho padrão.

## Onde fica

- `ui/widgets/cards/cartao_lista_app.dart` — o card.
- `ui/widgets/cards/linha_situacao_app.dart` — segunda linha (status + detalhes).
- Selo (`SeloStatusApp`) continua valendo nas **telas de detalhe** e em cabeçalhos, não em card de lista.

## Cards que ainda não seguem (alinhar ao mexer neles)

`cartao_fornecedor`, `cartao_boleto`, `cartao_produto` e o card de compras do cliente ainda usam selo ou outra montagem. Ao tocar em qualquer um, migre para este padrão no mesmo commit.
