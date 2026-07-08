# Devil's Advocate Report - seção Resultados

Gerado em: 2026-07-08. Revisão independente do draft `quality_reports/paper_drafts/05_resultados_draft.md`, com base nos artefatos de auditoria e tabelas fornecidos. Não foram editados o draft nem `paper/paper.Rmd`.

## Vulnerabilidade principal

A seção é mais cautelosa do que uma versão problemática seria, mas ainda está vulnerável a uma leitura substantiva indevida de um recorte que cobre apenas 699 de 5.250 PIDs elegíveis, isto é, 13,3% do manifest. O risco central não é um erro aritmético nos números principais; é a combinação de linguagem de "resultado central", comparações por periódico/período e categorias de Tabela 3 com denominadores mistos, que pode fazer o leitor esquecer que a amostra classificada é seletiva e incompleta.

## Veredicto numérico rápido

Não encontrei, nos números explicitamente narrados, divergência direta contra os CSVs fornecidos:

1. `5.250`, `699`, `13,3%`, `4.551`, `568`, `324`, `597`, `147`, `16`, `132` e `2` batem com `denominator_summary.csv`, `table_2_methodological_dimensions.csv`, `table_3_causality_credibility.csv` e os relatórios de auditoria.
2. A decomposição da Tabela 2 também fecha: `244 + 89 + 235 = 568` artigos empíricos; `89 + 235 = 324` artigos com componente quantitativo.
3. Os percentuais narrados para a Figura 2 e Figura 3 batem com `journal_dimension_matrix.csv` e `period_dimension_summary.csv`.
4. O problema é interpretativo e de denominador, não de soma simples.

## Ataques por dimensão

### Lógica interna

1. A seção diz que os resultados são preliminares, mas ainda organiza a narrativa como se houvesse "resultados centrais" sobre padrões metodológicos da área.
   - **Severidade**: Alta.
   - **Evidência**: O Gate 0 registra que apenas 699 de 5.250 PIDs elegíveis foram classificados e que 4.551 seguem sem classificação combinada. O próprio gate determina que qualquer manuscrito precisa rotular os resultados como preliminares.
   - **Risco**: Um leitor pode aceitar a cautela inicial como nota de rodapé e, em seguida, ler os gradientes por periódico/período como achados substantivos sobre a Ciência Política brasileira, quando eles descrevem uma fila parcial de classificação.
   - **Como o autor poderia responder**: Trocar "resultado central" por formulações como "diagnóstico preliminar no conjunto classificado" e repetir o denominador seletivo junto de cada inferência interpretativa, não apenas no primeiro parágrafo.

2. A Tabela 3 mistura denominadores e a prosa pode induzir uma leitura aritmeticamente impossível.
   - **Severidade**: Alta.
   - **Evidência**: `Desenho estrito de identificação` é apresentado como `16` sobre o `screen de credibilidade` de `147`, enquanto `Diagnóstico, não desenho` é `132` sobre os `699` classificados e `Outro método moderno a auditar` é `2` sobre os `699` classificados. Na sequência textual, a frase "A Tabela 3 também registra 132 casos..." aparece logo depois de "dentro desse screen".
   - **Risco**: O leitor pode entender que `16 + 132 + 2` são subcategorias do screen de 147, o que produziria 150 casos. Isso enfraquece a credibilidade da tabela mesmo se os números estiverem corretos em seus denominadores próprios.
   - **Como o autor poderia responder**: Explicitar que as linhas da Tabela 3 não são todas mutuamente exclusivas nem usam o mesmo denominador, ou reformatar a tabela em dois painéis: funil causal/credibilidade e diagnóstico geral entre classificados.

3. A referência "A Figura 1 e a Tabela 1 tornam esse denominador explícito" está parcialmente forte demais.
   - **Severidade**: Média.
   - **Evidência**: A Tabela 1 de descrição do corpus permite inferir o total de classificados e manifest por periódico, mas não explicita sozinha que há `4.551` PIDs ainda não classificados nem que todos os `5.250` PIDs do manifest têm texto integral disponível. Esses pontos aparecem claramente no Gate 0 e em `denominator_summary.csv`; a Figura 1 também ajuda, mas a Tabela 1 não carrega toda essa afirmação.
   - **Risco**: A frase promete mais do que a tabela entrega. Em revisão, isso vira uma crítica fácil de rastreabilidade entre texto e tabela.
   - **Como o autor poderia responder**: Atribuir a afirmação ao "Gate 0/Resumo de denominadores" ou garantir que a Tabela 1 final inclua explicitamente "PIDs não classificados" e "texto integral disponível".

### Evidência empírica

