# Seleção A/B gpt-5.5 high vs xhigh

Gerado em: 2026-06-17 01:04:46 -0300

## Escopo

- Baseline xhigh: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`
- Manifesto completo: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv`
- Manifesto congelado A/B: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_full_corpus/batch_manifests/ab_gpt55_high_50.csv`
- N total selecionado: 50
- Validações: PIDs únicos, task packets existentes, hash `input_text_hash` idêntico entre baseline e manifesto, N=50 e quotas exatas.

A seleção usa apenas artigos já classificados no corpus principal por leitura integral. Os estratos são escolhidos sequencialmente na ordem de prioridade: método positivo/diagnóstico, screen de credibilidade, tough call, quantitativo Torreblanca sem método positivo, qualitativo ou não empírico. Um PID já escolhido em estrato prioritário não pode ser escolhido novamente. Como os critérios se sobrepõem fortemente, esta interpretação preserva as quotas alvo sem duplicar PIDs.

## Tabela 1. Distribuição por estrato selecionado

assigned_stratum | n | target_n
--- | --- | ---
positive_or_diagnostic_method | 5 | 5
credibility_screen | 10 | 10
tough_call | 15 | 15
quant_torreblanca_no_positive_method | 10 | 10
qualitative_or_non_empirical | 10 | 10

## Tabela 2. Tamanho do pool candidato bruto por critério

candidate_stratum | raw_candidate_pool_n
--- | ---
positive_or_diagnostic_method | 133
credibility_screen | 133
tough_call | 249
quant_torreblanca_no_positive_method | 232
qualitative_or_non_empirical | 315

## Sobreposição entre critérios

Houve sobreposição bruta entre critérios em 48 dos 50 PIDs selecionados. A coluna `assigned_stratum` mostra o estrato final depois da prioridade.

## Tabela 3. PIDs selecionados com sobreposição bruta

selection_order | pid | assigned_stratum | raw_candidate_strata
--- | --- | --- | ---
1 | S1981-38212020000100201 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen
2 | S2236-57102023000100205 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
3 | S2236-57102024000100204 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
4 | S1981-38212016000200206 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
5 | S1981-38212019000300203 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
6 | S1981-38212022000200207 | credibility_screen | positive_or_diagnostic_method; credibility_screen; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
7 | S1981-38212008000200074 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
8 | S1981-38212019000200202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; qualitative_or_non_empirical
9 | S2236-57102024000100406 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call
10 | S1981-38212014000200094 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
11 | S1981-38212017000200205 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
12 | S1981-38212019000100204 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
13 | S2236-57102025000101004 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
14 | S1981-38212021000200202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
15 | S1981-38212020000300202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
16 | S1981-38212017000200201 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
17 | S2236-57102024000100405 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
18 | S1981-38212012000200002 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
19 | S1981-38212023000200202 | tough_call | tough_call; qualitative_or_non_empirical
20 | S1981-38212022000100204 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
21 | S2236-57102025000100207 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
22 | S1981-38212014000300098 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
23 | S2236-57102025000100204 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
24 | S1981-38212022000300201 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
25 | S1981-38212023000300201 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
26 | S2236-57102025000100800 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
27 | S2236-57102023000100408 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
28 | S2236-57102025000101406 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
29 | S2236-57102025000101701 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
30 | S1981-38212017000100203 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
31 | S1981-38212020000300201 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
32 | S1981-38212011000100054 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
33 | S2236-57102025000101607 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
34 | S2236-57102023000100209 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
35 | S1981-38212017000100204 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
36 | S1981-38212024000100201 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method
37 | S2236-57102023000100404 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
38 | S1981-38212020000200202 | quant_torreblanca_no_positive_method | quant_torreblanca_no_positive_method; qualitative_or_non_empirical
39 | S1981-38212009000200030 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
40 | S2236-57102023000100206 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
41 | S1981-38212018000200203 | qualitative_or_non_empirical | tough_call; qualitative_or_non_empirical
42 | S2236-57102023000100410 | qualitative_or_non_empirical | quant_torreblanca_no_positive_method; qualitative_or_non_empirical
43 | S1981-38212015000300042 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
46 | S1981-38212019000300202 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
47 | S1981-38212025000200203 | qualitative_or_non_empirical | tough_call; qualitative_or_non_empirical
48 | S2236-57102023000100217 | qualitative_or_non_empirical | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
49 | S1981-38212015000100039 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical
50 | S1981-38212013000200004 | qualitative_or_non_empirical | quant_torreblanca_no_positive_method; qualitative_or_non_empirical

## Tabela 4. PIDs selecionados

selection_order | pid | assigned_stratum | raw_candidate_strata | title | journal_title | year
--- | --- | --- | --- | --- | --- | ---
1 | S1981-38212020000100201 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen | How 'Democratic' is the Democratic Peace? A Survey Experiment of Foreign Policy Preferences in Brazil and China | Brazilian Political Science Review | 2020
2 | S2236-57102023000100205 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | A AGENDA DE PESQUISA DA BUROCRACIA DE NÍVEL DE RUA NO CONTEXTO DA PANDEMIA: UMA REVISÃO INTEGRATIVA | Cadernos Gestão Pública e Cidadania | 2023
3 | S2236-57102024000100204 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | FATORES FISCAIS E SOCIOECONÔMICOS QUE AFETAM A CRIMINALIDADE NO BRASIL | Cadernos Gestão Pública e Cidadania | 2024
4 | S1981-38212016000200206 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Unboxing the Active Role of the Legislative Power in Brazil | Brazilian Political Science Review | 2016
5 | S1981-38212019000300203 | positive_or_diagnostic_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Race and Competitiveness in Brazilian Elections: Evaluating the Chances of Black and Brown Candidates through Quantile Regression Analysis of Brazil's 2014 Congressional Elections | Brazilian Political Science Review | 2019
6 | S1981-38212022000200207 | credibility_screen | positive_or_diagnostic_method; credibility_screen; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | -State Presence in Brazilian Social Assistance Services: Effects on the Creation of Nonprofit Private Providers | Brazilian Political Science Review | 2022
7 | S1981-38212008000200074 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Policy Positions in the Chilean Senate: An Analysis of Coauthorship and Roll Call Data | Brazilian Political Science Review | 2008
8 | S1981-38212019000200202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; qualitative_or_non_empirical | Migrant Remittances and Rights to Physical Integrity: A Cross-section Study of Latin America (1981-2014) | Brazilian Political Science Review | 2019
9 | S2236-57102024000100406 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call | DESIGUALDADES DE GÊNERO E COR/RAÇA ENTRE OS DIRIGENTES MUNICIPAIS E ESTADUAIS NO BRASIL (2010 e 2019) | Cadernos Gestão Pública e Cidadania | 2024
10 | S1981-38212014000200094 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | A Comparative Analysis of Brazil's Foreign Policy Drivers Towards the USA: Comment on Amorim Neto (2011) | Brazilian Political Science Review | 2014
11 | S1981-38212017000200205 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Accountability, Corruption and Local Government: Mapping the Control Steps | Brazilian Political Science Review | 2017
12 | S1981-38212019000100204 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Capital Mobility, Veto Players, and Redistribution in Latin America During the Left Turn | Brazilian Political Science Review | 2019
13 | S2236-57102025000101004 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | TRANSPARÊNCIA ATIVA, DADOS ABERTOS E DESEMPENHO ACADÊMICO: ANÁLISE DAS UNIVERSIDADES FEDERAIS BRASILEIRAS | Cadernos Gestão Pública e Cidadania | 2025
14 | S1981-38212021000200202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Left-Wing Governmental Alliance in Portugal, 2015-2019: A Way of Renewing and Rejuvenating Social Democracy? | Brazilian Political Science Review | 2021
15 | S1981-38212020000300202 | credibility_screen | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Political Science in Latin America: A Scientometric Analysis | Brazilian Political Science Review | 2020
16 | S1981-38212017000200201 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Leaders or Loners? How Do the BRICS Countries and their Regions Vote in the UN General Assembly | Brazilian Political Science Review | 2017
17 | S2236-57102024000100405 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | TRANSPARÊNCIA SOBRE DIRIGENTES PÚBLICOS ESTADUAIS: UMA ANÁLISE EXPLORATÓRIA | Cadernos Gestão Pública e Cidadania | 2024
18 | S1981-38212012000200002 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | The Bigger, the Better: Coalitions in the GATT/WTO | Brazilian Political Science Review | 2012
19 | S1981-38212023000200202 | tough_call | tough_call; qualitative_or_non_empirical | Pierre Rosanvallon, from the Critique of Utopian Liberalism to the Critique of the Critique of Neoliberalism | Brazilian Political Science Review | 2023
20 | S1981-38212022000100204 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Policy Dynamics and Government Attention over Welfare Policies: An Analysis of the Brazilian Case | Brazilian Political Science Review | 2022
21 | S2236-57102025000100207 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | CUSTOS NO SETOR PÚBLICO: O CUSTO DO ABSENTEÍSMO NAS UNIDADES BÁSICAS DE SAÚDE | Cadernos Gestão Pública e Cidadania | 2025
22 | S1981-38212014000300098 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Beyond Brazilian Coalition Presidentialism: the Appropriation of the Legislative Agenda | Brazilian Political Science Review | 2014
23 | S2236-57102025000100204 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | ADMINISTRAÇÃO PÚBLICA 4.0 E OS CONCURSOS PARA CARREIRAS DA ÁREA ECONÔMICA DO PODER EXECUTIVO FEDERAL | Cadernos Gestão Pública e Cidadania | 2025
24 | S1981-38212022000300201 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | The Relationship between Ideology and COVID-19 Deaths: What We Know and What We Still Need to Know | Brazilian Political Science Review | 2022
25 | S1981-38212023000300201 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | PLANB Index : Sociological Categories for Climate Policymakers , | Brazilian Political Science Review | 2023
26 | S2236-57102025000100800 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | BOA GOVERNANÇA, MODELOS DE GESTÃO E INGRESSO NO SERVIÇO PÚBLICO BRASILEIRO: ENTRE DISCURSOS E PRÁTICAS | Cadernos Gestão Pública e Cidadania | 2025
27 | S2236-57102023000100408 | tough_call | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | A TRAJETÓRIA INSTITUCIONAL DO PROGRAMA NACIONAL DE FORMAÇÃO EM ADMINISTRAÇÃO PÚBLICA NA UNIVERSIDADE FEDERAL DE OURO PRETO | Cadernos Gestão Pública e Cidadania | 2023
28 | S2236-57102025000101406 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | AVALIAÇÃO DA APLICABILIDADE DA POLÍTICA NACIONAL DE RESÍDUOS SÓLIDOS EM PORTO VELHO | Cadernos Gestão Pública e Cidadania | 2025
29 | S2236-57102025000101701 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | PANORAMA DOS ESTUDOS SOBRE A RESILIÊNCIA FINANCEIRA APLICADA À GESTÃO DE RECURSOS PÚBLICOS NOS GOVERNOS LOCAIS | Cadernos Gestão Pública e Cidadania | 2025
30 | S1981-38212017000100203 | tough_call | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Germany and Greece in the Eurozone Crisis from the Viewpoint of the Neo-Neo Debate | Brazilian Political Science Review | 2017
31 | S1981-38212020000300201 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Individual Conditioning Factors of Political Protest in Latin America: Effects of Values, Grievance and Resources | Brazilian Political Science Review | 2020
32 | S1981-38212011000100054 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Brazilian Parties According to their Manifestos: Political Identity and Programmatic Emphases | Brazilian Political Science Review | 2011
33 | S2236-57102025000101607 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | ¿LA PROTESTA, SIN LA CALLE? LOS FORMATOS DE PROTESTA Y LA RELACIÓN CON LAS RESTRICCIONES A LA CIRCULACIÓN EN ARGENTINA (2020) | Cadernos Gestão Pública e Cidadania | 2025
34 | S2236-57102023000100209 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Percepções de gestores sobre parcerias entre negócios sociais e setor público no Brasil | Cadernos Gestão Pública e Cidadania | 2023
35 | S1981-38212017000100204 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Business, Government and Foreign Policy: Brazilian Construction Firms Abroad | Brazilian Political Science Review | 2017
36 | S1981-38212024000100201 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method | Political Support for Sale: Cabinet Appointments and Public Expenditures in Brazil | Brazilian Political Science Review | 2024
37 | S2236-57102023000100404 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | O ENSINO DE ADMINISTRAÇÃO PÚBLICA: ELEMENTOS PRELIMINARES DE UMA HISTÓRIA INTELECTUAL INTERDISCIPLINAR | Cadernos Gestão Pública e Cidadania | 2023
38 | S1981-38212020000200202 | quant_torreblanca_no_positive_method | quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Is Brazil a Geoeconomic Node? Geography, Public Policy, and the Failure of Economic Integration in South America | Brazilian Political Science Review | 2020
39 | S1981-38212009000200030 | quant_torreblanca_no_positive_method | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Strong Presidents, Robust Democracies? Separation of Powers and Rule of Law in Latin America | Brazilian Political Science Review | 2009
40 | S2236-57102023000100206 | quant_torreblanca_no_positive_method | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Mapeando a pesquisa de desenho de políticas públicas: uma revisão sistemática da literatura | Cadernos Gestão Pública e Cidadania | 2023
41 | S1981-38212018000200203 | qualitative_or_non_empirical | tough_call; qualitative_or_non_empirical | Freedom through form: Bolívar Lamounier and the Liberal Interpretation of Brazilian Political Thought* | Brazilian Political Science Review | 2018
42 | S2236-57102023000100410 | qualitative_or_non_empirical | quant_torreblanca_no_positive_method; qualitative_or_non_empirical | TCC EM GESTÃO PÚBLICA: PROFISSIONALIZAÇÃO E INOVAÇÃO | Cadernos Gestão Pública e Cidadania | 2023
43 | S1981-38212015000300042 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | The Capital Mistake: Local Information and National Electoral Reforms | Brazilian Political Science Review | 2015
44 | S1981-38212017000200401 | qualitative_or_non_empirical | qualitative_or_non_empirical | What are 'Think Tanks'? Revisiting the Dilemma of the Definition | Brazilian Political Science Review | 2017
45 | S2236-57102023000100211 | qualitative_or_non_empirical | qualitative_or_non_empirical | O Fantasma na Máquina: System-Level Bureaucracy e Coordenação Interorganizacional em Políticas Públicas | Cadernos Gestão Pública e Cidadania | 2023
46 | S1981-38212019000300202 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | Parliamentary Supervision of Brazilian Foreign Policy: An analysis of Approval of Authorities | Brazilian Political Science Review | 2019
47 | S1981-38212025000200203 | qualitative_or_non_empirical | tough_call; qualitative_or_non_empirical | Machiavelli against Imperialism: a Critique of Roman Expansionism and a Call for a Confederative Solution | Brazilian Political Science Review | 2025
48 | S2236-57102023000100217 | qualitative_or_non_empirical | tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | PARTES INTERESSADAS INTERNAS E DESEMPENHO EM CONTRATAÇÕES PÚBLICAS NA PERSPECTIVA DAS TEORIAS DOS STAKEHOLDERS E DOS CUSTOS DE TRANSAÇÃO | Cadernos Gestão Pública e Cidadania | 2023
49 | S1981-38212015000100039 | qualitative_or_non_empirical | positive_or_diagnostic_method; credibility_screen; tough_call; quant_torreblanca_no_positive_method; qualitative_or_non_empirical | The Institutional Presidency from a Comparative Perspective: Argentina and Brazil since the 1980s | Brazilian Political Science Review | 2015
50 | S1981-38212013000200004 | qualitative_or_non_empirical | quant_torreblanca_no_positive_method; qualitative_or_non_empirical | The judicialization of territorial politics in Brazil, Colombia and Spain | Brazilian Political Science Review | 2013

## Reprodutibilidade

A ordenação dentro de cada estrato é determinística: SHA-256 de `pid`, estrato e a semente textual `ab_gpt55_high_20260616`. Não há sorteio dependente de estado global do R.

Comando de reprodução:

`LC_ALL=pt_BR.UTF-8 Rscript --vanilla scripts/34_select_credibility_prompt_v3_ab_sample.R`
