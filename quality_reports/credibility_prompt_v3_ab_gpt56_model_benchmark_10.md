# Benchmark de modelos GPT-5.6 para classificação integral

Gerado em: 2026-07-10 17:41:11 -0300

## Escopo e regra de decisão

- Manifesto congelado: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_full_corpus/batch_manifests/ab_gpt56_models_10.csv`
- Baseline de consistência: GPT-5.5 xhigh já classificado.
- Benchmark histórico incorporado: GPT-5.5 high nos mesmos PIDs.
- Novos braços: GPT-5.6 Sol medium, Terra medium e Terra xhigh.
- Velocidade solicitada: standard/default em todos os braços; o `codex exec` não expõe a velocidade efetiva.
- Execução sequencial com rotação da ordem dos braços por PID.
- Regra lexicográfica: completude e logs válidos; menos desacordos screen/método; maior concordância média; menor tempo total.
- Piso histórico: um braço novo não pode ter mais desacordos críticos nem menor concordância média que o GPT-5.5 high nos mesmos 10 casos.
- O tempo de parede inclui filas, suspensões e tentativas falhas; ele mede a latência fim a fim usada na decisão. O tempo ativo do processo também é reportado separadamente.
- A coluna de timings registra sucesso/falha e retorno, mas não categoriza a causa de cada falha; mensagens diagnósticas permanecem nos logs de execução.
- A concordância com o baseline mede continuidade classificatória, não verdade substantiva.

## Tabela 1. Resultado geral por configuração

configuracao | completos | faltantes | pids_com_algum_desacordo | pids_com_desacordo_screen_metodo | concordancia_media | tentativas | falhas_transitorias | tempo_total_parede_segundos | tempo_total_ativo_segundos | mediana_parede_por_artigo_segundos | mediana_ativa_por_artigo_segundos
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
GPT-5.5 high (historical) | 10 | 0 | 10 | 7 | 75.8% |  |  |  |  |  | 
GPT-5.6 Sol medium | 10 | 0 | 7 | 4 | 87.5% | 16 | 6 | 1068.05426335335 | 1043.136712 | 82.4737000465393 | 78.685638
GPT-5.6 Terra medium | 10 | 0 | 8 | 4 | 81.7% | 15 | 5 | 9574.87014198303 | 1686.577922 | 62.0716094970703 | 62.0717125
GPT-5.6 Terra xhigh | 10 | 0 | 7 | 5 | 82.5% | 16 | 6 | 818.842032909393 | 818.845757 | 75.1457765102386 | 75.146966

## Tabela 2. Velocidade observada nos novos braços

configuracao | modelo | esforco | tentativas | falhas | tempo_total_parede_segundos | tempo_total_ativo_segundos | mediana_parede_segundos | mediana_ativa_segundos | media_parede_segundos | media_ativa_segundos
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
sol_medium | gpt-5.6-sol | medium | 16 | 6 | 1068.1 | 1043.1 | 82.5 | 78.7 | 103.3 | 100.8
terra_medium | gpt-5.6-terra | medium | 15 | 5 | 9574.9 | 1686.6 | 62.1 | 62.1 | 952 | 163.2
terra_xhigh | gpt-5.6-terra | xhigh | 16 | 6 | 818.8 | 818.8 | 75.1 | 75.1 | 76.7 | 76.7

## Tabela 3. Concordância por campo prioritário

configuracao | campo | n_comparado | discordancias | concordancia
--- | --- | --- | --- | ---
GPT-5.5 high (historical) | is_empirical_paper | 10 | 2 | 80.0%
GPT-5.5 high (historical) | empirical_evidence_type | 10 | 4 | 60.0%
GPT-5.5 high (historical) | is_empirical_quant_paper_torreblanca | 10 | 0 | 100.0%
GPT-5.5 high (historical) | is_empirical_qual_paper | 10 | 4 | 60.0%
GPT-5.5 high (historical) | quantitative_analysis_type | 10 | 0 | 100.0%
GPT-5.5 high (historical) | has_statistical_inference | 10 | 0 | 100.0%
GPT-5.5 high (historical) | causal_or_explanatory_claim_present | 10 | 2 | 80.0%
GPT-5.5 high (historical) | credibility_revolution_screen_applicable | 10 | 3 | 70.0%
GPT-5.5 high (historical) | credibility_revolution_screen_reason | 10 | 5 | 50.0%
GPT-5.5 high (historical) | credibility_revolution_method_present | 10 | 3 | 70.0%
GPT-5.5 high (historical) | credibility_revolution_method_type | 10 | 5 | 50.0%
GPT-5.5 high (historical) | tough_call | 10 | 1 | 90.0%
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
GPT-5.5 high (historical) | S1981-38212017000100203 | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.5 high (historical) | S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
GPT-5.5 high (historical) | S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | credibility_revolution_method_type | TRUE
GPT-5.5 high (historical) | S1981-38212023000200202 | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | TRUE
GPT-5.5 high (historical) | S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE
GPT-5.5 high (historical) | S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | TRUE
GPT-5.5 high (historical) | S2236-57102025000100204 | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE
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
GPT-5.5 high (historical) | S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | tough_call | FALSE
GPT-5.5 high (historical) | S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | empirical_evidence_type; is_empirical_qual_paper | FALSE
GPT-5.5 high (historical) | S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | empirical_evidence_type; is_empirical_qual_paper | FALSE
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
GPT-5.5 high (historical) | válido | 10
GPT-5.5 xhigh (baseline) | válido | 10
GPT-5.6 Sol medium | válido | 10
GPT-5.6 Terra medium | válido | 10
GPT-5.6 Terra xhigh | válido | 10

## Recomendação

- Escolher GPT-5.6 Sol medium entre os braços testados: passou os gates e venceu a ordenação lexicográfica. O tempo só seria usado após os critérios de desacordos críticos e concordância geral.
- Esta é uma calibração direcionada a 10 casos difíceis; antes de trocar o modelo em todo o corpus, a configuração vencedora deve permanecer sob auditoria amostral independente.