1. As comparações por periódico não são comparações equilibradas de periódicos.
   - **Severidade**: Alta.
   - **Evidência**: A matriz por periódico cobre apenas três periódicos classificados: BPSR com 268/268, Cadernos Gestão Pública e Cidadania com 120/120 apenas em 2019-2025, e Contexto Internacional com 311/456 e cobertura parcial em 2019-2025. Vários periódicos centrais do manifest têm 0 classificados.
   - **Risco**: A frase sobre "heterogeneidade por periódico" pode ser lida como diferença real entre periódicos, quando parte da heterogeneidade é produzida pela própria estratégia de cobertura. Cadernos não é comparável a BPSR em série temporal, e Contexto Internacional é parcialmente censurado no período recente.
   - **Como o autor poderia responder**: Chamar a Figura 2 de "perfil dos periódicos já classificados" e declarar que ela não estima diferenças entre periódicos do manifest completo.

2. Os gradientes por período são frágeis porque período e composição do conjunto classificado mudam juntos.
   - **Severidade**: Alta.
   - **Evidência**: A Figura 3 mostra aumentos de empiria, componente quantitativo e inferência estatística entre 2005-2011, 2012-2018 e 2019-2025. Mas a Figura 4 e a Tabela 1 mostram que a cobertura por periódico-período é altamente desigual.
   - **Risco**: "Aumenta" e "gradientes" podem soar como tendência temporal da área. Com os dados atuais, também podem refletir que o conjunto 2019-2025 inclui Cadernos e BPSR completos, Contexto parcialmente, e nenhum dos demais periódicos.
   - **Como o autor poderia responder**: Rebaixar para "nos artigos atualmente classificados, os percentuais são maiores nos períodos mais recentes" e evitar qualquer leitura de tendência até completar ou balancear o corpus.

3. "Técnicas quantitativas e inferenciais aparecem de forma substantiva" é defensável, mas escorrega para uma afirmação vaga.
   - **Severidade**: Média.
   - **Evidência**: `117` artigos com modelagem estatística equivalem a `16,7%` dos classificados; `104` com inferência estatística equivalem a `14,9%`. Em outro denominador, inferência estatística é `32,1%` dos 324 artigos com componente quantitativo.
   - **Risco**: "Substantiva" pode ser lido como prevalente. Dependendo do denominador, a conclusão muda de "existe em volume relevante" para "não domina o conjunto classificado".
   - **Como o autor poderia responder**: Substituir a avaliação adjetiva por uma frase com denominadores: "aparecem em uma fração minoritária, mas não residual, do conjunto classificado".

### Escopo e generalização

1. A seção evita generalização explícita, mas ainda não bloqueia todas as inferências indevidas para "Ciência Política brasileira".
   - **Severidade**: Alta.
   - **Evidência**: O manifest completo tem 5.250 PIDs e 11 periódicos elegíveis na Tabela 1; os resultados substantivos usam 699 artigos, concentrados em três periódicos. `Brazilian Journal of Political Economy` e `Civitas` estão fora da análise principal por regra do repositório, mas vários periódicos incluídos no manifest ainda têm zero classificação combinada.
   - **Risco**: Qualquer conclusão sobre "a área" ainda depende de completar a classificação ou mostrar que o subconjunto classificado é uma base analítica desenhada para estimativas preliminares. Hoje ele funciona melhor como diagnóstico de pipeline e prova de conceito.
   - **Como o autor poderia responder**: Inserir uma sentença de escopo antes das comparações: "Estas comparações descrevem o subconjunto classificado; não estimam prevalências para o manifest nem para a área."

2. A evidência sobre "revolução da credibilidade" ainda é um funil conservador parcial, não uma mensuração completa da adoção no corpus.
   - **Severidade**: Média.
   - **Evidência**: Há `147` artigos no screen de credibilidade entre os `699` classificados e `16` desenhos estritos. A regra conservadora exclui regressão observacional causal, efeitos fixos, mediação causal e SEM sem argumento explícito de identificação.
   - **Risco**: A força do achado depende tanto da regra substantiva quanto da cobertura incompleta. O texto acerta ao chamar o numerador de conservador, mas deveria separar "baixa adoção observada" de "baixa adoção estimada no corpus".
   - **Como o autor poderia responder**: Dizer que os 16 casos são "casos detectados sob regra estrita nos artigos classificados", não uma taxa final de adoção.

### Lacunas de mensuração

1. A lacuna de `method_explicitness` e `empirical_article_format` está corretamente reconhecida, mas é perigosa para a tese substantiva do paper.
   - **Severidade**: Alta.
   - **Evidência**: A auditoria de variáveis afirma que essas duas dimensões não estão disponíveis no classificador atual e que a tese sobre baixa explicitação/padronização deve aparecer como hipótese ou desenho, não como resultado confirmado.
   - **Risco**: Se a introdução, resumo ou conclusão prometerem achados sobre explicitação metodológica e formato empírico, esta seção não sustenta a promessa. A seção de Resultados faz a ressalva, mas o manuscrito completo precisa ser coerente com ela.
   - **Como o autor poderia responder**: Blindar o texto com uma distinção rígida: resultados atuais cobrem empiria, quantificação, causalidade e desenho estrito; explicitação e formato são alvo de classificação complementar.

