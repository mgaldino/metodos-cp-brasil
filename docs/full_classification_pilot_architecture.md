# Pipeline piloto de classificacao tripla independente

## Objetivo

Testar, nos 175 artigos gold/elegiveis da amostra piloto, um fluxo de classificacao tripla independente antes de escalar para o corpus completo elegivel SciELO 2005-2025.

Este piloto nao usa `classifications_llm_main_analysis.csv` como base substantiva final. Esse arquivo entra apenas como lista gold/piloto para selecao dos 175 PIDs elegiveis e para comparacao posterior contra a classificacao validada.

## Escopo e exclusoes

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da analise principal.
- Artigos marcados em `data/processed/excluded_articles.csv` ficam fora da analise principal.
- Dados brutos e XMLs existentes nao sao alterados.

## Entradas

- `data/processed/classifications_llm_main_analysis.csv`: gold/piloto validado dos 175 artigos elegiveis.
- `data/processed/sample_validation_sheet.csv`: metadados de titulo, ano, periodico e idioma.
- `data/processed/sample_xmls/<pid>.xml`: texto identico de entrada para todos os classificadores.
- `data/processed/excluded_journals.csv` e `data/processed/excluded_articles.csv`: regras de exclusao.

Observacao de qualidade do insumo: no piloto executado em 2026-06-03, os 175 XMLs em `data/processed/sample_xmls/` eram identicos aos arquivos correspondentes em `data/raw/articles_fulltext/` e nenhum continha elemento `<body>`. Assim, os subagentes classificaram com base no texto local disponivel nos XMLs (titulo, resumos, palavras-chave, metadados e referencias), nao em corpo integral do artigo. Esta limitacao deve bloquear qualquer decisao de escala substantiva enquanto nao houver insumo textual completo ou enquanto o codebook nao documentar que resumos/metadados sao suficientes para determinada rodada.

## Classificadores

Os classificadores sao subagentes locais desta sessao, nao chamadas de API.

- Agente A (`agent_a`): classificador metodologico geral, literal e conservador.
- Agente B (`agent_b`): classificador com lente de identificacao causal, usando `causal-did-identification` quando util.
- Agente C (`agent_c`): classificador com lente de analise empirica, usando `data-analysis-r` quando util.

Todos usam o mesmo schema final, o mesmo manifest e os mesmos XMLs. Os prompts versionados ficam em:

- `data/processed/full_classification_pilot/prompts/common_schema_v1.md`
- `data/processed/full_classification_pilot/prompts/agent_a_v1.md`
- `data/processed/full_classification_pilot/prompts/agent_b_v1.md`
- `data/processed/full_classification_pilot/prompts/agent_c_v1.md`

## Saidas

- `data/processed/full_classification_pilot/pilot_manifest.csv`: PIDs, metadados, XML fonte e hash SHA-256 do texto classificado.
- `data/processed/full_classification_pilot/agent_a/<pid>.json`
- `data/processed/full_classification_pilot/agent_b/<pid>.json`
- `data/processed/full_classification_pilot/agent_c/<pid>.json`
- `data/processed/full_classification_pilot/agent_a_classifications.csv`
- `data/processed/full_classification_pilot/agent_b_classifications.csv`
- `data/processed/full_classification_pilot/agent_c_classifications.csv`
- `data/processed/full_classification_pilot/comparison/agent_field_agreement.csv`
- `data/processed/full_classification_pilot/comparison/consensus_field_decisions.csv`
- `data/processed/full_classification_pilot/comparison/consensus_classifications.csv`
- `data/processed/full_classification_pilot/comparison/conflicts.csv`
- `data/processed/full_classification_pilot/comparison/adjudication_queue.csv`
- `data/processed/full_classification_pilot/comparison/gold_agreement_by_agent_field.csv`
- `data/processed/full_classification_pilot/comparison/gold_agreement_consensus_by_field.csv`
- `quality_reports/full_classification_pilot_manifest_summary.md`
- `quality_reports/full_classification_pilot_validation_summary.md`
- `quality_reports/full_classification_pilot_agreement_report.md`

## Comandos

```bash
Rscript --vanilla scripts/10_prepare_full_classification_pilot.R
Rscript --vanilla scripts/11_validate_full_classification_pilot_outputs.R
Rscript --vanilla scripts/12_compare_full_classification_pilot.R
```

## Regras de consenso

- Unanimidade: aceitar provisoriamente com `consensus_level = unanimity`.
- Maioria 2 contra 1 em campo nao critico: aceitar provisoriamente com `consensus_level = majority`.
- Discordancia em campo critico: enviar para adjudicacao manual.
- JSON invalido, ausente ou sem maioria: reprocessar ou enviar para adjudicacao.

Campos criticos:

- `is_empirical_quant_paper`
- `evidence_type`
- `method_status`
- `main_causal_research_design`
- `makes_explicit_causal_claim`
- `makes_implicit_causal_claim`
- `statement_of_identification_assumptions`
- `effort_to_explore_mechanisms`

## Regra objetiva para escalar

Nao escalar para o corpus completo enquanto houver JSON ausente/invalido, fila de adjudicacao substantiva nao revisada, ou acordo contra gold insatisfatorio em campos criticos. O relatorio do piloto deve recomendar uma das tres opcoes:

- `escalar`: todos os outputs validos, baixa fila critica e acordo satisfatorio contra gold nos campos criticos.
- `ajustar_prompt_schema`: divergencias concentradas em campos especificos ou padroes sistematicos de rigor/permissividade.
- `revisar_manualmente_campos`: conflitos substantivos persistentes nos campos criticos, mesmo apos outputs validos.

Com XMLs sem corpo integral, a recomendacao operacional deve ser conservadora: nao escalar a classificacao substantiva antes de corrigir o insumo textual ou aceitar explicitamente uma classificacao baseada apenas em metadados/resumos.
