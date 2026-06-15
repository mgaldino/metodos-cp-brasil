# Prompt `/goal` para classificar o corpus completo em blocos de 100

Use este prompt em uma nova sessão Codex aberta na raiz do repositório.

````text
/goal Classificar o corpus completo restante de artigos SciELO elegíveis para o paper da revolução da credibilidade na Ciência Política brasileira, usando o classificador `credibility_prompt_v3` por leitura integral, em blocos de 100 artigos por vez. A cada bloco de 100, parar, consolidar, reportar estatísticas básicas do bloco e aguardar autorização explícita para continuar.

Você está em `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP`.

## Contexto metodológico

O piloto v3 de 175 artigos foi concluído e auditado parcialmente. A regra ajustada após auditoria manual é:

- Regressão observacional, controles, efeitos fixos, SEM, mediação causal, path analysis ou modelos estruturais observacionais não contam automaticamente como método da revolução da credibilidade.
- `observational_regression_with_causal_claim_no_design`, `fixed_effects_causal_panel_claim` e `none_detected` são rótulos diagnósticos, não métodos positivos.
- `other_modern_causal_method` só pode contar como positivo se o artigo discutir explicitamente a estratégia/hipótese de identificação causal e defender sua plausibilidade no contexto empírico.
- Para SEM/mediação causal, procure discussão de ignorabilidade sequencial, ignorabilidade do tratamento/mediador, randomização, identificação por desenho, análise de sensibilidade ou argumento equivalente. Se não houver essa discussão, classifique como `observational_regression_with_causal_claim_no_design` e `credibility_revolution_method_present = false`.

O caso de borda do piloto, A017 (`S0104-62762018000100209`), foi removido do numerador porque usa SEM/mediação causal citando Imai, Keele e Tingley, mas não discute nem justifica ignorabilidade sequencial.

## Regras de execução

- Não faça classificação por regex, heurística, título, abstract, metadata ou labels auxiliares.
- Não reutilize classificações anteriores como verdade final.
- Não processe vários artigos no mesmo contexto de classificação.
- Cada artigo deve ser processado em uma chamada independente de `codex exec`.
- Cada execução deve ler o corpo integral, produzir `section_reading_log`, `general_summary`, `decision_audit` e só então a `classification`.
- Preserve dados brutos e arquivos extraídos.
- Não altere decisões manuais nem aplique overrides substantivos fora do que está neste prompt.
- Se editar o runner, prompt, schema ou scripts de preparação, rode testes e peça revisão independente antes do batch real.

## Preflight obrigatório

1. Leia:
   - `RULES.md` / `AGENTS.md`, se presentes.
   - `docs/credibility_prompt_v3_integral_reading_batch.md`.
   - `quality_reports/credibility_prompt_v3_integral_pilot_adjusted_check.md`, se já existir.
   - `quality_reports/credibility_prompt_v3_positive_case_check.md`, se já existir.
2. Confirme que existem:
   - `scripts/25_run_credibility_prompt_v3_integral_codex_batch.py`
   - `scripts/31_prepare_credibility_prompt_v3_full_corpus_manifest.R`
   - `scripts/32_summarize_credibility_integral_batch.R`
   - `data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md`
   - `data/processed/credibility_prompt_v3_test/prompts/classifier_prompt_v3.md`
   - `data/processed/credibility_prompt_v3_integral_reading/prompts/integral_reading_output_schema.json`
3. Rode os testes:

```bash
python3 -m pytest scripts/test_integral_codex_batch_validation.py
```

4. Gere o manifest do corpus completo restante. Por padrão, este script exclui os 175 PIDs do piloto:

```bash
Rscript --vanilla scripts/31_prepare_credibility_prompt_v3_full_corpus_manifest.R
```

O manifest esperado é:

```text
data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv
```

Os task packets ficam em:

```text
data/processed/credibility_prompt_v3_full_corpus/task_packets/
```

## Execução em blocos de 100

Output do batch completo:

```text
data/processed/credibility_prompt_v3_integral_reading/full_corpus/
```

Para cada bloco, use `--offset` e `--limit 100`.

### Bloco 1

Cheque seca:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus \
  --offset 0 \
  --limit 100 \
  --dry-run
```

Batch real, com permissão escalonada/fora do sandbox porque o runner chama subprocessos `codex exec`:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus \
  --offset 0 \
  --limit 100 \
  --timeout 2400
```

Depois do bloco, resumir:

```bash
Rscript --vanilla scripts/32_summarize_credibility_integral_batch.R \
  --csv data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv \
  --out data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/batch_summary_offset_000.md \
  --label full_corpus_offset_000_limit_100
```

Pare aqui e reporte ao usuário:

- quantos artigos foram selecionados;
- quantos completaram;
- quantos falharam;
- quantos foram empíricos;
- quantos foram quantitativos Torreblanca;
- quantos entraram no screen de credibilidade;
- quantos candidatos positivos de método apareceram;
- lista de PIDs candidatos positivos, se houver;
- lista de PIDs falhos, se houver;
- caminho do resumo do bloco.

Só continue para o próximo bloco depois de autorização explícita do usuário.

### Blocos seguintes

Repita o mesmo padrão, incrementando `--offset` de 100 em 100:

```text
Bloco 2: --offset 100 --limit 100
Bloco 3: --offset 200 --limit 100
Bloco 4: --offset 300 --limit 100
...
```

O arquivo de resumo deve usar o offset no nome:

```text
batch_summary_offset_100.md
batch_summary_offset_200.md
batch_summary_offset_300.md
...
```

Se o runner parar no meio de um bloco, repita exatamente o mesmo comando do bloco. O runner tem checkpoint por PID e pula artigos com reading log e classificação válidos. Use `--force` apenas se o usuário pedir reprocessamento.

## Consolidação final

Quando todos os blocos terminarem, rode a consolidação do manifest completo:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus \
  --combine-only
```

Depois rode o resumo final:

```bash
Rscript --vanilla scripts/32_summarize_credibility_integral_batch.R \
  --csv data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv \
  --out data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/full_corpus_summary.md \
  --label full_corpus_final
```

## Critérios de encerramento

Não marque o goal como completo até que:

- todos os PIDs do manifest estejam classificados ou tenham falha documentada;
- exista reading log para todo PID completo;
- o CSV/JSONL final consolidado esteja gerado;
- `failed/` esteja vazio ou as falhas remanescentes estejam listadas;
- o resumo final tenha sido reportado ao usuário;
- candidatos positivos de método de credibilidade tenham sido destacados para auditoria manual.

Não faça commit dos outputs grandes em:

```text
data/processed/credibility_prompt_v3_integral_reading/full_corpus/
data/processed/credibility_prompt_v3_full_corpus/task_packets/
```

Commitar apenas scripts, prompts, docs e relatórios pequenos que forem explicitamente úteis para reprodutibilidade.
````
