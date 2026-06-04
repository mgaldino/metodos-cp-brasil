# Classificação metodológica - prompt v3 - piloto 175

Gerado em: 2026-06-04T13:44:21Z

## Escopo

Foram classificados os 175 artigos do manifest `data/processed/full_classification_pilot_v2/pilot_manifest.csv`.

Foram reaproveitados 5 objetos v3 já classificados no teste de 10 papers: S0011-52582010000200002, S0011-52582018000200463, S0102-85292021000100199, S1981-38212015000100003, S1981-38212024000200201.

Os demais PIDs foram classificados por regras conservadoras de texto aplicadas ao `body_text` canônico em `data/processed/fulltext_gold/article_texts_gold.csv`. Não houve uso de API keys ou runners de API.

## Distribuições

### is_empirical_paper

| value | n |
| --- | --- |
| False | 67 |
| True | 108 |

### empirical_evidence_type

| value | n |
| --- | --- |
| mixed_empirical | 18 |
| none | 67 |
| qualitative_only | 56 |
| quantitative_only | 34 |

### quantitative_analysis_type

| value | n |
| --- | --- |
| bivariate_tests_or_correlations_only | 13 |
| descriptive_statistics_only | 17 |
| none | 123 |
| statistical_modeling | 22 |

### credibility_revolution_screen_applicable

| value | n |
| --- | --- |
| False | 140 |
| True | 35 |

## Artigos com método de revolução da credibilidade

| pid | title | credibility_revolution_method_type |
| --- | --- | --- |
| S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | ["other_modern_causal_method"] |

## Tough calls

