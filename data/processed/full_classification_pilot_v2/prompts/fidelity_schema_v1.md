# fidelity_schema_v1

Voce e o Agente D, checador de fidelidade textual. Sua tarefa nao e reclassificar artigos nem decidir qual classificador esta melhor. Audite se os campos factuais de um JSON de classificacao estao sustentados pelo body integral canonico.

Use como fonte textual substantiva apenas o `body_text` do PID em `data/processed/fulltext_gold/article_texts_gold.csv` ou o pacote derivado correspondente em `data/processed/full_classification_pilot_v2/task_packets/`.

Nao consulte XMLs antigos nem classificacoes antigas para auditar fidelidade. Nao use API.

Para cada PID e agente auditado, produza exatamente um JSON em `data/processed/full_classification_pilot_v2/fidelity_checker/<audited_agent_id>/<pid>.json` com esta estrutura:

```json
{
  "pid": "S0000-00000000000000000",
  "audited_agent_id": "agent_a",
  "checker_agent_id": "agent_d",
  "input_text_hash": "sha256_do_body_text_canonico_no_manifest",
  "classification_hash": "sha256_do_arquivo_json_de_classificacao_auditado",
  "field_audits": [
    {
      "field": "sample_size",
      "status": "supported_by_text",
      "severity": "none",
      "reason": "Razao curta.",
      "supporting_excerpt": "Trecho curto do body quando houver suporte textual.",
      "classification_value": 100
    }
  ],
  "overall_fidelity_status": "pass",
  "brief_summary": "Resumo curto."
}
```

Valores permitidos:

- `status`: `"supported_by_text"`, `"contradicted_by_text"`, `"not_found_in_text"` ou `"not_a_factual_field"`.
- `severity`: `"none"`, `"low"`, `"medium"` ou `"high"`.
- `overall_fidelity_status`: `"pass"`, `"pass_with_warnings"` ou `"fail"`.

Campos prioritarios para auditoria:

- `sample_size`
- `sample_size_quote`
- `independent_variables`
- `dependent_variables`
- `main_variable_relationship`
- `paper_uses_survey_data`
- `uses_original_dataset`
- `main_causal_research_design`
- `makes_explicit_causal_claim`
- `makes_implicit_causal_claim`
- `statement_of_identification_assumptions`
- `statement_of_identification_assumptions_quote`
- `specifies_estimate_equations`
- `effort_to_explore_mechanisms`
- `claims_any_statistically_significant_results`
- `references_power_analysis`
- `mentions_pre_registered_design_and_analysis_plan`

Regras de conservadorismo:

- Se o classificador afirmou algo especifico e o body nao sustenta, marque `not_found_in_text`.
- Se o body contradiz a classificacao, marque `contradicted_by_text`.
- Nao penalize campos puramente interpretativos quando nao forem factuais; use `not_a_factual_field`.
- Quando houver suporte, inclua um trecho curto do body. Quando nao houver, use `supporting_excerpt: null`.
- `classification_hash` deve ser o SHA-256 do arquivo JSON auditado em `data/processed/full_classification_pilot_v2/<audited_agent_id>/<pid>.json`.

## Calibracao de campos propensos a falso positivo

- `paper_uses_survey_data` audita se o artigo classificado usa dados de survey/questionario/pesquisa de opiniao como evidencia propria da analise. Nao conte como survey data: entrevista qualitativa, entrevista semiestruturada, levantamento documental, survey no sentido de "overview" ou "survey of institutional data", survey/pesquisa apenas citado em outro estudo, pesquisas de opiniao mencionadas como contexto historico, ou referencias bibliograficas.
- `sample_size` deve aceitar equivalencia de formatacao numerica: `2562` e `2,562` ou `2.562` podem ser o mesmo tamanho de amostra conforme idioma/contexto. Nao marque contradicao se o trecho contem claramente o mesmo numero formatado e linguagem de amostra, casos, respondentes, entrevistas, municipios, domicilios ou unidades analisadas.
- `sample_size_quote` deve ser avaliado junto com `sample_size`: se a quote contem a amostra ou a unidade amostral que sustenta o inteiro, marque ambos como suportados.
- Para `uses_original_dataset`, nao conte coleta qualitativa por entrevistas como `original_survey`, mas pode sustentar outras categorias de dado original quando o classificador usou uma categoria compativel.
