# Prompt para rodar os 175 artigos em outra sessão Codex

Use este prompt em uma nova sessão Codex aberta na raiz do repositório:

````text
Você está em /Users/manoelgaldino/Documents/DCP/Papers/metodos_CP.

Objetivo: rodar o classificador `credibility_prompt_v3` por leitura integral para os 175 artigos do piloto. Cada artigo deve ser processado em uma chamada independente de `codex exec`, com leitura do corpo integral, resumo por seção, resumo geral do paper, auditoria de decisão e só então classificação no schema v3.

Regras metodológicas obrigatórias:

- Não faça classificação por regex, heurística, título, abstract, metadata ou labels auxiliares.
- Não reutilize classificações anteriores como verdade final.
- Não processe vários artigos no mesmo contexto de classificação.
- Cada iteração deve passar um único task packet integral ao Codex.
- Um artigo só pode entrar no CSV/JSONL final se tiver `status == "complete"`, `full_body_read == true`, `section_reading_log` não vazio, `general_summary`, `decision_audit` e `classification` válida.
- Preserve os arquivos extraídos/task packets; não altere dados brutos.
- Artefatos grandes e outputs locais de execução devem permanecer fora do Git. O diretório `data/processed/credibility_prompt_v3_integral_reading/pilot_175/` está no `.gitignore`.

Antes de executar:

1. Leia `docs/credibility_prompt_v3_integral_reading_batch.md`.
2. Confirme que existem:
   - `scripts/25_run_credibility_prompt_v3_integral_codex_batch.py`
   - `data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md`
   - `data/processed/credibility_prompt_v3_integral_reading/prompts/integral_reading_output_schema.json`
   - `data/processed/full_classification_pilot_v2/pilot_manifest.csv`
3. Não edite o runner antes do batch. Se precisar editar, chame `review-python` antes de executar.

Execute primeiro uma checagem seca:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --dry-run
```

Depois rode o batch real com permissão escalonada/fora do sandbox, porque o runner chama subprocessos `codex exec` e eles podem falhar no sandbox ao inicializar o app-server:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --timeout 2400
```

Se a execução parar no meio, repita exatamente o mesmo comando. O runner tem checkpoint por PID e pula artigos que já tenham reading log e classificação válidos. Use `--force` apenas se for necessário reprocessar todos os artigos.

Depois do batch, rode a consolidação/validação:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --combine-only
```

Verificações finais obrigatórias:

- Conte quantas linhas há em `pilot_175/combined/classifications_integral_reading.jsonl`; deve haver 175 se todos completaram.
- Confirme que há 175 arquivos em `pilot_175/reading_logs/` e 175 em `pilot_175/classifications/`.
- Confirme que `pilot_175/failed/` está vazio ou contém apenas falhas já resolvidas por nova execução.
- Abra o relatório `pilot_175/combined/integral_reading_batch_report.md` e reporte:
  - número de artigos classificados;
  - distribuições de evidência empírica, tipo quantitativo e screen de credibilidade;
  - lista de tough calls;
  - lista de métodos de revolução da credibilidade detectados.
- Faça uma auditoria manual rápida de uma amostra de reading logs antes de declarar o conjunto como gold.

Ao responder, informe os caminhos dos outputs finais e qualquer PID que tenha falhado. Não faça commit dos outputs em `pilot_175/`, pois eles estão ignorados por serem artefatos locais potencialmente grandes.
````
