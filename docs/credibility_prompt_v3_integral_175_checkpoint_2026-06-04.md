# Credibility Prompt v3 Integral 175: checkpoint de execução

Data: 2026-06-04  
Repositório: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP`

Este documento registra o estado da execução do classificador `credibility_prompt_v3` por leitura integral para os 175 artigos do piloto. A execução foi interrompida manualmente antes do fim e deve ser retomada com o mesmo runner, preservando os checkpoints já aceitos.

## Status do checkpoint

- Dry-run concluído com sucesso: 175 prompts renderizados em `data/processed/credibility_prompt_v3_integral_reading/pilot_175/prompts/`.
- Batch real iniciado fora do sandbox com `--timeout 2400`.
- Execução interrompida após o PID `S0104-44782005000100007`.
- Consolidação parcial executada com `--combine-only`.
- Artigos completos no combinado parcial: 117.
- Reading logs válidos: 117.
- Respostas brutas gravadas: 120.
- Arquivos de stdout/stderr: 240.
- PIDs ainda ausentes no combinado parcial: 58.
- Arquivos de falha: 3.

Os outputs locais estão em `data/processed/credibility_prompt_v3_integral_reading/pilot_175/` e continuam fora do Git por regra do `.gitignore`.

## Falhas observadas

As três falhas registradas até este checkpoint são falhas de validação de metadados por normalização de entidades HTML no título, não falhas substantivas de leitura integral:

- `S0011-52582017000200395`: `&#8220;...&#8221;` foi devolvido como aspas curvas UTF-8.
- `S0034-73292025000200604`: `&#8211;` foi devolvido como travessão UTF-8.
- `S0103-33522014000300315`: `an&#225;lise` e `pol&#237;tica` foram devolvidos com acentos UTF-8.

Antes de retomar a execução, vale revisar o critério de validação de `title` para aceitar equivalência após decodificação HTML. Como isso exige editar o runner, deve haver revisão `review-python` antes de executar uma versão alterada.

## Tempo observado até o checkpoint

Estimativa baseada nos timestamps dos arquivos de classificação e falha gravados entre o primeiro e o último artefato deste checkpoint:

- Eventos observados: 120.
- Primeiro artefato: `2026-06-04T16:07:19`, `S0011-52582006000100002.json`.
- Último artefato: `2026-06-04T19:07:50`, `S0104-44782005000100007.json`.
- Tempo decorrido entre primeiro e último artefato: 10.831,2 segundos, aproximadamente 3h00m31s.
- Intervalo médio entre artefatos: 91,0 segundos.
- Mediana do intervalo: 78,1 segundos.
- Intervalo mínimo observado: 45,9 segundos.
- Intervalo máximo observado: 205,7 segundos.
- P90 observado: 149,2 segundos.
- P95 observado: 164,8 segundos.

Essa medida é uma aproximação operacional do tempo por PID, pois o runner ainda não registra `started_at` e `finished_at` por artigo. Para checagem de andamento, um intervalo de 2 a 3 minutos por artigo é normal; ausência de checkpoint por 4 minutos ainda ocorreu dentro da execução normal. O timeout de 2400 segundos por artigo continua conservador.

## Comandos executados

Dry-run:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --dry-run
```

Batch real:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --timeout 2400
```

Consolidação parcial:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --combine-only
```

## Como retomar

Se o runner não for alterado, repetir o comando do batch real. Ele pulará os 117 PIDs com reading log e classificação válidos e tentará novamente os PIDs ausentes:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --timeout 2400
```

Se o runner for alterado para aceitar equivalência de títulos com entidades HTML decodificadas, chamar `review-python` antes do novo batch. Depois da retomada, executar novamente `--combine-only` e verificar se o combinado chegou a 175 linhas completas.

## Prompt operacional integral

O prompt abaixo é o prompt operacional usado para iniciar esta execução, copiado integralmente de `docs/credibility_prompt_v3_integral_175_session_prompt.md` para reprodutibilidade do checkpoint.

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
