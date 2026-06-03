# common_schema_v1

Voce classifica artigos de Ciencia Politica publicados em periodicos brasileiros. Leia o XML/texto integral indicado no manifest e devolva apenas um arquivo JSON valido por artigo, sem comentario fora do JSON.

Use o mesmo texto de entrada para todos os artigos: `source_file` do `pilot_manifest.csv`. Nao consulte as classificacoes gold em `data/processed/classifications_llm_main_analysis.csv`, `data/processed/classifications_final/`, `data/processed/classifications/` ou `data/processed/classifications_normalized/` para tomar decisoes substantivas. Esses arquivos sao usados apenas pelo orquestrador para avaliacao posterior.

## Envelope obrigatorio

Cada arquivo `data/processed/full_classification_pilot/<agent_id>/<pid>.json` deve ter exatamente esta estrutura:

```json
{
  "pid": "S0000-00000000000000000",
  "agent_id": "agent_a",
  "prompt_version": "agent_a_v1+common_schema_v1",
  "model": "codex_subagent_inherited",
  "run_timestamp": "2026-06-03T00:00:00Z",
  "input_text_hash": "sha256_do_source_file_no_manifest",
  "source_file": "data/processed/sample_xmls/S0000-00000000000000000.xml",
  "classification": {},
  "raw_response_path": null
}
```

`classification` deve conter exatamente os campos abaixo. Nao inclua campos extras dentro de `classification`.

## Schema final

1. `error_in_raw_text`: `"No Error"`, `"Missing/Corrupt"` ou `"Title/Text Mismatch"`.
2. `subfield`: `"Brazilian Politics"`, `"Comparative Politics"`, `"International Relations"`, `"Methodology and Formal Theory"`, `"Political Theory and Philosophy"`, `"Public Policy/Administration"` ou `"Other"`.
3. `is_empirical_quant_paper`: `true` se o artigo conduz analise propria de dados observacionais ou experimentais; `false` caso contrario.
4. `general_goal_of_analysis`: `"Describe"`, `"Predict"`, `"Explain"` ou `null`.
5. `single_country_study`: `"single_country"`, `"multiple_countries"` ou `null`.
6. `single_region`: `"single_region"`, `"multiple_region"` ou `null`.
7. `countries_of_focus`: nomes de paises separados por ponto e virgula, ou `null`.
8. `paper_uses_survey_data`: `"no_survey_data"`, `"runs_original_survey"` ou `"uses_public_available_survey"`.
9. `uses_original_dataset`: `"original_survey"`, `"field_experiment"`, `"field_study"`, `"structure_systematize"`, `"procure_original_data"`, `"other_original_data"`, `"not_original"` ou `null`.
10. `seeks_determinants`: `true`, `false` ou `null`.
11. `main_causal_research_design`: `"Field Experiment"`, `"Survey Experiment"`, `"Lab Experiment"`, `"Diff-in-Diff"`, `"Instrumental Variable"`, `"Regression Discontinuity Design"`, `"Regression Kink Design"`, `"Synthetic Control"`, `"Matching/Weighting/Balancing"`, `"Kitchen Sink Linear Model"`, `"Multiple Designs"`, `"Other"` ou `null`.
12. `other_research_design`: string curta se o desenho for `"Other"` ou `"Multiple Designs"`; caso contrario `null`.
13. `instrumental_variable_instrument`: nome conciso do instrumento se houver IV; caso contrario `null`.
14. `placebo_test`: `true`, `false` ou `null`.
15. `independent_variables`: array de objetos `{"variable_name": string, "variable_description": string}` ou `null`.
16. `dependent_variables`: array de objetos `{"variable_name": string, "variable_description": string}` ou `null`.
17. `main_variable_relationship`: array de objetos `{"iv_var_name": string, "dv_var_name": string, "relationship_type": "Positive|Negative|Non-Monotonic|Null|Unknown", "statistically_significant": boolean, "substantively_significant": boolean}` ou `null`.
18. `makes_explicit_causal_claim`: `true`, `false` ou `null`.
19. `makes_implicit_causal_claim`: `true`, `false` ou `null`.
20. `strong_non_causal_causal_qualification`: `true`, `false` ou `null`.
21. `sample_size`: inteiro nao negativo ou `null`. Nao chute.
22. `sample_size_quote`: citacao textual exata usada para definir `sample_size`, ou `null`.
23. `claims_any_statistically_significant_results`: `true`, `false` ou `null`.
24. `references_power_analysis`: `true`, `false` ou `null`.
25. `clearly_defined_explanatory_variable`: `true`, `false` ou `null`.
26. `clear_causal_quantity_of_interest`: `"ATE"`, `"ATT"`, `"ATC"`, `"LATE"`, `"CATE"`, `"ITT"`, `"FALSE"` ou `null`.
27. `specifies_estimate_equations`: `true`, `false` ou `null`.
28. `discusses_threats_to_causality`: `true`, `false` ou `null`.
29. `statement_of_identification_assumptions_quote`: citacao textual exata sobre suposicoes de identificacao, ou `null`.
30. `statement_of_identification_assumptions`: `true`, `false` ou `null`.
31. `effort_to_explore_mechanisms`: `"No Mention of Mechanisms/Channels"`, `"Mechanisms/Channels Mentioned But Not Explored"`, `"Mechanisms/Channels Mentioned With Substantial Exploration"` ou `null`.
32. `mentions_pre_registered_design_and_analysis_plan`: `true`, `false` ou `null`.
33. `evidence_type`: `"quantitative"`, `"qualitative"`, `"mixed"` ou `"theoretical-normative"`.
34. `method_status`: `"explicit"` ou `"essayistic"`.
35. `brief_justification`: 2-3 frases explicando a classificacao.

## Regras comuns de conservadorismo

- Nao infira metodo causal, variavel, amostra, estimando ou identificacao quando o texto nao declara ou demonstra claramente.
- Se o XML estiver sem corpo de artigo e contiver apenas metadados/resumo/referencias, use `error_in_raw_text = "Missing/Corrupt"` e classifique apenas o que for sustentado pelo material disponivel.
- Use `null` quando um campo nao se aplicar ou nao estiver claro.
- Use `method_status = "explicit"` apenas quando o artigo declare ou justifique claramente o procedimento metodologico.
- Use `evidence_type = "theoretical-normative"` para ensaio teorico, normativo, conceitual ou historia das ideias sem analise empirica propria.
