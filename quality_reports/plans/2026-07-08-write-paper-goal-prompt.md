# Prompt `/goal` para escrever o paper

Use uma das duas opções abaixo em uma nova sessão Codex aberta na raiz do repositório.

## Opção curta

Copie e cole este bloco curto na nova sessão:

```text
/goal Leia integralmente `quality_reports/plans/2026-07-08-write-paper-goal-prompt.md`, ignore a seção "Opção curta" depois de entendê-la, e execute o bloco longo em "Opção completa" como a especificação operacional do goal. Siga todos os gates, separações entre implementação e revisão, skills obrigatórias, verificações e critérios de encerramento definidos naquele bloco. Não faça commit ou push sem pedido explícito.
```

## Opção completa

Copie e cole o bloco longo abaixo se quiser passar toda a especificação diretamente na conversa.

````text
/goal Escrever uma versão metodologicamente defensável do paper `paper/paper.Rmd`, substituindo os placeholders atuais por texto, tabelas, figuras e um PDF renderizado, sem overclaiming sobre dados ainda incompletos. O processo deve separar implementação e revisão: cada parte substantiva do paper deve ser escrita por um subagente implementador independente e revisada por outro subagente, sempre com Devil's Advocate. Quem revisa não implementa; quem implementa não revisa o próprio trabalho.

Você está em `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP`.

## Fontes obrigatórias de contexto

Leia antes de agir:

- `AGENTS.md`
- `README.md`
- `quality_reports/plans/2026-07-08-paper_sintese_variaveis_finais.md`
- `paper/paper.Rmd`
- `references.bib`
- `scripts/34_build_preliminary_credibility_analysis.R`
- `data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md`

O `paper/paper.Rmd` hoje contém placeholders no resumo e nas seções: Introdução, Contexto e Expectativas, Dados, Estratégia Empírica, Resultados, Discussão e Conclusão. O objetivo é substituir esses placeholders por uma versão compilável. Não trate o arquivo como pronto.

## Gatilhos metodológicos

- A tese provisória é que a Ciência Política brasileira avançou em profissionalização metodológica, mas de modo seletivo, incompleto e pouco padronizado.
- Não formule o paper como ataque ao pluralismo metodológico.
- O problema substantivo é opacidade ou baixa padronização em artigos que fazem trabalho empírico, explicativo ou causal sem explicitar claramente dados, método, estratégia analítica, resultados e limites inferenciais.
- Torreblanca et al. (2026) entram como referência internacional e operacional, sobretudo pelo funil, pela distinção entre alcance e profundidade da mudança metodológica e pela cautela interpretativa.
- O interlocutor principal é a literatura brasileira sobre calcanhar metodológico, formação metodológica, obscuridade metodológica, transparência e reprodutibilidade.
- Não estruturar o paper como sociologia do campo científico. Periódico, Qualis e subcampo entram como heterogeneidade empírica, não como explicação causal forte.

## Gate 0: checagem de completude e escopo

Antes de escrever Resultados finais, faça uma auditoria reprodutível da base disponível.

Use como candidatos canônicos:

- Manifesto do corpus completo: `data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv`
- Classificações combinadas: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`
- Logs de leitura: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/reading_logs/`
- Texto integral do corpus: `data/processed/fulltext_corpus/article_texts_corpus.csv`

Verifique:

- número de PIDs no manifesto;
- número de PIDs classificados;
- se há um reading log válido por PID classificado;
- se `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` estão fora da base analítica;
- se os anos estão em 2005-2025;
- se os denominadores relevantes estão explícitos;
- se a classificação atual cobre o corpus completo ou apenas um subconjunto.

Se o corpus completo ainda não estiver classificado, não escreva resultados finais como se a base estivesse completa. Nesse caso, escreva uma versão preliminar honesta do manuscrito apenas se for possível rotular claramente os resultados como preliminares e registrar a limitação no resumo, nos Dados, nos Resultados e na Conclusão. Se isso comprometer a tese do paper, pare e reporte o bloqueio.

## Skills e papéis

Use `tool_search` para expor ferramentas de subagentes, se elas não estiverem visíveis.

Use skills assim:

- `data-analysis-r`: agente implementador de análise, validação, derivação de variáveis, tabelas e figuras.
- `review-r`: agente revisor independente de todo script R e de artefatos derivados por R. O revisor não edita arquivos.
- `review-python`: somente se algum script Python for editado. O revisor não edita arquivos.
- `devils-advocate`: revisão obrigatória de cada seção substantiva e do argumento integrado. O revisor não edita arquivos.
- `rewrite-introduction`: usar apenas depois de haver uma versão integrada do paper. A skill deve propor uma introdução reescrita e notas; um agente implementador diferente decide/aplica a incorporação se a proposta for consistente com os resultados.

