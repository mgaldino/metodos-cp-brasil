# Análise bayesiana hierárquica por classificação binária do primeiro prenome

**Data de execução:** 2026-07-19

## Síntese

A inferência principal substitui os testes separados de proporções e o ajuste de Mantel–Haenszel por seis modelos logísticos hierárquicos. Os artigos formam o primeiro nível; os nove periódicos elegíveis são tratados como unidades permutáveis no segundo nível. Tanto o intercepto quanto a diferença associada à categoria feminina variam entre periódicos e recebem pooling parcial.

Há probabilidade posterior de pelo menos 95% de uma diferença menor que −2 p.p. para: Análise quantitativa; Inferência estatística; Examinados para identificação. Há probabilidade posterior de pelo menos 95% de uma diferença maior que +2 p.p. para: Artigos empíricos. Os demais resultados são inconclusivos ou pequenos segundo essa margem: Linguagem causal ou explicativa; Estratégia explícita de identificação.

As estimativas são descritivas e correlacionais. O modelo descreve associações condicionais a periódico e período; não identifica efeito causal de gênero.

## Especificação

Para cada indicador binário pré-especificado, foi ajustado:

`logit Pr(y_ij = 1) = α_j + β_j Feminino_ij + γ_2 Período2_ij + γ_3 Período3_ij`,

em que `(α_j, β_j)` segue uma distribuição normal multivariada entre periódicos. O contraste reportado é a diferença posterior de probabilidade entre `Feminino = 1` e `Feminino = 0`, padronizada pela composição observada de periódico e período no denominador de cada indicador.

O pooling parcial regulariza sobretudo os contrastes de periódicos com poucos artigos ou eventos. Por isso não se corrigem p-valores para as nove comparações: elas são estimadas conjuntamente. O argumento segue Gelman, Hill e Yajima (2012), que recomendam modelagem multilevel quando efeitos relacionados são permutáveis.

Ressalva: os seis indicadores são desfechos distintos e foram estimados separadamente. O pooling entre periódicos não elimina automaticamente a multiplicidade entre desfechos; por isso eles são seis estimandos pré-especificados, sem declaração binária global de ‘significância’. Reportam-se a distribuição posterior, a direção e a probabilidade de diferença substantiva maior que 2 p.p.

## Resultados

**Tabela 1. Diferenças posteriores padronizadas entre as categorias feminina e masculina do primeiro prenome**

| Indicador | N | Diferença posterior média F−M | ICr 95% | Pr(F−M > 0) | Pr(F−M < −2 p.p.) | Pr(F−M > +2 p.p.) | Pr(ROPE ±2 p.p.) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Artigos empíricos | 3.970 | +4,2 p.p. | [+1,9 p.p.; +6,5 p.p.] | > 0,999 | < 0,001 | 0,972 | 0,028 |
| Análise quantitativa | 3.276 | -5,2 p.p. | [-8,4 p.p.; -1,9 p.p.] | < 0,001 | 0,969 | < 0,001 | 0,031 |
| Inferência estatística | 1.938 | -12,5 p.p. | [-16,6 p.p.; -8,4 p.p.] | < 0,001 | > 0,999 | < 0,001 | < 0,001 |
| Linguagem causal ou explicativa | 3.276 | +0,3 p.p. | [-0,8 p.p.; +1,4 p.p.] | 0,715 | < 0,001 | 0,002 | 0,998 |
| Examinados para identificação | 3.970 | -5,8 p.p. | [-8,6 p.p.; -3,0 p.p.] | < 0,001 | 0,996 | < 0,001 | 0,004 |
| Estratégia explícita de identificação | 1.359 | -1,5 p.p. | [-3,6 p.p.; +0,7 p.p.] | 0,086 | 0,323 | 0,002 | 0,676 |

*Nota:* F−M é feminino menos masculino. ICr é o intervalo de credibilidade posterior de 95%. A ROPE de ±2 p.p. é uma margem descritiva de equivalência prática, não um limiar universal.

![Diferenças posteriores hierárquicas](../output/figures/gender_analysis/figure_3_bayesian_hierarchical_gender_effects.png)

*Figura 1. Diferenças posteriores padronizadas entre as categorias feminina e masculina do primeiro prenome.* As barras são ICr de 95%; a faixa cinza é a ROPE de ±2 p.p.

Os contrastes parcialmente agrupados por periódico estão em `output/tables/gender_analysis/table_14_bayesian_gender_effects_by_journal.csv`. Com nove periódicos, a heterogeneidade entre eles tem incerteza relevante.

