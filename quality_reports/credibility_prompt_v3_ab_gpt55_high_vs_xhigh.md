# A/B gpt-5.5 high vs xhigh: credibility_prompt_v3

Gerado em: 2026-06-17 01:04:52 -0300

## Escopo

- Manifesto congelado: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_full_corpus/batch_manifests/ab_gpt55_high_50.csv`
- Baseline xhigh: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`
- Tratamento high: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt55_high/combined/classifications_integral_reading_ab_gpt55_high_50.csv`
- CSV de desacordos: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt55_high/combined/ab_gpt55_high_disagreements.csv`
- N no manifesto: 50
- N baseline no manifesto: 50
- N tratamento high: 50
- N comparado: 50
- PIDs ausentes no baseline: 0
- PIDs ausentes no high: 0
- PIDs extras no high fora do manifesto: 0
- Validações: PIDs únicos em manifesto/baseline/high e `input_text_hash` idêntico entre manifesto, baseline e tratamento nos PIDs comparados.

## Tabela 1. Concordância por campo prioritário

field | n_compared | n_agree | n_disagree | agreement_rate | agreement_percent
--- | --- | --- | --- | --- | ---
empirical_evidence_type | 50 | 43 | 7 | 0.86 | 86.0%
is_empirical_qual_paper | 50 | 43 | 7 | 0.86 | 86.0%
tough_call | 50 | 43 | 7 | 0.86 | 86.0%
credibility_revolution_method_type | 50 | 45 | 5 | 0.9 | 90.0%
credibility_revolution_screen_reason | 50 | 45 | 5 | 0.9 | 90.0%
causal_or_explanatory_claim_present | 50 | 47 | 3 | 0.94 | 94.0%
credibility_revolution_method_present | 50 | 47 | 3 | 0.94 | 94.0%
credibility_revolution_screen_applicable | 50 | 47 | 3 | 0.94 | 94.0%
is_empirical_paper | 50 | 48 | 2 | 0.96 | 96.0%
has_statistical_inference | 50 | 49 | 1 | 0.98 | 98.0%
is_empirical_quant_paper_torreblanca | 50 | 50 | 0 | 1 | 100.0%
quantitative_analysis_type | 50 | 50 | 0 | 1 | 100.0%

## Tabela 2. PIDs com desacordo substantivo

pid | title | journal_title | fields_disagree
--- | --- | --- | ---
S2236-57102024000100204 | FATORES FISCAIS E SOCIOECONÔMICOS QUE AFETAM A CRIMINALIDADE NO BRASIL | Cadernos Gestão Pública e Cidadania | empirical_evidence_type; is_empirical_qual_paper
S1981-38212022000200207 | -State Presence in Brazilian Social Assistance Services: Effects on the Creation of Nonprofit Private Providers | Brazilian Political Science Review | tough_call
S1981-38212008000200074 | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | Brazilian Political Science Review | tough_call
S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | Brazilian Political Science Review | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type
S1981-38212023000200202 | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | Brazilian Political Science Review | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason
S2236-57102025000100207 | CUSTOS NO SETOR PÚBLICO: O CUSTO DO ABSENTEÍSMO NAS UNIDADES BÁSICAS DE SAÚDE | Cadernos Gestão Pública e Cidadania | tough_call
S1981-38212014000300098 | Beyond Brazilian Coalition Presidentialism: the Appropriation of the Legislative Agenda | Brazilian Political Science Review | has_statistical_inference
S2236-57102025000100204 | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | Cadernos Gestão Pública e Cidadania | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type
S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | Brazilian Political Science Review | credibility_revolution_method_type
S1981-38212017000100203 | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | Brazilian Political Science Review | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type
S1981-38212011000100054 | Brazilian Parties According to their Manifestos: Political Identity and Programmatic Emphases | Brazilian Political Science Review | tough_call
S2236-57102025000101607 | ¿LA PROTESTA, SIN LA CALLE? LOS FORMATOS DE PROTESTA Y LA RELACIÓN CON LAS RESTRICCIONES A LA CIRCULACIÓN EN ARGENTINA (2020) | Cadernos Gestão Pública e Cidadania | empirical_evidence_type; is_empirical_qual_paper
S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | Brazilian Political Science Review | credibility_revolution_method_type
S2236-57102023000100404 | O ENSINO DE ADMINISTRAÇÃO PÚBLICA: ELEMENTOS PRELIMINARES DE UMA HISTÓRIA INTELECTUAL INTERDISCIPLINAR | Cadernos Gestão Pública e Cidadania | empirical_evidence_type; is_empirical_qual_paper
S1981-38212018000200203 | Freedom through form: Bolívar Lamounier and the Liberal Interpretation of Brazilian Political Thought* | Brazilian Political Science Review | causal_or_explanatory_claim_present
S2236-57102023000100410 | TCC EM GESTÃO PÚBLICA: PROFISSIONALIZAÇÃO E INOVAÇÃO | Cadernos Gestão Pública e Cidadania | tough_call
S1981-38212015000300042 | The Capital Mistake: Local Information and National Electoral Reforms | Brazilian Political Science Review | empirical_evidence_type; is_empirical_qual_paper
S2236-57102023000100211 | O Fantasma na Máquina: System-Level Bureaucracy e Coordenação Interorganizacional em Políticas Públicas | Cadernos Gestão Pública e Cidadania | tough_call
S1981-38212019000300202 | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | Brazilian Political Science Review | empirical_evidence_type; is_empirical_qual_paper
S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | Brazilian Political Science Review | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason
S1981-38212015000100039 | The Institutional Presidency from a Comparative Perspective: Argentina and Brazil since the 1980s | Brazilian Political Science Review | tough_call

