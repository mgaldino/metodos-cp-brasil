# Análise adicional por gênero da autoria

**Data de execução:** 2026-07-19

## Síntese

A análise parte dos 4.389 artigos presentes no CSV canônico corrente. Após as exclusões de escopo, restam 4.157 artigos; 232 registros foram retirados. O pacote `genderBR` classificou a primeira autoria como feminina ou masculina em 3.970 casos (95,5%).

Entre as primeiras autorias classificadas, 1.323 (33,3%) foram classificadas como femininas e 2.647 como masculinas. Outros 187 artigos permaneceram sem classificação binária; 15 deles não tinham autoria registrada no manifest.

Na análise quantitativa, a prevalência foi 55,7% entre artigos com primeira autoria feminina e 61,2% entre artigos com primeira autoria masculina (diferença descritiva de -5,5 p.p.). Para estratégias explícitas de identificação, as proporções foram 3,0% e 4,9%, respectivamente.

Essas diferenças são descritivas e correlacionais. Elas não identificam preferências individuais nem efeitos de gênero, pois também podem refletir composição por periódico, período, subcampo, coautoria e outros fatores não controlados.

## População analítica e exclusões

A população de partida é o CSV canônico de classificações por leitura integral. Foram excluídos `Lua Nova: Revista de Cultura e Política` e `Novos estudos CEBRAP`, conforme solicitado. Também foram mantidas as exclusões permanentes de `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais`, exigidas pelas regras do projeto.

**Tabela 1. Distribuição do gênero inferido da primeira autoria**

| Gênero inferido | Artigos | Proporção do corpus |
| --- | --- | --- |
| Feminino | 1.323 | 31,8% |
| Masculino | 2.647 | 63,7% |
| Não classificado | 187 | 4,5% |

*Nota:* a proporção usa todos os artigos da base analítica como denominador. `Não classificado` inclui prenomes ausentes do cadastro do IBGE ou com probabilidade insuficiente para ultrapassar o limiar de 90%.

**Tabela 2. Composição de gênero inferido da equipe de autoria**

| Composição da equipe | Artigos | Proporção do corpus |
| --- | --- | --- |
| Somente mulheres | 892 | 21,5% |
| Somente homens | 2.138 | 51,4% |
| Mista | 832 | 20,0% |
| Indeterminada | 295 | 7,1% |

*Nota:* uma equipe é classificada como `Indeterminada` quando ao menos um autor não pôde ser classificado; a regra conservadora evita chamar uma equipe de exclusivamente feminina ou masculina com informação incompleta.

![Distribuição do gênero inferido da primeira autoria por período](../output/figures/gender_analysis/figure_1_first_author_gender_by_period.png)

*Figura 1. Distribuição do gênero inferido da primeira autoria por período de publicação.*

## Indicadores metodológicos por gênero da primeira autoria

**Tabela 3. Indicadores metodológicos segundo o gênero inferido da primeira autoria**

| Indicador | Feminino: n/N | Feminino: % | Masculino: n/N | Masculino: % | Diferença F−M |
| --- | --- | --- | --- | --- | --- |
| Artigos empíricos | 1.133/1.323 | 85,6% | 2.143/2.647 | 81,0% | +4,7 p.p. |
| Análise quantitativa | 631/1.133 | 55,7% | 1.312/2.143 | 61,2% | -5,5 p.p. |
| Inferência estatística | 184/629 | 29,3% | 543/1.309 | 41,5% | -12,2 p.p. |
| Linguagem causal ou explicativa | 1.103/1.133 | 97,4% | 2.082/2.143 | 97,2% | +0,2 p.p. |
| Examinados para identificação | 396/1.323 | 29,9% | 963/2.647 | 36,4% | -6,4 p.p. |
| Estratégia explícita de identificação | 12/396 | 3,0% | 47/963 | 4,9% | -1,9 p.p. |

*Nota:* cada célula apresenta numerador/denominador. Os denominadores são: todos os artigos para artigos empíricos; artigos empíricos com classificação observada para análise quantitativa e linguagem causal/explicativa; artigos quantitativos com inferência observada para inferência estatística; todos os artigos com screen observado para exame de identificação; e artigos examinados para identificação para estratégia explícita. Casos não classificados por gênero não entram na comparação feminino–masculino.

![Indicadores metodológicos por gênero inferido da primeira autoria](../output/figures/gender_analysis/figure_2_methodological_indicators_by_first_author_gender.png)

*Figura 2. Indicadores metodológicos segundo o gênero inferido da primeira autoria.*

**Tabela 4. Tipo de evidência entre artigos empíricos, por gênero inferido da primeira autoria**