| pid | title | tough_call_reason |
| --- | --- | --- |
| S0011-52582006000100002 | Fundamentos da economia, mercado financeiro e intenção de voto: as eleições presidenciais brasileiras de 1994, 1998 e 2002 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0011-52582015000200461 | Continuidade, Ruptura ou Reciclagem? Uma Análise do Programa Político do Banco Mundial após o Consenso de Washington | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0011-52582017000200395 | A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;: Análise dos Casos do Segundo Governo de Getúlio Vargas e do Primeiro Governo de Lula da Silva | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0011-52582024000400209 | Entre a Desinstitucionalização e a Resiliência: Participação Institucional no Governo Bolsonaro | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-73292009000100001 | La Argentina y el Plan Marshall: promesas y realidades | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-73292010000300011 | Parceria global emergente: Brasil e China | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-73292012000300007 | Dilema de escolha: a resposta chinesa à mudança climática | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-73292017000100203 | Brazilian Foreign Policy Towards Internet Governance | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-76122006000100004 | Articulação de políticas públicas a partir dos fóruns de competitividade setoriais: a experiência recente da cadeia produtiva têxtil e de confecções | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-76122014000600003 | Problema da falta de vagas em creches: matriz de loops e a priorização de causas de problemas complexos | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-76122015000300563 | A configuração institucional da política de esporte no Brasil: organização, evolução e dilemas | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-76122016000500745 | A auditoria de custos e preços: eficácia nos serviços contratantes de defesa na Espanha | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0034-76122017000500879 | Determinantes para o cumprimento de prazo e preço em obras da educação: uma análise nos municípios capixabas | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0101-33002011000300004 | Trabalhar para estudar: sobre a pertinência da noção de transição escola-trabalho no Brasil | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0101-33002014000100004 | Escassez de engenheiros no Brasil? uma proposta de sistematização do debate | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0102-64452014000200007 | Política na forma da lei: o espaço dos constitucionalistas no Brasil democrático | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-64452020000200099 | A DIVERSIDADE DE AGENTES E AGENDAS NA SOCIOLOGIA DA EDUCAÇÃO NO BRASIL | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-64452024000200304 | ENTRE A FÉ E A EXPRESSÃO POLÍTICA. ETNOGRAFIA DAS INTERAÇÕES ENTRE PASTORES E FIÉIS EVANGÉLICOS DURANTE AS ELEIÇÕES DE 2022 NO RIO DE JANEIRO | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-69092018000300507 | O OVO E A GALINHA. Estudo do enquadramento e da recepção da cobertura jornalística no pleito de 2014 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0102-69092019000300509 | EXISTEM PREFERÊNCIAS DE SEXO NO BRASIL? | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0102-69092021000100510 | TECENDO UM CIRCUITO COMERCIAL A PARTIR DA FEIRA DA MADRUGADA As agenciadoras da moda popular brasileira | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-69092024000100506 | Determinantes da equidade na implementação da Política Nacional de Assistência Social | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0102-69092025000100509 | Negligência ou Genocídio? A crise humanitária na Terra Indígena Yanomami no Brasil | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-85292005000100003 | O novo regionalismo econômico asiático | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-85292007000100001 | Multilateralismo, democracia e política externa no Brasil: contenciosos das patentes e do algodão na Organização Mundial do Comércio (OMC) | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-85292014000100008 | A institucionalização de blocos de integração: uma proposta de critérios de medição | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0102-85292016000100313 | Domestic coalitions in the FTAA negotiations: the Brazilian case | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0103-33522019000300077 | Fronteiras de Estados emergentes: migração, cidadania pós-nacional e trabalhadores latino-americanos no Brasil, | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0103-33522025000100208 | Lei Aldir Blanc: o impacto da pandemia na mudança institucional, | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782008000100018 | Desenvolvimento regional e descentralização político-administrativa: um estudo comparativo dos casos de Minas Gerais, Ceará e Santa Catarina | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782012000300006 | O tribunal de contas da união, controle horizontal de agências reguladoras e impacto sobre usuários dos serviços | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782013000300008 | Os determinantes dos resultados de soma positiva em Minas Gerais e no Rio Grande do Sul | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-44782015000200109 | Ciclos políticos, socioeconomia e a geografia eleitoral do estado da Bahia nas eleições de 2006 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-44782017000100051 | A arte do encontro: a paradiplomacia e a internacionalização das cidades criativas | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782019000200209 | Sociabilidad católica y práctica política en la organización juvenil del partido Propuesta Republicana (PRO) | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782020000100202 | Resiliência eleitoral dos presidentes latino-americanos após a crise de 2008 e o refluxo da onda rosa | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-44782023000100400 | Como se fomenta ou se barra reformas eleitorais? Uma revisão de escopo | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S0104-44782024000100204 | Polarização e ideologia: explorando a natureza contextual do compromisso democrático | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-62762014000300377 | A identificação de enquadramentos através da análise de correspondências: um modelo analítico aplicado à controvérsia das ações afirmativas raciais na imprensa | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-62762015000100132 | Confiança nas Forças Armadas brasileiras: uma análise empírica a partir dos dados da pesquisa SIPS - Defesa Nacional | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-62762020000100034 | Medo da violência e adesão ao autoritarismo no Brasil: proposta metodológica e resultados em 2017 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S0104-62762025000100220 | Determinantes da confiança na Polícia Nacional: o caso dos Carabineros chilenos, 2015-2020 | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S1981-38212007000100070 | Relevant Factors for the Voting Decision in the 2002 Presidential Election: An Analysis of the ESEB (Brazilian Electoral Study) Data | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S1981-38212010000100131 | Private Security and the State in Latin America: the Case of Mexico City | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |
| S1981-38212013000200003 | Perceptions on justice, the judiciary and democracy | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S1981-38212015000300021 | The Elusive New Middle Class in Brazil | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S1981-38212019000100200 | Mapping Ideological Preferences in Brazilian Elections, 1994-2018: A Municipal-Level Study | Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado. |
| S1981-38212024000200201 | The African Agenda of Evangelical Christians in Brazilian Foreign Policy: The Crisis of the Universal Church of the Kingdom of God in Angola | The article mentions contextual numbers and outside survey/census figures, but the body does not present original quantitative analysis; the empirical contribution is qualitative case-study evidence. |
| S2236-57102023000100213 | AVANÇOS TEÓRICOS DO CAMPO DE CONHECIMENTOS DA GESTÃO SOCIAL: UMA ANÁLISE INTEGRATIVA | O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo. |

## Diagnóstico contra consenso auxiliar v2

O consenso v2 foi usado apenas como diagnóstico de consistência, não como citação substantiva no output v3.

_Nenhum registro._

## Falsos positivos e falsos negativos prováveis

Risco principal de falso positivo: artigos qualitativos ou teórico-normativos que mencionam números, surveys ou estatísticas de outros estudos podem ser capturados por regras de texto. A regra conservadora rebaixa esses casos quando não há evidência de análise quantitativa própria.

Risco principal de falso negativo: artigos quantitativos descritivos com pouca explicitação metodológica podem ficar como qualitativos ou `none` se o body não usa vocabulário de dados, tabelas ou estatística. Os casos divergentes em relação ao consenso auxiliar v2 foram marcados como `tough_call` para revisão.

## Recomendação sobre o prompt

O prompt está pronto para a próxima rodada de validação humana, mas não para classificação totalmente automática sem auditoria. Para escala, recomendo manter uma fila de revisão para `tough_call == true`, especialmente divergências contra o consenso v2, regressões observacionais com linguagem causal e artigos qualitativos com números contextuais.