## Tabela 3. Desacordos em screen/method

pid | title | fields_disagree | credibility_revolution_screen_applicable_xhigh | credibility_revolution_screen_applicable_high | credibility_revolution_screen_reason_xhigh | credibility_revolution_screen_reason_high | credibility_revolution_method_present_xhigh | credibility_revolution_method_present_high | credibility_revolution_method_type_xhigh | credibility_revolution_method_type_high
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
S1981-38212021000200202 | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | TRUE | FALSE | causal_claim_with_quantitative_analysis_screen | descriptive_quantitative_only | FALSE | NA | none_detected | 
S1981-38212023000200202 | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | FALSE | FALSE | qualitative_only | not_empirical | NA | NA |  | 
S2236-57102025000100204 | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | FALSE | TRUE | descriptive_quantitative_only | causal_claim_with_quantitative_analysis_screen | NA | FALSE |  | none_detected
S1981-38212022000300201 | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | credibility_revolution_method_type | TRUE | TRUE | statistical_modeling_screen | statistical_modeling_screen | FALSE | FALSE | observational_regression_with_causal_claim_no_design | none_detected
S1981-38212017000100203 | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | FALSE | TRUE | descriptive_quantitative_only | causal_claim_with_quantitative_analysis_screen | NA | FALSE |  | none_detected
S1981-38212024000100201 | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | credibility_revolution_method_type | TRUE | TRUE | statistical_modeling_screen | statistical_modeling_screen | FALSE | FALSE | fixed_effects_causal_panel_claim; observational_regression_with_causal_claim_no_design | observational_regression_with_causal_claim_no_design
S1981-38212025000200203 | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | FALSE | FALSE | qualitative_only | not_empirical | NA | NA |  | 

## Tabela 4. Cobertura dos reading logs high em todos os PIDs

high_log_assessment | n
--- | ---
Sem sinal mecânico de superficialidade no reading log. | 50

## Tabela 5. Avaliação curta dos reading logs em casos divergentes

