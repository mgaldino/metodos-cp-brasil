# Benchmark de modelos GPT-5.6 para classifica<c3><a7><c3><a3>o integral

Gerado em: 2026-07-10 17:36:01 -0300

## Escopo e regra de decis<c3><a3>o

- Manifesto congelado: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_full_corpus/batch_manifests/ab_gpt56_models_10.csv`
- Baseline de consist<c3><aa>ncia: GPT-5.5 xhigh j<c3><a1> classificado.
- Benchmark hist<c3><b3>rico incorporado: GPT-5.5 high nos mesmos PIDs.
- Novos bra<c3><a7>os: GPT-5.6 Sol medium, Terra medium e Terra xhigh.
- Velocidade solicitada: standard/default em todos os bra<c3><a7>os; o `codex exec` n<c3><a3>o exp<c3><b5>e a velocidade efetiva.
- Execu<c3><a7><c3><a3>o sequencial com rota<c3><a7><c3><a3>o da ordem dos bra<c3><a7>os por PID.
- Regra lexicogr<c3><a1>fica: completude e logs v<c3><a1>lidos; menos desacordos screen/m<c3><a9>todo; maior concord<c3><a2>ncia m<c3><a9>dia; menor tempo total.
- Piso hist<c3><b3>rico: um bra<c3><a7>o novo n<c3><a3>o pode ter mais desacordos cr<c3><ad>ticos nem menor concord<c3><a2>ncia m<c3><a9>dia que o GPT-5.5 high nos mesmos 10 casos.
- O tempo de parede inclui filas, suspens<c3><b5>es e tentativas falhas; ele mede a lat<c3><aa>ncia fim a fim usada na decis<c3><a3>o. O tempo ativo do processo tamb<c3><a9>m <c3><a9> reportado separadamente.
- A concord<c3><a2>ncia com o baseline mede continuidade classificat<c3><b3>ria, n<c3><a3>o verdade substantiva.

## Tabela 1. Resultado geral por configura<c3><a7><c3><a3>o

configuracao | completos | faltantes | pids_com_algum_desacordo | pids_com_desacordo_screen_metodo | concordancia_media | tentativas | falhas_transitorias | tempo_total_parede_segundos | tempo_total_ativo_segundos | mediana_parede_por_artigo_segundos | mediana_ativa_por_artigo_segundos
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
GPT-5.5 high (histórico) | 10 | 0 | 10 | 7 | 75.8% |  |  |  |  |  | 
GPT-5.6 Sol medium | 10 | 0 | 7 | 4 | 87.5% | 16 | 6 | 1068.05426335335 | 1043.136712 | 82.4737000465393 | 78.685638
GPT-5.6 Terra medium | 10 | 0 | 8 | 4 | 81.7% | 15 | 5 | 9574.87014198303 | 1686.577922 | 62.0716094970703 | 62.0717125
GPT-5.6 Terra xhigh | 10 | 0 | 7 | 5 | 82.5% | 16 | 6 | 818.842032909393 | 818.845757 | 75.1457765102386 | 75.146966

## Tabela 2. Velocidade observada nos novos bra<c3><a7>os

configuracao | modelo | esforco | tentativas | falhas | tempo_total_parede_segundos | tempo_total_ativo_segundos | mediana_parede_segundos | mediana_ativa_segundos | media_parede_segundos | media_ativa_segundos
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
sol_medium | gpt-5.6-sol | medium | 16 | 6 | 1068.1 | 1043.1 | 82.5 | 78.7 | 103.3 | 100.8
terra_medium | gpt-5.6-terra | medium | 15 | 5 | 9574.9 | 1686.6 | 62.1 | 62.1 | 952 | 163.2
terra_xhigh | gpt-5.6-terra | xhigh | 16 | 6 | 818.8 | 818.8 | 75.1 | 75.1 | 76.7 | 76.7

## Tabela 3. Concord<c3><a2>ncia por campo priorit<c3><a1>rio

configuracao | campo | n_comparado | discordancias | concordancia
--- | --- | --- | --- | ---
GPT-5.5 high (histórico) | is_empirical_paper | 10 | 2 | 80.0%
GPT-5.5 high (histórico) | empirical_evidence_type | 10 | 4 | 60.0%
GPT-5.5 high (histórico) | is_empirical_quant_paper_torreblanca | 10 | 0 | 100.0%
GPT-5.5 high (histórico) | is_empirical_qual_paper | 10 | 4 | 60.0%
GPT-5.5 high (histórico) | quantitative_analysis_type | 10 | 0 | 100.0%
GPT-5.5 high (histórico) | has_statistical_inference | 10 | 0 | 100.0%
GPT-5.5 high (histórico) | causal_or_explanatory_claim_present | 10 | 2 | 80.0%
GPT-5.5 high (histórico) | credibility_revolution_screen_applicable | 10 | 3 | 70.0%
GPT-5.5 high (histórico) | credibility_revolution_screen_reason | 10 | 5 | 50.0%
GPT-5.5 high (histórico) | credibility_revolution_method_present | 10 | 3 | 70.0%
GPT-5.5 high (histórico) | credibility_revolution_method_type | 10 | 5 | 50.0%
GPT-5.5 high (histórico) | tough_call | 10 | 1 | 90.0%
GPT-5.6 Sol medium | is_empirical_paper | 10 | 0 | 100.0%
GPT-5.6 Sol medium | empirical_evidence_type | 10 | 2 | 80.0%
GPT-5.6 Sol medium | is_empirical_quant_paper_torreblanca | 10 | 0 | 100.0%
GPT-5.6 Sol medium | is_empirical_qual_paper | 10 | 2 | 80.0%
GPT-5.6 Sol medium | quantitative_analysis_type | 10 | 0 | 100.0%
GPT-5.6 Sol medium | has_statistical_inference | 10 | 0 | 100.0%
GPT-5.6 Sol medium | causal_or_explanatory_claim_present | 10 | 0 | 100.0%
GPT-5.6 Sol medium | credibility_revolution_screen_applicable | 10 | 1 | 90.0%
GPT-5.6 Sol medium | credibility_revolution_screen_reason | 10 | 1 | 90.0%
GPT-5.6 Sol medium | credibility_revolution_method_present | 10 | 1 | 90.0%
GPT-5.6 Sol medium | credibility_revolution_method_type | 10 | 4 | 60.0%
GPT-5.6 Sol medium | tough_call | 10 | 4 | 60.0%
GPT-5.6 Terra medium | is_empirical_paper | 10 | 1 | 90.0%
GPT-5.6 Terra medium | empirical_evidence_type | 10 | 3 | 70.0%
GPT-5.6 Terra medium | is_empirical_quant_paper_torreblanca | 10 | 0 | 100.0%
GPT-5.6 Terra medium | is_empirical_qual_paper | 10 | 3 | 70.0%
GPT-5.6 Terra medium | quantitative_analysis_type | 10 | 0 | 100.0%
GPT-5.6 Terra medium | has_statistical_inference | 10 | 0 | 100.0%
GPT-5.6 Terra medium | causal_or_explanatory_claim_present | 10 | 4 | 60.0%
GPT-5.6 Terra medium | credibility_revolution_screen_applicable | 10 | 1 | 90.0%
GPT-5.6 Terra medium | credibility_revolution_screen_reason | 10 | 2 | 80.0%
GPT-5.6 Terra medium | credibility_revolution_method_present | 10 | 1 | 90.0%
GPT-5.6 Terra medium | credibility_revolution_method_type | 10 | 3 | 70.0%
GPT-5.6 Terra medium | tough_call | 10 | 4 | 60.0%
GPT-5.6 Terra xhigh | is_empirical_paper | 10 | 0 | 100.0%
GPT-5.6 Terra xhigh | empirical_evidence_type | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | is_empirical_quant_paper_torreblanca | 10 | 0 | 100.0%
GPT-5.6 Terra xhigh | is_empirical_qual_paper | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | quantitative_analysis_type | 10 | 0 | 100.0%
GPT-5.6 Terra xhigh | has_statistical_inference | 10 | 0 | 100.0%
GPT-5.6 Terra xhigh | causal_or_explanatory_claim_present | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | credibility_revolution_screen_applicable | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | credibility_revolution_screen_reason | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | credibility_revolution_method_present | 10 | 2 | 80.0%
GPT-5.6 Terra xhigh | credibility_revolution_method_type | 10 | 5 | 50.0%
GPT-5.6 Terra xhigh | tough_call | 10 | 4 | 60.0%

## Tabela 4. PIDs e campos divergentes do baseline GPT-5.5 xhigh

configuracao | pid | titulo | campos_divergentes | divergencia_screen_metodo
--- | --- | --- | --- | ---
GPT-5.5 high (histórico) | S1981-38212017000100203 | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.5 high (histórico) | S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.5 high (histórico) | S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | credibility_revolution_method_type | TRUE
GPT-5.5 high (histórico) | S1981-38212023000200202 | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | TRUE
GPT-5.5 high (histórico) | S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE
GPT-5.5 high (histórico) | S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | TRUE
GPT-5.5 high (histórico) | S2236-57102025000100204 | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.6 Sol medium | S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | empirical_evidence_type; is_empirical_qual_paper; credibility_revolution_method_type | TRUE
GPT-5.6 Sol medium | S1981-38212017000100203 | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type; tough_call | TRUE
GPT-5.6 Sol medium | S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | credibility_revolution_method_type | TRUE
GPT-5.6 Sol medium | S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE
GPT-5.6 Terra medium | S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type; tough_call | TRUE
GPT-5.6 Terra medium | S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | causal_or_explanatory_claim_present; credibility_revolution_method_type | TRUE
GPT-5.6 Terra medium | S1981-38212023000200202 | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason; tough_call | TRUE
GPT-5.6 Terra medium | S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE
GPT-5.6 Terra xhigh | S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | empirical_evidence_type; is_empirical_qual_paper; credibility_revolution_method_type; tough_call | TRUE
GPT-5.6 Terra xhigh | S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type; tough_call | TRUE
GPT-5.6 Terra xhigh | S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | causal_or_explanatory_claim_present; credibility_revolution_method_type | TRUE
GPT-5.6 Terra xhigh | S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE
GPT-5.6 Terra xhigh | S2236-57102025000100204 | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.5 high (histórico) | S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | tough_call | FALSE
GPT-5.5 high (histórico) | S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | empirical_evidence_type; is_empirical_qual_paper | FALSE
GPT-5.5 high (histórico) | S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | empirical_evidence_type; is_empirical_qual_paper | FALSE
GPT-5.6 Sol medium | S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | tough_call | FALSE
GPT-5.6 Sol medium | S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | empirical_evidence_type; is_empirical_qual_paper; tough_call | FALSE
GPT-5.6 Sol medium | S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | tough_call | FALSE
GPT-5.6 Terra medium | S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | causal_or_explanatory_claim_present; tough_call | FALSE
GPT-5.6 Terra medium | S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | empirical_evidence_type; is_empirical_qual_paper | FALSE
GPT-5.6 Terra medium | S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | empirical_evidence_type; is_empirical_qual_paper; tough_call | FALSE
GPT-5.6 Terra medium | S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | causal_or_explanatory_claim_present | FALSE
GPT-5.6 Terra xhigh | S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | causal_or_explanatory_claim_present; tough_call | FALSE
GPT-5.6 Terra xhigh | S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | empirical_evidence_type; is_empirical_qual_paper; tough_call | FALSE

## Tabela 5. Integridade dos reading logs

configuracao | status_do_log | n
--- | --- | ---
GPT-5.5 high (histórico) | válido | 10
GPT-5.5 xhigh (baseline) | válido | 10
GPT-5.6 Sol medium | válido | 10
GPT-5.6 Terra medium | válido | 10
GPT-5.6 Terra xhigh | válido | 10

## Recomenda<c3><a7><c3><a3>o

- Escolher GPT-5.6 Sol medium entre os bra<c3><a7>os testados: passou os gates e liderou a ordena<c3><a7><c3><a3>o lexicogr<c3><a1>fica por desacordos cr<c3><ad>ticos, concord<c3><a2>ncia geral e tempo.
- Esta <c3><a9> uma calibra<c3><a7><c3><a3>o direcionada a 10 casos dif<c3><ad>ceis; antes de trocar o modelo em todo o corpus, a configura<c3><a7><c3><a3>o vencedora deve permanecer sob auditoria amostral independente.
