# Síntese do paper e variáveis finais — 2026-07-08

## Status

Documento de planejamento substantivo produzido a partir de entrevista de refinamento do paper em 2026-07-08. O objetivo é fixar a tese provisória, a pergunta de pesquisa, o posicionamento na literatura, a estrutura esperada dos resultados e o conjunto final de variáveis necessárias para a análise.

Este documento não substitui o plano operacional de classificação do corpus completo. Ele define o desenho analítico do paper a ser implementado depois que a base classificada elegível estiver consolidada.

## Tese provisória

A Ciência Política brasileira avançou em profissionalização metodológica, mas de forma seletiva, incompleta e pouco padronizada. O problema central não é apenas a baixa difusão de métodos causais associados à revolução da credibilidade. O diagnóstico mais amplo é a persistência de baixa explicitação metodológica, baixa padronização da arquitetura textual do artigo empírico e adoção desigual de práticas contemporâneas de quantificação, causalidade, identificação e transparência inferencial.

A tese não deve ser formulada como uma crítica ao pluralismo metodológico em si. Artigos teóricos, ensaios, estudos qualitativos e revisões têm lugar legítimo. O problema substantivo é a opacidade ou baixa padronização em artigos que fazem trabalho empírico, explicativo ou causal sem explicitar claramente dados, método, estratégia analítica, resultados e limites inferenciais.

## Pergunta de pesquisa

Duas décadas depois do diagnóstico do "calcanhar metodológico", em que medida os artigos de Ciência Política, Relações Internacionais e Administração Pública publicados no Brasil entre 2005 e 2025 apresentam práticas metodológicas explícitas, padronizadas e compatíveis com convenções contemporâneas de pesquisa empírica?

Uma formulação alternativa, mais direta:

> Como se organiza a prática metodológica dos artigos brasileiros de Ciência Política, Relações Internacionais e Administração Pública entre 2005 e 2025, e onde persistem lacunas de explicitação, padronização e identificação?

## Posicionamento na literatura

### Interlocutor principal

O paper deve dialogar primeiro com a literatura brasileira sobre formação metodológica, profissionalização da Ciência Política, "calcanhar metodológico" e "obscuridade metodológica".

Referências centrais já identificadas:

- Soares (2005), como diagnóstico inicial do calcanhar metodológico.
- Barberia, Godoy e Barboza (2014), sobre ensino de métodos e formação metodológica.
- Albuquerque, Mesquita e Brito (2022), sobre obscuridade metodológica em RI e áreas afins.
- Figueiredo et al. (2019), sobre transparência e reprodutibilidade.

### Interlocutor secundário

Torreblanca et al. (2026) devem entrar como referência internacional e operacional. O paper brasileiro não precisa replicar somente a pergunta estreita da revolução da credibilidade. A contribuição de Torreblanca et al. deve ser aproveitada principalmente em quatro pontos:

1. Lógica de funil: corpus total, artigos empíricos, artigos quantitativos, artigos explicativos/causais, métodos de identificação e práticas de credibilidade.
2. Distinção entre alcance e profundidade da mudança metodológica.
3. Cautela interpretativa: medir convenções de apresentação, justificativa metodológica e transparência inferencial, não "qualidade" final dos achados.
4. Heterogeneidade por periódico e subcampo.

### Literatura a evitar como eixo principal

O paper não deve se estruturar principalmente como sociologia do campo científico. A noção de hierarquias do campo pode aparecer de forma leve e empírica, especialmente por periódico, Qualis e subcampo, mas o foco deve permanecer no diagnóstico metodológico da produção publicada.

## Argumento

O paper deve tratar a revolução da credibilidade como a ponta mais exigente de uma transformação metodológica mais ampla. Antes de perguntar se há diferença-em-diferenças, regressão descontínua, experimento, variável instrumental ou controle sintético, o paper pergunta se o artigo empírico deixa claro:

