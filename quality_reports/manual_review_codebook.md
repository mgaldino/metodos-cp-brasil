# Codebook da Revisão Manual

Preencha `decision_value` em `quality_reports/manual_review_queue.csv` usando os valores permitidos abaixo. Use `<NULL>` quando o campo aceitar nulo e o valor substantivo não se aplicar. Use `decision_note` para justificar decisões difíceis.

| field | allowed_values |
| --- | --- |
| error_in_raw_text | No Error<br>Missing/Corrupt<br>Title/Text Mismatch |
| is_empirical_quant_paper | TRUE<br>FALSE |
| paper_uses_survey_data | no_survey_data<br>runs_original_survey<br>uses_public_available_survey |
| uses_original_dataset | original_survey<br>field_experiment<br>field_study<br>structure_systematize<br>procure_original_data<br>other_original_data<br>not_original<br><NULL> |
| general_goal_of_analysis | Describe<br>Predict<br>Explain<br><NULL> |
| single_country_study | single_country<br>multiple_countries<br><NULL> |
| single_region | single_region<br>multiple_region<br><NULL> |
| evidence_type | quantitative<br>qualitative<br>mixed<br>theoretical-normative |
| method_status | explicit<br>essayistic |
| effort_to_explore_mechanisms | No Mention of Mechanisms/Channels<br>Mechanisms/Channels Mentioned But Not Explored<br>Mechanisms/Channels Mentioned With Substantial Exploration<br><NULL> |
| main_variable_relationship | <NULL><br>structured_json_required |

## Regras de preenchimento

- `decision_status`: deixe `pending` enquanto não decidido; use `done` quando a decisão estiver pronta.
- `decision_value`: deve ser um valor permitido no codebook para o campo.
- `decision_note`: registre justificativa curta quando a decisão não for óbvia.
- `reviewer`: iniciais ou nome de quem revisou.
- `review_date`: data em formato `YYYY-MM-DD`.