pid | fields_disagree | xhigh_status | high_status | xhigh_full_body_read | high_full_body_read | xhigh_n_sections | high_n_sections | xhigh_total_summary_chars | high_total_summary_chars | high_to_xhigh_section_ratio | high_to_xhigh_summary_ratio | high_first_sections | high_log_assessment
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
S2236-57102024000100204 | empirical_evidence_type; is_empirical_qual_paper | complete | complete | TRUE | TRUE | 12 | 12 | 7897 | 7519 | 1 | 0.952133721666456 | INTRODUÇÃO; REFERENCIAL TEÓRICO; Teoria do crime, fatores socioeconômicos e a violência urbana; Gastos públicos e criminalidade brasileira | Sem sinal mecânico de superficialidade no reading log.
S1981-38212022000200207 | tough_call | complete | complete | TRUE | TRUE | 9 | 9 | 7535 | 7780 | 1 | 1.03251493032515 | chunk_1; Hybrid systems and institutional change; First regulations and proliferation of PSAPs; From the 1988 Federal Constitution to the FHC administrations | Sem sinal mecânico de superficialidade no reading log.
S1981-38212008000200074 | tough_call | complete | complete | TRUE | TRUE | 5 | 5 | 4201 | 4268 | 1 | 1.01594858367055 | chunk_1; Shifting Attention to the Senate; Ideal Points from Recorded Roll Call Votes; Bill Coauthorship Links | Sem sinal mecânico de superficialidade no reading log.
S1981-38212021000200202 | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | complete | complete | TRUE | TRUE | 9 | 9 | 7651 | 7271 | 1 | 0.950333289766044 | chunk_1; Theory and ‘descriptive hypothesis’: the Great Recession as a stimulus for social democratic renewal and rejuvenation, and for increasing radical left influence; The Great Recession and ideological change within the radical left in Portugal; The radical left’s difficult road to co-operation with the PS | Sem sinal mecânico de superficialidade no reading log.
S1981-38212023000200202 | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | complete | complete | TRUE | TRUE | 5 | 5 | 4784 | 4383 | 1 | 0.916178929765886 | chunk_1; Classical economic liberalism as the germ of totalitarianism; Developments in Rosanvallon's interpretation of liberalism, in dialogue with Foucault; Rosanvallon and the question of neoliberalism: an alternative reading of Foucault | Sem sinal mecânico de superficialidade no reading log.
S2236-57102025000100207 | tough_call | complete | complete | TRUE | TRUE | 11 | 11 | 6838 | 5880 | 1 | 0.859900555718046 | INTRODUÇÃO; REFERENCIAL TEÓRICO; Contabilidade aplicada ao setor público; Custeio na administração pública | Sem sinal mecânico de superficialidade no reading log.
S1981-38212014000300098 | has_statistical_inference | complete | complete | TRUE | TRUE | 10 | 12 | 7504 | 9647 | 1.2 | 1.28558102345416 | chunk_1; Majority formation and agenda power; Analytical model for Appropriation; Appropriation categories | Sem sinal mecânico de superficialidade no reading log.
S2236-57102025000100204 | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | complete | complete | TRUE | TRUE | 6 | 11 | 4665 | 6945 | 1.83333333333333 | 1.4887459807074 | INTRODUÇÃO; ADMINISTRAÇÃO PÚBLICA 4.0; AS CARREIRAS ECONÔMICAS; METODOLOGIA | Sem sinal mecânico de superficialidade no reading log.
S1981-38212022000300201 | credibility_revolution_method_type | complete | complete | TRUE | TRUE | 9 | 9 | 7777 | 6887 | 1 | 0.885559984569886 | Introduction / opening section; What we already know: ecological inferences revisited; Ecological inferences at the individual-level; Ecological inferences at the aggregate level | Sem sinal mecânico de superficialidade no reading log.
S1981-38212017000100203 | credibility_revolution_screen_applicable; credibility_revolution_screen_reason; credibility_revolution_method_present; credibility_revolution_method_type | complete | complete | TRUE | TRUE | 12 | 12 | 8724 | 7117 | 1 | 0.815795506648326 | Introduction; Institutionalization in Europe; The neo-neo debate; Asymmetries between Germany and Greece and the crisis | Sem sinal mecânico de superficialidade no reading log.
S1981-38212011000100054 | tough_call | complete | complete | TRUE | TRUE | 15 | 15 | 10822 | 9113 | 1 | 0.842080946220662 | Introduction; The Theory of Competition by Emphasis; The Programmatic Emphases of Brazilian Parties; The content analysis method | Sem sinal mecânico de superficialidade no reading log.
S2236-57102025000101607 | empirical_evidence_type; is_empirical_qual_paper | complete | complete | TRUE | TRUE | 7 | 7 | 5471 | 5773 | 1 | 1.05520014622555 | INTRODUCCIÓN; Las dimensiones de la protesta; La protesta en el ASPO; Dimensión económica: A mayor crisis económica más calle | Sem sinal mecânico de superficialidade no reading log.
S1981-38212024000100201 | credibility_revolution_method_type | complete | complete | TRUE | TRUE | 7 | 7 | 6904 | 5658 | 1 | 0.819524913093859 | Introduction; The role played by pork barrel politics and cabinet appointments; A principal-agent theory about cabinet appointments and pork barrel in Brazil; Descriptive analysis | Sem sinal mecânico de superficialidade no reading log.
S2236-57102023000100404 | empirical_evidence_type; is_empirical_qual_paper | complete | complete | TRUE | TRUE | 5 | 5 | 2666 | 4547 | 1 | 1.70555138784696 | INTRODUÇÃO; UM CAMPO PARA O PÚBLICO: DISCIPLINAS, DICOTOMIAS E TRADIÇÕES INTELECTUAIS; A ESCOLA DE GOVERNO PROFESSOR PAULO NEVES DE CARVALHO E O ENSINO DA ADMINISTRAÇÃO PÚBLICA NO BRASIL; AS TRADIÇÕES INTELECTUAIS DOS TRABALHOS DE CONCLUSÃO DE CURSO DA ESCOLA DE GOVERNO PROFESSOR PAULO NEVES DE CARVALHO | Sem sinal mecânico de superficialidade no reading log.
S1981-38212018000200203 | causal_or_explanatory_claim_present | complete | complete | TRUE | TRUE | 7 | 7 | 5733 | 5445 | 1 | 0.949764521193093 | chunk_1; From conservative thought to authoritarian ideology: in search of theories and analytical models (1968-1974); State ideology and political representation: formalism as the cure for authoritarianism (1974-1981); Institutions versus culture: Ruy Barbosa as a precursor of Brazilian institutionalism (1991-1999) | Sem sinal mecânico de superficialidade no reading log.
S2236-57102023000100410 | tough_call | complete | complete | TRUE | TRUE | 5 | 5 | 4325 | 3797 | 1 | 0.877919075144509 | INTRODUÇÃO; O TRABALHO DE CONCLUSÃO DE CURSO, SEUS DIVERSOS TIPOS E POSSIBILIDADES DE CONTRIBUIÇÃO PARA A FORMAÇÃO TECNOLÓGICA DO ALUNO DE GESTÃO PÚBLICA; LEVANTAMENTO DE TCC-PRODUTOS ADOTADOS PELOS CURSOS SUPERIORES TECNOLÓGICOS EM GESTÃO PÚBLICA, NA MODALIDADE PRESENCIAL, NO BRASIL; AVALIAÇÃO COMO INDUTORA DE COMPORTAMENTO E RECONHECIMENTO SOCIAL DA PRODUÇÃO TECNOLÓGICA | Sem sinal mecânico de superficialidade no reading log.
S1981-38212015000300042 | empirical_evidence_type; is_empirical_qual_paper | complete | complete | TRUE | TRUE | 11 | 11 | 5479 | 7303 | 1 | 1.33290746486585 | chunk_1; Endogenous electoral rules; Electoral reforms: national decisions with local information; Assumptions | Sem sinal mecânico de superficialidade no reading log.
S2236-57102023000100211 | tough_call | complete | complete | TRUE | TRUE | 8 | 9 | 6232 | 6205 | 1.125 | 0.995667522464698 | chunk_1; Definindo a System-Level Bureaucracy; COORDENAÇÃO ENTRE BUROCRACIAS E ESTRATÉGIAS DE COPING; METODOLOGIA | Sem sinal mecânico de superficialidade no reading log.
S1981-38212019000300202 | empirical_evidence_type; is_empirical_qual_paper | complete | complete | TRUE | TRUE | 8 | 8 | 6824 | 6021 | 1 | 0.882327080890973 | Introduction; Brazilian foreign policy and the National Congress; Parliamentary supervision and approval of authorities; Senatorial deliberation on authorities | Sem sinal mecânico de superficialidade no reading log.
S1981-38212025000200203 | is_empirical_paper; empirical_evidence_type; is_empirical_qual_paper; causal_or_explanatory_claim_present; credibility_revolution_screen_reason | complete | complete | TRUE | TRUE | 5 | 5 | 4053 | 4253 | 1 | 1.0493461633358 | introductory unheaded section; Machiavelli the Imperialist; Empire and domination: the Roman model; The contradictions of Imperialism | Sem sinal mecânico de superficialidade no reading log.
S1981-38212015000100039 | tough_call | complete | complete | TRUE | TRUE | 6 | 6 | 5222 | 6144 | 1 | 1.17656070471084 | chunk_1; State of the Art; Data and Methodology; The Size of the Presidencies | Sem sinal mecânico de superficialidade no reading log.

## Recomendação

- Concordância média nos campos prioritários: 92.8%
- Menor concordância de campo: 86.0%
- PIDs com desacordo screen/method: 7
- PIDs com sinal mecânico de superficialidade no high: 0
- Recomendação: Manter xhigh como default; high ainda gera divergência substantiva demais para substituir.

A avaliação dos `section_reading_log` é uma checagem reprodutível de cobertura, não uma leitura substantiva humana. Ela marca superficialidade apenas quando o log high está ausente, incompleto, com hash divergente, ou muito mais curto que o xhigh.
