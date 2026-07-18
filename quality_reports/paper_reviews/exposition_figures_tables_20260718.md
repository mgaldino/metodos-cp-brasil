# Revisão independente de exposição das figuras e tabelas

Data: 18 de julho de 2026

## Escopo

Revisão *read-only* dos títulos, rótulos, eixos, legendas e captions das sete figuras e cinco tabelas de `paper/paper.pdf`, com os critérios de `edmans-exposition`, `ggplot-dataviz` e `figure-captions`.

## Primeiro veredito: REPAIR

Foram identificados três problemas:

1. alguns rótulos da Figura 3 simplificavam a variável medida e podiam alterar sua interpretação;
2. os cabeçalhos abreviados da Tabela 3 não eram autossuficientes;
3. o caption da Figura 1 não distinguia os 5.249 artigos elegíveis dos 3.565 artigos classificados.

## Reparos

- A Figura 3 passou a nomear explicitamente a presença de linguagem causal ou explicativa, o caráter empírico do artigo e a presença ou ausência de análise quantitativa.
- A Tabela 3 passou a incluir uma nota que expande os cabeçalhos e informa os denominadores de cada percentual.
- A Figura 1 passou a distinguir o universo elegível do conjunto classificado.
- Os captions das sete figuras foram revisados para informar conteúdo, universo e regra de leitura sem linguagem interna do pipeline.
- A Figura 4 foi fixada antes da Tabela 5, preservando a ordem de apresentação do manuscrito.

## Veredito final: PASS

O revisor independente não identificou bloqueadores remanescentes. A inspeção do PDF confirmou:

- ausência de colisões, cortes ou rótulos ilegíveis;
- ausência de `screen`, “desenho estrito”, `ledger` e outros termos internos em títulos, eixos, facetas, legendas ou captions;
- eixo vertical fixo de 0% a 100% nas Figuras 5 e 7;
- correspondência entre os rótulos da Figura 3 e as variáveis efetivamente classificadas;
- captions autossuficientes e consistentes com as figuras.