## Priors

Foram usadas priors fracamente informativas, não priors impróprias ou supostamente não informativas:

- intercepto global: Student-t(3, 0, 2,5);
- coeficientes globais de gênero e período: Normal(0, 0,75) na escala logit;
- desvios-padrão entre periódicos: half-Student-t(3, 0, 1);
- correlação entre intercepto e contraste do periódico: LKJ(2).

A regularização segue Gelman (2006) para priors half-t em escalas hierárquicas e Gelman et al. (2008) para priors fracamente informativas em regressão logística. Priors próprias estabilizam especialmente o indicador raro de estratégia explícita de identificação.

## Diagnósticos

**Tabela 2. Diagnósticos dos modelos bayesianos hierárquicos**

| Indicador | N | Eventos | R-hat máximo | ESS bulk mínimo | ESS tail mínimo | Divergências | Treedepth máximo | PPC prevalência |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Artigos empíricos | 3.970 | 3.276 | 1,005 | 792 | 869 | 0 | 0 | PASS |
| Análise quantitativa | 3.276 | 1.943 | 1,004 | 1.031 | 1.517 | 0 | 0 | PASS |
| Inferência estatística | 1.938 | 727 | 1,003 | 892 | 1.203 | 0 | 0 | PASS |
| Linguagem causal ou explicativa | 3.276 | 3.185 | 1,007 | 803 | 716 | 0 | 0 | PASS |
| Examinados para identificação | 3.970 | 1.359 | 1,003 | 796 | 1.149 | 0 | 0 | PASS |
| Estratégia explícita de identificação | 1.359 | 59 | 1,002 | 1.278 | 1.602 | 0 | 0 | PASS |

*Nota:* cada modelo usou 4 cadeias, 2.000 iterações por cadeia, 1.000 de aquecimento, `adapt_delta = 0.99` e `max_treedepth = 12`. PASS exige R-hat < 1,01, ESS bulk e tail mínimos ≥ 400, nenhuma divergência, nenhuma saturação de treedepth e prevalência observada dentro do intervalo preditivo posterior de 95%.

## População e limites

A entrada é derivada do CSV canônico corrente e exclui `Lua Nova: Revista de Cultura e Política`, `Novos estudos CEBRAP`, `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais`. Somente artigos cujo primeiro prenome foi classificado como feminino ou masculino entram nos modelos.

A proxy não observa identidade de gênero, exclui identidades não binárias e tem não classificação diferencial. A ordem de autoria não mede contribuição. O modelo não trata a classificação como incerta e não controla subcampo, idioma, coautoria ou repetição da mesma pessoa.

## Reprodutibilidade

- Script gerador: `scripts/54_fit_bayesian_gender_hierarchical.R`.
- Base de entrada: `data/processed/gender_analysis/current_canonical_article_gender.csv`, gerada por `scripts/51_analyze_gender_current_canonical.R`.
- MD5 da base de entrada: `9ba855c38cb5509c2c778b0237ff7f22`.
- Ambiente: `R 4.4.2; brms 2.23.0; cmdstanr 0.9.0; posterior 1.6.1; CmdStan 2.37.0`.
- Os objetos `brmsfit` são cache local em `data/processed/gender_analysis/bayesian_models/` e não são versionados devido ao tamanho.

## Referências metodológicas

- Gelman, A. (2006). Prior distributions for variance parameters in hierarchical models. *Bayesian Analysis*, 1(3), 515–534. https://doi.org/10.1214/06-BA117A
- Gelman, A., Jakulin, A., Pittau, M. G., & Su, Y.-S. (2008). A weakly informative default prior distribution for logistic and other regression models. *The Annals of Applied Statistics*, 2(4), 1360–1383. https://doi.org/10.1214/08-AOAS191
- Gelman, A., Hill, J., & Yajima, M. (2012). Why we (usually) don’t have to worry about multiple comparisons. *Journal of Research on Educational Effectiveness*, 5(2), 189–211. https://doi.org/10.1080/19345747.2011.618213

## Validações automáticas

**Tabela 3. Validações da análise bayesiana**

| Validação | Status |
| --- | --- |
| PIDs únicos na base de entrada | PASS |
| Apenas categorias binárias entram nos modelos | PASS |
| Nove periódicos em todos os denominadores | PASS |
| Desfechos binários com variação | PASS |
| R-hat, ESS e amostragem NUTS aprovados | PASS |
| Prevalência observada coberta pela checagem preditiva posterior | PASS |
| Probabilidades posteriores dentro de [0, 1] | PASS |
