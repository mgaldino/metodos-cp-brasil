Piloto v2 de classificação metodológica: diagnóstico e próximos passos
================
Codex
2026-06-03 22:10 -03

- [Síntese executiva](#síntese-executiva)
- [O que funcionou bem](#o-que-funcionou-bem)
- [O que não funcionou bem](#o-que-não-funcionou-bem)
- [Fidelidade textual](#fidelidade-textual)
- [Interpretação dos principais
  riscos](#interpretação-dos-principais-riscos)
- [Fila de adjudicação](#fila-de-adjudicação)
- [Comparação diagnóstica com a rodada
  anterior](#comparação-diagnóstica-com-a-rodada-anterior)
- [Próximos passos recomendados](#próximos-passos-recomendados)
- [Decisão sobre escala](#decisão-sobre-escala)
- [Arquivos consultados](#arquivos-consultados)

<style type="text/css">
body {
  font-size: 15px;
  line-height: 1.45;
}
table {
  font-size: 13px;
}
caption {
  font-weight: 700;
}
</style>

# Síntese executiva

**Recomendação:** não escalar a classificação para o corpus completo
ainda. O piloto v2 resolveu o problema central de insumo textual: os 175
artigos elegíveis foram classificados a partir do `body_text` canônico
de `data/processed/fulltext_gold/article_texts_gold.csv`, com hash por
PID, prompts versionados, preservação do piloto anterior e validação de
schema sem erros. Isso é um avanço real em reprodutibilidade.

O bloqueio agora não é infraestrutura. O bloqueio é validade substantiva
e fidelidade textual em campos críticos. Há desacordo alto entre agentes
nos campos causais e falhas residuais de suporte textual em campos
factuais como claim causal explícito, dataset original, uso de survey,
tamanho da amostra, citação do tamanho da amostra e relação IV-DV. A
escala deve esperar uma rodada de adjudicação manual e ajustes de
codebook/prompt nesses campos.

| Métrica                               | Valor   | Taxa   |
|:--------------------------------------|:--------|:-------|
| artigos elegíveis no manifest         | 175     | NA     |
| campos de classificação               | 35      | NA     |
| decisões artigo-campo A/B/C           | 6.125   | NA     |
| unanimidade A/B/C                     | 4.264   | 69,6%  |
| maioria 2 contra 1 A/B/C              | 976     | 15,9%  |
| adjudicação por desacordo A/B/C       | 885     | 14,4%  |
| adjudicação em campos críticos        | 570     | 40,7%  |
| adjudicação em campos não críticos    | 315     | 6,7%   |
| JSONs de classificação presentes      | 525/525 | 100,0% |
| JSONs de auditoria D presentes        | 525/525 | 100,0% |
| erros de schema A/B/C                 | 0       | NA     |
| warnings de schema A/B/C              | 0       | NA     |
| erros de schema D                     | 0       | NA     |
| warnings de schema D                  | 0       | NA     |
| campos factuais auditados por D       | 8.925   | NA     |
| campos factuais suportados pelo texto | 8.279   | 92,8%  |
| campos contraditos pelo texto         | 281     | 3,1%   |
| campos não encontrados no texto       | 365     | 4,1%   |
| falhas de severidade alta             | 168     | 1,9%   |
| PIDs com ao menos uma falha alta      | 50      | 28,6%  |
| itens na fila priorizada              | 1.031   | NA     |
| PIDs na fila priorizada               | 175     | 100,0% |
| itens com prioridade \>= 14           | 55      | NA     |
| PIDs com prioridade \>= 14            | 30      | 17,1%  |

Tabela 1. Snapshot estatístico do piloto v2.

# O que funcionou bem

1.  **Insumo textual correto.** A v2 usou o body integral canônico, não
    os XMLs sem `<body>` da rodada anterior. O manifest aponta para
    `article_texts_gold.csv`, coluna `body_text`, com `input_text_hash`
    por artigo.

2.  **Rastreabilidade e versionamento.** A infraestrutura v2 ficou
    separada em `data/processed/full_classification_pilot_v2/`,
    preservando o piloto v1. Os prompts foram versionados e os scripts
    v2 não quebraram os scripts v1.

3.  **Execução completa sem API.** Os três classificadores geraram 175
    JSONs cada, e o Agente D produziu 525 auditorias de fidelidade
    textual. Não há evidência, nos artefatos finais, de uso de runners
    de API.

4.  **Schema validado.** As validações finais reportam zero erros e zero
    warnings tanto para os classificadores A/B/C quanto para o
    checador D. Isso torna os outputs comparáveis e auditáveis.

5.  **O checador D agregou valor.** A auditoria de fidelidade localizou
    falhas específicas com campo, PID, agente, status, severidade e
    trecho de suporte quando aplicável. Isso transforma o problema de
    qualidade em uma fila de revisão concreta.

| Tipo          | Agente  | Esperado | Presente | Completo |
|:--------------|:--------|:---------|:---------|:---------|
| classificação | agent_a | 175      | 175      | TRUE     |
| classificação | agent_b | 175      | 175      | TRUE     |
| classificação | agent_c | 175      | 175      | TRUE     |
| fidelidade    | agent_a | 175      | 175      | TRUE     |
| fidelidade    | agent_b | 175      | 175      | TRUE     |
| fidelidade    | agent_c | 175      | 175      | TRUE     |

Tabela 2. Completude dos JSONs de classificação e auditoria.

# O que não funcionou bem

1.  **Consenso baixo nos campos causais.** Como a regra força
    adjudicação para desacordo em campos críticos, os campos centrais da
    pergunta do paper ainda não estão prontos para escala.
    `makes_implicit_causal_claim` teve adjudicação em 95,4% dos artigos,
    e `makes_explicit_causal_claim` em 89,7%.

2.  **O campo `brief_justification` não é adequado para consenso por
    igualdade literal.** Ele aparece com 100% de adjudicação porque é
    texto livre. Esse campo deve ser tratado como justificativa
    auxiliar, síntese textual ou evidência para revisão, não como campo
    de consenso automático por comparação exata.

3.  **Campos factuais ainda têm risco de invenção ou extrapolação.** A
    auditoria D marcou 281 campos como contraditos pelo texto e 365 como
    não encontrados no texto. As falhas de severidade alta somam 168
    eventos de campo-agente, concentradas em 50 PIDs.

4.  **Os agentes têm perfis diferentes, mas nenhum é suficiente
    sozinho.** O Agente C teve maior taxa agregada de suporte textual,
    mas também o maior número de falhas de severidade alta. O Agente B
    teve a menor taxa de suporte textual e o maior número de
    contradições. O Agente A foi o mais permissivo em sinais
    substantivos.

5.  **A fila de adjudicação ficou ampla.** Todos os 175 PIDs aparecem em
    algum item da fila priorizada. Isso não significa que todos os
    artigos estejam igualmente problemáticos, mas indica que a escala
    sem adjudicação herdaria desacordos e falhas conhecidas.

| Campo | Unanimidade | Itens para adjudicar | Adjudicação |
|:---|:---|:---|:---|
| makes_implicit_causal_claim | 4,6% | 167 | 95,4% |
| makes_explicit_causal_claim | 10,3% | 157 | 89,7% |
| effort_to_explore_mechanisms | 64,6% | 62 | 35,4% |
| evidence_type | 65,7% | 60 | 34,3% |
| method_status | 74,3% | 45 | 25,7% |
| main_causal_research_design | 84,6% | 27 | 15,4% |
| is_empirical_quant_paper | 85,1% | 26 | 14,9% |
| statement_of_identification_assumptions | 85,1% | 26 | 14,9% |

Tabela 3. Acordo A/B/C nos campos críticos.

| Campo | Campo crítico | Artigos | Unanimidade | Maioria | Itens para adjudicar | Adjudicação |
|:---|:---|:---|:---|:---|:---|:---|
| brief_justification | não | 175 | 0,0% | 0,0% | 175 | 100,0% |
| makes_implicit_causal_claim | sim | 175 | 4,6% | 0,0% | 167 | 95,4% |
| makes_explicit_causal_claim | sim | 175 | 10,3% | 0,0% | 157 | 89,7% |
| effort_to_explore_mechanisms | sim | 175 | 64,6% | 0,0% | 62 | 35,4% |
| evidence_type | sim | 175 | 65,7% | 0,0% | 60 | 34,3% |
| method_status | sim | 175 | 74,3% | 0,0% | 45 | 25,7% |
| main_causal_research_design | sim | 175 | 84,6% | 0,0% | 27 | 15,4% |
| is_empirical_quant_paper | sim | 175 | 85,1% | 0,0% | 26 | 14,9% |
| statement_of_identification_assumptions | sim | 175 | 85,1% | 0,0% | 26 | 14,9% |
| uses_original_dataset | não | 175 | 53,1% | 32,6% | 25 | 14,3% |
| dependent_variables | não | 175 | 63,4% | 24,0% | 22 | 12,6% |
| independent_variables | não | 175 | 64,6% | 22,9% | 22 | 12,6% |
| main_variable_relationship | não | 175 | 89,7% | 2,3% | 14 | 8,0% |
| sample_size_quote | não | 175 | 79,4% | 14,9% | 10 | 5,7% |
| seeks_determinants | não | 175 | 56,6% | 38,9% | 8 | 4,6% |

Tabela 4. Campos com maior taxa de adjudicação A/B/C.

# Fidelidade textual

A taxa agregada de suporte textual dos campos factuais auditados foi
alta, mas não alta o bastante para escalar sem revisão: 92,8% dos campos
auditados foram marcados como suportados. O problema substantivo está
concentrado nos campos que o paper mais precisa medir com precisão.

| Agente | Campos auditados | Campos suportados | Taxa de suporte | Contraditos | Não encontrados | Severidade alta | Severidade média |
|:---|:---|:---|:---|:---|:---|:---|:---|
| agent_c | 2975 | 2819 | 94,8% | 26 | 130 | 77 | 70 |
| agent_a | 2975 | 2746 | 92,3% | 105 | 124 | 39 | 162 |
| agent_b | 2975 | 2714 | 91,2% | 150 | 111 | 52 | 195 |

Tabela 5. Fidelidade textual por agente auditado.

| Agente  | Pass | Pass com warnings | Fail | Total |
|:--------|:-----|:------------------|:-----|:------|
| agent_a | 71   | 79                | 25   | 175   |
| agent_b | 23   | 120               | 32   | 175   |
| agent_c | 124  | 9                 | 42   | 175   |

Tabela 6. Status geral das auditorias de fidelidade por agente.

| Campo | Auditados | Suportados | Taxa de suporte | Contraditos | Não encontrados | Severidade alta | Severidade média |
|:---|:---|:---|:---|:---|:---|:---|:---|
| makes_explicit_causal_claim | 525 | 303 | 57,7% | 212 | 10 | 0 | 222 |
| uses_original_dataset | 525 | 408 | 77,7% | 36 | 81 | 0 | 117 |
| paper_uses_survey_data | 525 | 464 | 88,4% | 4 | 57 | 58 | 3 |
| sample_size_quote | 525 | 481 | 91,6% | 0 | 44 | 44 | 0 |
| sample_size | 525 | 486 | 92,6% | 0 | 39 | 39 | 0 |
| effort_to_explore_mechanisms | 525 | 489 | 93,1% | 27 | 9 | 0 | 9 |
| main_variable_relationship | 525 | 499 | 95,0% | 0 | 26 | 25 | 1 |
| makes_implicit_causal_claim | 525 | 501 | 95,4% | 0 | 24 | 0 | 0 |
| dependent_variables | 525 | 508 | 96,8% | 0 | 17 | 0 | 17 |
| main_causal_research_design | 525 | 508 | 96,8% | 0 | 17 | 0 | 17 |
| independent_variables | 525 | 510 | 97,1% | 0 | 15 | 0 | 15 |
| claims_any_statistically_significant_results | 525 | 511 | 97,3% | 0 | 14 | 0 | 14 |

Tabela 7. Campos factuais com maior risco de falta de suporte textual.

| Campo                      | Falhas altas |
|:---------------------------|:-------------|
| paper_uses_survey_data     | 58           |
| sample_size_quote          | 44           |
| sample_size                | 39           |
| main_variable_relationship | 25           |
| references_power_analysis  | 2            |

Tabela 8. Falhas de severidade alta por campo.

| Agente  | Falhas altas |
|:--------|:-------------|
| agent_c | 77           |
| agent_b | 52           |
| agent_a | 39           |

Tabela 9. Falhas de severidade alta por agente auditado.

# Interpretação dos principais riscos

**Claims causais.** O campo `makes_explicit_causal_claim` combina baixo
acordo entre agentes e baixa fidelidade textual. Esse é o principal
bloqueio metodológico, porque a tese sobre revolução da credibilidade
depende de distinguir linguagem causal vaga, associação descritiva e
identificação causal real.

**Survey e dataset original.** `paper_uses_survey_data` e
`uses_original_dataset` precisam de definições mais granulares. O piloto
confunde com facilidade uso de dados de survey secundários, surveys
originais dos autores, questionários aplicados em estudo de caso, bases
administrativas compiladas e datasets originais derivados de fontes
públicas.

**Amostra.** `sample_size` e `sample_size_quote` ainda falham quando o
texto contém números, mas não sustenta claramente a unidade amostral
classificada. A regra deve exigir unidade, escopo e trecho diretamente
vinculado ao valor.

**Relação IV-DV.** `main_variable_relationship`, `independent_variables`
e `dependent_variables` são vulneráveis a extrapolação quando o artigo
discute conceitos ou mecanismos sem estimar uma relação empírica clara.
Esses campos devem ser nulos quando não houver relação operacionalizada
no texto.

**Justificativas livres.** `brief_justification` deve continuar
existindo como trilha de auditoria, mas não deve entrar na regra de
consenso por igualdade literal.

# Fila de adjudicação

Há duas filas que devem ser distinguidas. A primeira é a fila por
desacordo A/B/C, que soma 885 decisões artigo-campo a adjudicar. A
segunda é a fila priorizada final, que acrescenta falhas de fidelidade
textual e chega a 1.031 itens. A triagem inicial deve atacar os 55 itens
com prioridade maior ou igual a 14, envolvendo 30 PIDs.

| Razão                                         | Itens | Parcela |
|:----------------------------------------------|:------|:--------|
| desacordo_entre_agentes                       | 636   | 61,7%   |
| desacordo_entre_agentes_e_falha_de_fidelidade | 249   | 24,2%   |
| falha_de_fidelidade_textual                   | 146   | 14,2%   |

Tabela 10. Razões dos itens na fila priorizada.

| Campo                       | Itens de prioridade alta |
|:----------------------------|:-------------------------|
| paper_uses_survey_data      | 17                       |
| sample_size_quote           | 11                       |
| main_variable_relationship  | 8                        |
| makes_explicit_causal_claim | 8                        |
| sample_size                 | 6                        |
| main_causal_research_design | 5                        |

Tabela 11. Campos nos itens de maior prioridade.

| PID | Título | Campo | Campo crítico | Consenso | Prioridade | Razão | Agentes com falha |
|:---|:---|:---|:---|:---|:---|:---|:---|
| S0104-62762012000200003 | Solidariedade e expressão jurídica: valores políticos de vereadores sobre direitos sociais | sample_size_quote | não | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S1981-38212009000100011 | Social Scientists and Public Administration in the Lula da Silva Government | sample_size_quote | não | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S1981-38212010000100131 | Private Security and the State in Latin America: the Case of Mexico City | sample_size_quote | não | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S0011-52582013000100006 | Os alunos do ensino médio e Sciences Po: entre a meritocracia e a percepção das desigualda | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092018000300507 | O OVO E A GALINHA. Estudo do enquadramento e da recepção da cobertura jornalística no plei | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092019000200505 | CLASSE SOCIAL E ALIMENTAÇÃO: PADRÕES DE CONSUMO ALIMENTAR NO BRASIL CONTEMPORÂNEO | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092019000300509 | EXISTEM PREFERÊNCIAS DE SEXO NO BRASIL? | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762007000200001 | Eleições e capital social: uma análise das eleições presidenciais no Brasil (2002-2006) | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762014000300523 | Encarte de dados: Opinião sobre questões de segurança pública e comportamento social | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762015000100132 | Confiança nas Forças Armadas brasileiras: uma análise empírica a partir dos dados da pesqu | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762016000200318 | Medindo o acesso à Justiça Cível no Brasil | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762020000100034 | Medo da violência e adesão ao autoritarismo no Brasil: proposta metodológica e resultados | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212009000100011 | Social Scientists and Public Administration in the Lula da Silva Government | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212013000200003 | Perceptions on justice, the judiciary and democracy | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212015000300021 | The Elusive New Middle Class in Brazil | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212019000100200 | Mapping Ideological Preferences in Brazilian Elections, 1994-2018: A Municipal-Level Study | paper_uses_survey_data | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da c | sample_size | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | sample_size | não | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |

Tabela 12. Primeiros itens da fila de adjudicação priorizada.

# Comparação diagnóstica com a rodada anterior

A comparação contra a classificação anterior é útil para diagnóstico de
mudança operacional, mas não deve ser interpretada como validação,
porque a rodada anterior foi feita sem body integral. Mesmo assim, as
divergências mostram onde a troca de insumo textual e o maior
conservadorismo mudaram mais os resultados.

| Campo | Campo crítico | Consensos v2 aceitos | Acordo com v1 |
|:---|:---|:---|:---|
| error_in_raw_text | não | 175 | 25,7% |
| mentions_pre_registered_design_and_analysis_plan | não | 175 | 37,7% |
| seeks_determinants | não | 167 | 56,3% |
| uses_original_dataset | não | 150 | 58,7% |
| references_power_analysis | não | 175 | 58,9% |
| specifies_estimate_equations | não | 172 | 62,2% |
| clearly_defined_explanatory_variable | não | 172 | 65,1% |
| general_goal_of_analysis | não | 172 | 65,1% |
| clear_causal_quantity_of_interest | não | 175 | 66,9% |
| claims_any_statistically_significant_results | não | 174 | 69,0% |
| discusses_threats_to_causality | não | 173 | 71,7% |
| makes_explicit_causal_claim | sim | 18 | 72,2% |
| single_region | não | 174 | 75,3% |
| statement_of_identification_assumptions | sim | 149 | 75,8% |
| strong_non_causal_causal_qualification | não | 171 | 77,2% |

Tabela 13. Menores taxas de acordo do consenso v2 com a rodada anterior.

| Agente  | Slots auditados | Sinais permissivos | Taxa permissiva |
|:--------|:----------------|:-------------------|:----------------|
| agent_a | 2975            | 378                | 12,7%           |
| agent_b | 2975            | 371                | 12,5%           |
| agent_c | 2975            | 311                | 10,5%           |

Tabela 14. Sinais de permissividade por agente.

# Próximos passos recomendados

1.  **Congelar o piloto v2 como baseline de calibração.** Não
    sobrescrever os JSONs A/B/C/D. Qualquer nova rodada deve ser `v3` ou
    um diretório de adjudicação derivado, por exemplo
    `data/processed/full_classification_pilot_v2/adjudicated/`.

2.  **Adjudicar manualmente a fila de maior prioridade.** Começar pelos
    55 itens com prioridade maior ou igual a 14, cobrindo 30 PIDs. Em
    paralelo, revisar todos os 168 eventos de severidade alta em 50
    PIDs, porque eles indicam risco concreto de afirmação não sustentada
    ou contradita pelo body.

3.  **Reescrever o codebook dos campos instáveis.** Prioridade:
    `makes_explicit_causal_claim`, `makes_implicit_causal_claim`,
    `main_causal_research_design`, `paper_uses_survey_data`,
    `uses_original_dataset`, `sample_size`, `sample_size_quote`,
    `main_variable_relationship`, `independent_variables` e
    `dependent_variables`.

4.  **Separar categorias que hoje estão colapsadas.** Para survey,
    distinguir `no_survey_data`, `secondary_survey_data`,
    `original_survey_by_authors` e
    `questionnaire_or_interview_in_case_study`. Para dataset original,
    distinguir dados primários, base compilada pelos autores a partir de
    fontes públicas e reuso de base externa.

5.  **Adicionar regras de nulidade explícitas.** Campos factuais devem
    receber `null` quando o body não contiver suporte direto. Isso deve
    valer especialmente para tamanho de amostra, variáveis, relação
    IV-DV, equações estimadas, significância estatística, power analysis
    e pré-registro.

6.  **Remover `brief_justification` do consenso por igualdade literal.**
    A melhor regra é preservar as três justificativas como evidência
    auxiliar, e gerar uma justificativa consensual apenas depois da
    adjudicação.

7.  **Criar uma planilha de adjudicação humana.** A planilha deve conter
    PID, título, campo, valores A/B/C, status do Agente D, trecho de
    suporte, motivo de prioridade e uma coluna para decisão final. Isso
    transforma a fila em trabalho manual rastreável.

8.  **Produzir um gold set adjudicado do piloto.** Depois da
    adjudicação, gerar `consensus_classifications_adjudicated.csv` e um
    relatório de mudanças em relação ao consenso provisório. Esse gold
    set deve virar benchmark para nova rodada de prompts.

9.  **Rodar uma v3 pequena antes da escala.** Reclassificar apenas os
    campos problemáticos nos PIDs adjudicados, com prompts revisados, e
    medir melhoria de acordo e fidelidade antes de tocar no corpus
    completo.

10. **Definir critérios objetivos de escala.** Sugestão mínima: zero
    erros de schema, zero falhas altas nos campos prioritários após
    adjudicação, taxa de suporte textual acima de 95% em cada campo
    factual central, e adjudicação abaixo de 10% nos campos críticos em
    uma amostra de validação pós-revisão.

# Decisão sobre escala

A escala para o corpus completo deve esperar. A infraestrutura v2 é
sólida o bastante para servir de base, mas os resultados substantivos
ainda exigem adjudicação e revisão de schema/prompt. Escalar agora
provavelmente propagaria erro justamente nos campos que sustentam a
inferência principal do paper: presença de claim causal, tipo de desenho
causal, identificação, variáveis, survey/dataset original e evidência
estatística.

O melhor caminho é tratar o piloto v2 como benchmark de calibração,
adjudicar os campos de maior risco, revisar o codebook e rodar uma v3
focalizada. Só depois disso faz sentido classificar o corpus completo.

# Arquivos consultados

- `data/processed/full_classification_pilot_v2/pilot_manifest.csv`
- `data/processed/full_classification_pilot_v2/pilot_manifest_metadata.json`
- `quality_reports/full_classification_pilot_v2_validation_summary.md`
- `quality_reports/full_classification_pilot_v2_fidelity_validation_summary.md`
- `quality_reports/full_classification_pilot_v2_final_report.md`
- `data/processed/full_classification_pilot_v2/comparison/agent_field_agreement.csv`
- `data/processed/full_classification_pilot_v2/comparison/adjudication_queue_prioritized.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_field_audits_validated.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_file_audits_validated.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_high_risk_fields.csv`
- `data/processed/full_classification_pilot_v2/comparison/previous_classification_agreement_consensus_by_field.csv`