1. qual evidência usa;
2. qual método aplica;
3. qual inferência pretende fazer;
4. como organiza dados, método, resultados e interpretação;
5. quais limites ou ameaças inferenciais reconhece.

O achado esperado não é simplesmente "há poucos métodos causais modernos". O achado mais importante deve ser que a arquitetura do artigo empírico brasileiro ainda não está plenamente estabilizada: muitos textos empíricos não oferecem ao leitor uma estrutura comum para localizar método, dados, resultados e limites inferenciais.

## Estratégia de resultados

Os resultados devem seguir um funil inspirado em Torreblanca et al., mas ampliado para o diagnóstico brasileiro:

1. Do corpus total ao artigo empírico.
2. Entre os empíricos, grau de explicitação metodológica.
3. Tipo de evidência e tipo de análise: qualitativo, quantitativo, misto, descritivo, bivariado, modelagem.
4. Arquitetura do artigo empírico: presença substantiva e estrutural de método, dados, resultados e discussão.
5. Causalidade e identificação: claims causais, designs causais, discussão de identificação e práticas de credibilidade.
6. Heterogeneidade: periódico primeiro; depois agrupamentos por Qualis, área disciplinar, período e, secundariamente, gênero de autoria.

## Eixos de heterogeneidade

### Eixo principal

O eixo principal deve ser o periódico individual. As tabelas e figuras principais devem deixar os padrões emergirem por periódico antes de impor categorias agregadas.

### Agrupamentos interpretativos

Depois da apresentação por periódico, os resultados podem ser interpretados por:

- Qualis A1 versus demais, se houver tabela confiável de Qualis por periódico.
- Ciência Política, Relações Internacionais e Administração Pública.
- Períodos: 2005-2011, 2012-2018 e 2019-2025.

### Eixo secundário

Gênero de autoria deve entrar apenas como análise secundária/exploratória. A inferência por nome deve sempre incluir categorias de incerteza e não deve sustentar claims causais ou explicações fortes sobre preferência metodológica.

## Periodização

Usar três períodos:

1. 2005-2011: período inicial após o diagnóstico do calcanhar metodológico.
2. 2012-2018: período intermediário de expansão, profissionalização e internacionalização gradual.
3. 2019-2025: período recente, no qual práticas internacionais de transparência, causalidade, reprodutibilidade e arquitetura empírica estão mais disponíveis.

A periodização deve ser usada como dimensão secundária. O paper não deve depender de uma tendência anual limpa. A pergunta principal é a organização metodológica do campo, não uma série temporal fina.

## Variáveis finais

### Unidade de análise

- `pid`: identificador do artigo.

### Variáveis de contexto

- `year`: ano de publicação.
- `period_3`: `2005-2011`, `2012-2018`, `2019-2025`.
- `journal_title`: periódico.
- `journal_area`: Ciência Política, Relações Internacionais, Administração Pública ou híbrido.
- `qualis_group`: A1 versus demais, se houver fonte confiável.
- `language`: idioma do artigo.
- `n_authors`: número de autores.
- `first_author_gender`: gênero inferido do primeiro autor, com categoria `unknown`.
- `team_gender_composition`: composição de gênero da equipe, com categoria `unknown`.

### Dimensão 1: artigo empírico e tipo de evidência

Variáveis centrais:

- `is_empirical_paper`: o artigo apresenta evidência empírica própria ou reanalisada.
- `empirical_evidence_type`: `none`, `qualitative_only`, `quantitative_only`, `mixed_empirical`.
- `is_empirical_quant_paper_torreblanca`: o artigo é empírico quantitativo no sentido do funil de Torreblanca et al.
- `is_empirical_qual_paper`: o artigo apresenta evidência qualitativa substantiva.
- `sample_or_data_source_present`: o artigo explicita fonte de dados, amostra, corpus, documentos ou evidências.

Observação: parte dessas variáveis já existe no classificador atual. `sample_or_data_source_present` pode ser derivada de `sample_or_data_source`, mas precisa de regra explícita.