## Separação entre implementação e revisão

Crie diretórios, se necessário:

- `quality_reports/paper_drafts/`
- `quality_reports/paper_reviews/`
- `quality_reports/paper_variable_audit/`

Para cada seção, siga este ciclo:

1. Um subagente implementador escreve um rascunho da seção em `quality_reports/paper_drafts/`.
2. Um subagente revisor diferente aplica `devils-advocate` e salva relatório em `quality_reports/paper_reviews/`.
3. O implementador, não o revisor, incorpora correções defensáveis no rascunho e depois no `paper/paper.Rmd`.
4. Registre em uma nota curta o que foi aceito, rejeitado ou deixado para o autor.

Seções mínimas e agentes separados:

- Introdução
- Contexto e Expectativas
- Dados
- Estratégia Empírica
- Resultados
- Discussão
- Conclusão
- Resumo, escrito por último

## Variáveis e análise

Antes de editar o texto do paper, crie ou atualize scripts R reprodutíveis para:

- mapear variáveis finais, fonte, regra de derivação, disponibilidade e necessidade de classificação complementar;
- construir a base analítica do paper;
- gerar tabelas e figuras usadas no manuscrito.

Use R para análise. Não faça análise substantiva em comandos inline. Use `dplyr::select()` sempre que selecionar colunas.

Variáveis mínimas do núcleo:

- `is_empirical_paper`
- `method_explicitness`
- `empirical_evidence_type`
- `quantitative_analysis_type`
- `has_statistical_inference`
- `empirical_article_format`
- `causal_or_explanatory_claim_present`
- `strict_design_method`
- `journal_title`
- `journal_area`
- `period_3`

Se `method_explicitness` ou `empirical_article_format` não puderem ser derivadas com segurança dos logs e classificações existentes, não invente proxy fraca. Produza a auditoria de lacuna e proponha uma rodada complementar de classificação. Só use essas dimensões em resultados se a regra de derivação e a validação forem defensáveis.

Denominadores obrigatórios:

- corpus completo elegível;
- artigos empíricos;
- artigos empíricos quantitativos;
- artigos com claim causal ou explicativo;
- artigos no screen de credibilidade.

## Figuras e tabelas esperadas

Produza apenas figuras e tabelas que os dados disponíveis sustentam. As principais desejadas são:

- Figura 1: funil do corpus.
- Figura 2: matriz periódico por dimensão.
- Figura 3: variação por período.
- Figura 4: periódico e período, se houver tamanho suficiente.
- Tabela 1: descrição do corpus.
- Tabela 2: dimensões metodológicas.
- Tabela 3: causalidade e credibilidade.

Todas as figuras e tabelas devem ser numeradas, ter caption e informar denominador.

## Redação do paper

Escreva em português acadêmico claro, com acentos, UTF-8 e sem prosa inflada.

Regras substantivas:

- Não usar a amostra de 175 como base final substantiva.
- Não fazer claim causal sobre por que certos periódicos ou subcampos diferem.
- Não tratar Qualis como medida normativa de qualidade.
- Não tornar gênero de autoria eixo central.
- Não transformar as dimensões em índice único de internacionalização metodológica.
- Não contar SEM, mediação causal, regressão observacional ou efeitos fixos como método de revolução da credibilidade sem discussão explícita de identificação e plausibilidade das hipóteses.

Atualize `paper/paper.Rmd` para ler os outputs gerados pelos scripts, não CSVs obsoletos, e para renderizar com `xelatex`.

## Verificação obrigatória

Antes de encerrar:

1. Rode os scripts R criados/alterados.
2. Submeta scripts R e artefatos derivados a `review-r` por agente independente e corrija o que for procedente.
3. Rode a revisão `devils-advocate` integrada do paper completo por agente que não escreveu nenhuma seção.
4. Renderize `paper/paper.Rmd` para PDF.
5. Rode `git diff --check`.
6. Verifique que não restam placeholders:

```bash
rg -n "Resumo a completar|Texto a completar|\\[.*a completar|TODO|TBD|PLACEHOLDER" paper/paper.Rmd
```

7. Verifique o PDF com extração de texto, confirmando título, resumo, seções e ausência de placeholders.
8. Informe exatamente quais comandos passaram, quais falharam e quais limitações continuam.

## Critérios de encerramento

Não marque o goal como completo até que:

- `paper/paper.Rmd` não tenha placeholders;
- exista um PDF renderizado e abrível;
- todas as tabelas e figuras usadas tenham script de geração;
- os denominadores estejam explícitos;
- as revisões independentes estejam salvas em `quality_reports/paper_reviews/`;
- nenhum resultado final dependa da amostra piloto como se fosse corpus completo;
- limitações de cobertura/classificação estejam claras no texto.

Não faça commit ou push sem pedido explícito.
````