| Gênero inferido | Tipo de evidência | Artigos | Denominador empírico | Proporção |
| --- | --- | --- | --- | --- |
| Feminino | Mista | 430 | 1.133 | 38,0% |
| Feminino | Somente qualitativa | 503 | 1.133 | 44,4% |
| Feminino | Somente quantitativa | 200 | 1.133 | 17,7% |
| Masculino | Mista | 694 | 2.143 | 32,4% |
| Masculino | Somente qualitativa | 828 | 2.143 | 38,6% |
| Masculino | Somente quantitativa | 621 | 2.143 | 29,0% |

*Nota:* o denominador é o total de artigos classificados como empíricos em cada grupo de gênero da primeira autoria.

## Robustez descritiva: composição da equipe

**Tabela 5. Indicadores metodológicos segundo a composição de gênero inferido da equipe**

| Indicador | Somente mulheres | Somente homens | Mista | Indeterminada |
| --- | --- | --- | --- | --- |
| Artigos empíricos | 743/892 (83,3%) | 1.677/2.138 (78,4%) | 758/832 (91,1%) | 249/295 (84,4%) |
| Análise quantitativa | 355/743 (47,8%) | 955/1.677 (56,9%) | 563/758 (74,3%) | 139/249 (55,8%) |
| Inferência estatística | 90/353 (25,5%) | 392/952 (41,2%) | 211/563 (37,5%) | 54/139 (38,8%) |
| Linguagem causal ou explicativa | 734/743 (98,8%) | 1.637/1.677 (97,6%) | 720/758 (95,0%) | 240/249 (96,4%) |
| Examinados para identificação | 211/892 (23,7%) | 700/2.138 (32,7%) | 396/832 (47,6%) | 96/295 (32,5%) |
| Estratégia explícita de identificação | 8/211 (3,8%) | 35/700 (5,0%) | 15/396 (3,8%) | 1/96 (1,0%) |

*Nota:* cada célula apresenta n/N e a proporção entre parênteses. Equipes `Indeterminadas` têm ao menos um autor não classificado; por isso, essa coluna não representa uma quarta categoria de gênero, mas informação incompleta. Os denominadores seguem as definições da Tabela 3.

## Evolução temporal

**Tabela 6. Participação feminina na primeira autoria por período**

| Período | Primeira autoria feminina | Primeiras autorias classificadas | Proporção feminina entre classificadas | Não classificadas no período |
| --- | --- | --- | --- | --- |
| 2005-2011 | 321 | 1.051 | 30,5% | 55 |
| 2012-2018 | 450 | 1.405 | 32,0% | 71 |
| 2019-2025 | 552 | 1.514 | 36,5% | 61 |

*Nota:* a proporção feminina usa somente primeiras autorias classificadas como femininas ou masculinas no período. A contagem não classificada é apresentada separadamente.

## Método e limites

Os nomes de autoria foram extraídos do manifest canônico e separados pelo delimitador `;`. O pacote `genderBR` versão 1.4.0 aplicou `get_gender(..., prob = TRUE, internal = TRUE, year = 2022)` aos nomes completos; a função usa o primeiro prenome. Foram classificados como feminino os casos com probabilidade feminina maior que 90% e como masculino os casos com probabilidade menor que 10%. Os demais ficaram como `Não classificado`.

A classificação é uma proxy baseada na distribuição de prenomes registrada pelo IBGE, não uma observação da identidade de gênero de cada pessoa. O procedimento tem cobertura inferior para nomes estrangeiros, raros, coletivos ou ambíguos e não representa identidades não binárias. A ordem de autoria também não deve ser interpretada como contribuição relativa, pois pode seguir convenções alfabéticas.

Documentação consultada em 2026-07-19: [manual oficial do pacote genderBR no CRAN](https://cran.r-project.org/web/packages/genderBR/refman/genderBR.html) e [base de nomes do Censo do IBGE](https://censo2010.ibge.gov.br/nomes/).

## Reprodutibilidade e validação

- Script gerador: `scripts/51_analyze_gender_current_canonical.R`.
- CSV canônico: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`.
- MD5 do CSV canônico: `b10712af7af5223ff9217f9645813ddb`.
- Modificação do CSV canônico: `2026-07-19 00:04:46 -03`.
- R: `R version 4.4.2 (2024-10-31)`.
- genderBR: `1.4.0`.

**Tabela 7. Validações automáticas**

| Validação | Status |
| --- | --- |
| Duplicatas exatas do CSV tratadas sem alterar PIDs | PASS |
| PIDs únicos no CSV canônico | PASS |
| PIDs canônicos encontrados no manifest | PASS |
| Anos entre 2005 e 2025 | PASS |
| Artigos na base analítica | PASS |
| Metadados de autoria presentes na base | PASS |
| Primeiros autores classificados como feminino ou masculino | PASS |
| Probabilidades dentro do intervalo [0, 1] | PASS |

*Nota:* todos os artefatos derivados deste relatório são recriados pelo script acima.