### Dimensão 2: explicitação metodológica

Variáveis centrais:

- `method_explicitness`: `clear`, `partial`, `absent`.
- `method_section_present`: o artigo tem seção ou subtítulo explícito de método, metodologia, dados, procedimentos ou estratégia empírica.
- `data_source_explained`: o artigo explica substantivamente a fonte de dados.
- `analytic_strategy_explained`: o artigo explica substantivamente como a evidência é analisada.

Definição operacional proposta:

- `clear`: artigo empírico explicita dados/fontes e estratégia de análise de forma suficiente para o leitor entender como o resultado foi produzido.
- `partial`: artigo empírico menciona dados ou método, mas de forma incompleta, dispersa ou sem estratégia analítica clara.
- `absent`: artigo empírico usa evidência, mas não explicita método, dados ou estratégia analítica de forma minimamente rastreável.

Essa é uma dimensão crítica para a tese. O classificador atual não captura isso de forma perfeita; será necessário derivar a partir dos reading logs ou rodar uma classificação complementar.

### Dimensão 3: quantificação e inferência

Variáveis centrais:

- `quantitative_analysis_type`: `none`, `descriptive_statistics_only`, `bivariate_tests_or_correlations_only`, `statistical_modeling`.
- `has_statistical_inference`: presença de teste, intervalo, erro-padrão, p-valor, modelo inferencial ou inferência estatística equivalente.
- `claims_statistical_significance`: o artigo afirma resultados estatisticamente significativos.
- `specifies_estimate_equations`: o artigo apresenta equações ou especificação formal do modelo.

Observação: `quantitative_analysis_type` e `has_statistical_inference` já existem no classificador atual. `claims_statistical_significance` e `specifies_estimate_equations` existem na classificação antiga e devem ser avaliadas antes de uso; se necessário, entram em rodada complementar.

### Dimensão 4: formato e arquitetura do artigo empírico

Variáveis centrais:

- `clear_section_structure`: o artigo possui estrutura de seções discernível.
- `methods_or_data_section_present`: há seção explícita ou funcional de método, metodologia, dados ou procedimentos.
- `results_or_analysis_section_present`: há seção explícita ou funcional de resultados, análise ou achados.
- `discussion_or_conclusion_present`: há seção de discussão, considerações finais ou conclusão.
- `imrad_like`: o artigo tem arquitetura funcional próxima a introdução, método/dados, resultados/análise e discussão/conclusão.
- `empirical_article_format`: `imrad_like`, `structured_non_imrad`, `essayistic_empirical`, `theoretical_or_review`, `unclear`.

Definição operacional proposta:

- `imrad_like`: artigo empírico com seções ou funções textuais equivalentes a introdução, dados/método, resultados/análise e discussão/conclusão.
- `structured_non_imrad`: artigo empírico com estrutura clara, mas organizada por caso, tema, período, argumento ou seção substantiva, sem padrão IMRaD.
- `essayistic_empirical`: artigo empírico que usa evidência, mas a organiza em fluxo ensaístico, sem seção clara de método/dados/resultados.
- `theoretical_or_review`: artigo não empírico, teórico, normativo, bibliográfico ou de revisão.
- `unclear`: estrutura insuficientemente identificável.

Essa dimensão é indispensável para a tese de baixa padronização do artigo empírico. Ela deve ser construída a partir dos `section_reading_log` ou de classificação complementar.

### Dimensão 5: causalidade e credibilidade

Variáveis centrais:

- `causal_or_explanatory_claim_present`: presença de claim explicativo ou causal.
- `credibility_revolution_screen_applicable`: artigo entra no funil causal/quantitativo.
- `credibility_revolution_screen_reason`: razão de entrada ou exclusão do screen.
- `credibility_revolution_method_present`: presença bruta de método associado à revolução da credibilidade.
- `credibility_revolution_method_type`: tipo de método identificado.
- `strict_design_method`: derivada; conta apenas desenhos estritos de identificação causal.
- `diagnostic_not_design`: derivada; identifica regressão observacional com claim causal, fixed effects causal sem desenho, ou casos sem desenho detectado.
- `identification_assumptions_discussed`: o artigo discute suposições de identificação.
- `discusses_threats_to_causality`: o artigo discute ameaças à causalidade.
- `placebo_test`: presença de placebo test.
- `references_power_analysis`: referência a análise de poder estatístico.
- `mentions_pre_registered_design_and_analysis_plan`: menção a pré-registro ou plano de análise.
- `robustness_or_sensitivity_checks`: presença de robustez, sensibilidade ou checagens equivalentes.

Observação: parte dessas variáveis está no classificador atual, parte na classificação antiga e parte talvez exija rodada complementar. `strict_design_method` deve seguir regra conservadora: SEM, mediação causal e regressão observacional não contam como método de credibilidade sem discussão explícita de identificação e plausibilidade das hipóteses.

## Denominadores obrigatórios

Todas as tabelas devem explicitar o denominador:

- Corpus completo elegível.
- Artigos empíricos.
- Artigos empíricos quantitativos.
- Artigos com claim causal ou explicativo.
- Artigos no screen de credibilidade.

Essa disciplina de denominadores é central para evitar overclaiming.

## Variáveis mínimas para o núcleo do paper

Se for necessário reduzir a análise principal, o núcleo deve incluir:

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

## Figuras e tabelas centrais

### Figura 1: Funil do corpus

Fluxo do corpus completo para artigos empíricos, artigos com método explícito, artigos quantitativos, artigos com claim causal/explicativo e artigos com desenho estrito de identificação.

### Figura 2: Matriz periódico por dimensão

Mapa de calor ou dot plot com periódicos nas linhas e dimensões nas colunas:

- proporção de artigos empíricos;
- proporção de artigos empíricos com método explícito claro;
- proporção de artigos quantitativos;
- proporção de artigos com arquitetura `imrad_like`;
- proporção de artigos com claim causal/explicativo;
- proporção de artigos com desenho estrito de identificação.

### Figura 3: Variação por período

Comparação das dimensões principais entre 2005-2011, 2012-2018 e 2019-2025.

### Figura 4: Periódico e período

Se houver tamanho suficiente, mostrar mudança por periódico ou por blocos emergentes de periódico ao longo dos três períodos.

### Tabela 1: Descrição do corpus

Artigos por periódico, período, idioma, área e status de inclusão/exclusão.

### Tabela 2: Dimensões metodológicas

Resumo das quatro dimensões centrais por denominador relevante.

### Tabela 3: Causalidade e credibilidade

Claims causais, desenhos, identificação e práticas de credibilidade entre artigos no screen apropriado.

### Apêndice

- Validação da classificação.
- Regras de derivação das variáveis.
- Robustez de periodização.
- Heterogeneidade por Qualis e gênero de autoria.

## Próximos passos operacionais

1. Auditar quais variáveis finais já existem no classificador atual.
2. Criar tabela de mapeamento: variável final, fonte, regra de derivação, necessidade de classificação complementar.
3. Consolidar `period_3`, `journal_area` e, se possível, `qualis_group`.
4. Derivar variáveis de formato a partir dos `section_reading_log`.
5. Se os reading logs forem insuficientes, rodar classificador complementar apenas para explicitação metodológica e arquitetura textual.
6. Produzir uma amostra manual de validação para `method_explicitness` e `empirical_article_format`.
7. Só depois escrever a seção de resultados do paper.

## Decisões de escopo

- Não transformar as dimensões em índice único de "internacionalização metodológica".
- Não fazer claims causais sobre por que certos periódicos ou subcampos são mais próximos da fronteira internacional.
- Não tratar Qualis como medida normativa de qualidade; usar, no máximo, como proxy institucional de posição no campo.
- Não tornar gênero de autoria eixo central da tese.
- Não apresentar a amostra piloto de 175 ou blocos parciais como base final substantiva do paper.