2. Incluir linhas `NA` na Tabela 2 pode ser bom para transparência, mas ruim como apresentação de resultado.
   - **Severidade**: Média.
   - **Evidência**: `method_explicitness` e `empirical_article_format` aparecem em `table_2_methodological_dimensions.csv` como `NA`, denominador "não disponível", e nota de que exigem classificação complementar.
   - **Risco**: Se a tabela final for lida como "dimensões metodológicas", linhas não mensuradas podem parecer falha de execução no resultado, não fronteira deliberada do classificador atual.
   - **Como o autor poderia responder**: Manter essas linhas apenas em nota/caption ou em um painel separado de "dimensões ainda não mensuradas".

### Referências a Figuras e Tabelas

1. As referências às Figuras 1-4 são, em geral, coerentes com os artefatos existentes.
   - **Severidade**: Baixa.
   - **Evidência**: Os PDFs `figure_1_corpus_funnel.pdf`, `figure_2_journal_dimension_matrix.pdf`, `figure_3_period_variation.pdf` e `figure_4_journal_period_coverage.pdf` existem, e o texto extraído deles confirma os títulos e notas de denominador.
   - **Risco**: Baixo, desde que a numeração final no `paper.Rmd` preserve essa ordem.
   - **Como o autor poderia responder**: Conferir a renderização final do PDF do paper, porque este review validou os PDFs isolados e o draft, não a paginação final do manuscrito.

2. A Tabela 3 precisa de caption mais defensiva do que o texto atual sugere.
   - **Severidade**: Alta.
   - **Evidência**: A própria tabela alterna denominadores: classificados, screen de credibilidade e classificados de novo. Isso é aceitável tecnicamente, mas só se a legenda avisar que a tabela é um funil/diagnóstico com bases distintas.
   - **Risco**: Sem caption explícita, o leitor pode tratar a tabela como distribuição única e cobrar somas que ela não foi desenhada para produzir.
   - **Como o autor poderia responder**: Caption sugerida em espírito: "As linhas usam denominadores distintos; o desenho estrito é calculado sobre o screen de credibilidade, enquanto diagnóstico e fila de auditoria são contagens entre classificados."

## Ranking de vulnerabilidades

1. **Generalização indevida a partir de 13,3% do manifest** - pode derrubar qualquer frase que soe como resultado final da área.
2. **Tabela 3 com denominadores mistos e risco de soma impossível** - ameaça a confiança no funil causal/credibilidade.
3. **Comparações por período confundidas com composição seletiva do conjunto classificado** - enfraquece a leitura de tendência temporal.
4. **Comparações por periódico sem base balanceada** - especialmente Cadernos apenas em 2019-2025 e Contexto parcialmente classificado no período recente.
5. **Lacunas `method_explicitness` e `empirical_article_format` ainda incompatíveis com uma tese forte sobre explicitação/padronização** - a seção reconhece, mas o manuscrito inteiro precisa obedecer.
6. **Referência excessiva à Tabela 1 para pontos que estão melhor documentados no Gate 0/denominator summary** - problema de rastreabilidade, não de conteúdo.

## O que sobrevive ao escrutínio

1. Os números centrais narrados no draft batem com os CSVs lidos.
2. A seção declara explicitamente que os resultados são preliminares e que cobrem apenas artigos classificados por leitura integral.
3. A regra conservadora para `strict_design_method` está alinhada com a auditoria de variáveis: SEM, mediação causal, regressão observacional e efeitos fixos não entram sem argumento explícito de identificação.
4. A seção não transforma `method_explicitness` e `empirical_article_format` em achados substantivos; ela os mantém como lacunas de mensuração.
5. As figuras existentes trazem notas de denominador e, em especial, a Figura 4 se apresenta corretamente como diagnóstico de cobertura, não como resultado substantivo.

## Condição mínima para a seção ficar defensável

A seção pode ser defensável como diagnóstico preliminar se fizer três movimentos de blindagem: primeiro, trocar linguagem de resultado substantivo por linguagem de diagnóstico do conjunto classificado; segundo, esclarecer que a Tabela 3 usa denominadores distintos e não é uma distribuição única; terceiro, bloquear explicitamente qualquer interpretação de tendência temporal ou diferença entre periódicos até que a classificação cubra o manifest completo ou uma amostra balanceada e justificada.
