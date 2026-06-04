# Credibility Prompt v3: Batch por leitura integral

Este documento descreve a implementação do pipeline de classificação por leitura integral, criado depois da constatação de que a expansão automática por regras não satisfaz o requisito metodológico do projeto.

## Objetivo

Classificar artigos um a um, com contexto curto e limpo, exigindo que cada execução:

1. leia o corpo integral de um único artigo;
2. produza um resumo por seção;
3. produza um resumo geral do paper;
4. responda a uma auditoria de decisão;
5. só então produza a classificação no schema `credibility_prompt_v3`.

O script não classifica por regex, regras ou labels auxiliares. Ele apenas monta prompts, chama `codex exec`, valida a resposta e consolida outputs aceitos.

## Arquivos implementados

- `data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md`
  - Prompt wrapper que torna obrigatória a leitura integral e o `section_reading_log`.
  - Embute o prompt v3 original como definição do objeto nested `classification`.

- `data/processed/credibility_prompt_v3_integral_reading/prompts/integral_reading_output_schema.json`
  - JSON Schema usado por `codex exec --output-schema`.
  - Exige top-level com `section_reading_log`, `general_summary`, `decision_audit` e `classification`.

- `scripts/25_run_credibility_prompt_v3_integral_codex_batch.py`
  - Runner de batch.
  - Lê um manifest com `pid` e `task_packet_file`.
  - Renderiza um prompt por artigo.
  - Chama um processo `codex exec` por PID.
  - Salva raw response, logs, reading log e classificação.
  - Rejeita outputs incompletos ou inválidos.
  - Consolida JSONL/CSV apenas para PIDs com reading log e classificação válidos.

## Estrutura de outputs

Para o teste dos 10 artigos:

```text
data/processed/credibility_prompt_v3_integral_reading/test_10/
  prompts/              # prompt completo enviado ao Codex para cada PID
  raw_responses/        # resposta final bruta de cada codex exec
  run_logs/             # stdout/stderr de cada processo
  reading_logs/         # log de leitura integral por seção
  classifications/      # classificação v3 limpa por PID
  failed/               # falhas por PID
  combined/             # JSONL, CSV e relatório agregados
```

Outputs agregados do teste:

- `data/processed/credibility_prompt_v3_integral_reading/test_10/combined/classifications_integral_reading.jsonl`
- `data/processed/credibility_prompt_v3_integral_reading/test_10/combined/classifications_integral_reading.csv`
- `data/processed/credibility_prompt_v3_integral_reading/test_10/combined/integral_reading_batch_report.md`

## Validações implementadas

O runner só aceita um artigo como completo se:

- `status == "complete"`;
- `full_body_read == true`;
- existe `section_reading_log` não vazio;
- existe `general_summary`;
- existe `decision_audit` com as seis perguntas obrigatórias;
- existe `classification`;
- `pid`, `title`, `journal_title` e `input_text_hash` batem com o manifest;
- todos os campos obrigatórios do schema v3 estão presentes;
- enums de evidência, tipo quantitativo, razão de screen e métodos são válidos;
- `has_statistical_inference == true` tem `statistical_inference_quote`;
- `credibility_revolution_method_present` é `null` quando o screen não é aplicável;
- o CSV/JSONL combinado só inclui PIDs com reading log e classificação válidos.

Após revisão `review-python`, quatro problemas críticos foram corrigidos antes da execução:

- o combinado não podia aceitar classificação sem reading log correspondente;
- falhas antigas precisavam ser removidas após sucesso posterior;
- timeouts e binário `codex` ausente precisavam ser capturados por PID;
- o prompt wrapper precisava resolver o conflito com a instrução de output do prompt v3 original.

## Como reproduzir o teste dos 10

Renderizar prompts sem chamar Codex:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --dry-run --limit 10
```

Executar os 10 artigos:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --limit 10 --timeout 2400
```

No ambiente Codex atual, a execução real do runner precisa sair do sandbox porque cada iteração chama um subprocesso `codex exec`, que inicializa o app-server local. O dry-run pode rodar no sandbox; o batch real deve ser executado com permissão escalonada.

Combinar outputs já existentes:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --combine-only --limit 10
```

## Resultado do teste dos 10

O teste dos 10 artigos iniciais completou com sucesso:

- artigos no manifest: 10;
- classificações completas: 10;
- reading logs: 10;
- falhas: 0;
- PIDs faltantes: 0.

Distribuição final no teste:

| empirical_evidence_type | quantitative_analysis_type | n |
| --- | --- | ---: |
| none | none | 3 |
| quantitative_only | statistical_modeling | 3 |
| qualitative_only | none | 2 |
| mixed_empirical | descriptive_statistics_only | 1 |
| quantitative_only | bivariate_tests_or_correlations_only | 1 |

Todos os 10 reading logs têm `full_body_read == true`. O número de seções resumidas por artigo variou de 3 a 12, conforme a estrutura do paper.

## Como escalar para os 175 artigos

Depois de aprovar o teste dos 10, usar o mesmo runner com o manifest do piloto:

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py \
  --manifest data/processed/full_classification_pilot_v2/pilot_manifest.csv \
  --out-dir data/processed/credibility_prompt_v3_integral_reading/pilot_175 \
  --timeout 2400
```

O runner tem checkpoint por PID. Se a execução parar no meio, basta repetir o comando; PIDs com reading log e classificação válidos serão pulados. Para reprocessar tudo, use `--force`.

## Lições aprendidas

1. **Classificação por regras não serve como gold.**
   A tentativa inicial por regex/regras foi útil como protótipo, mas não satisfaz o protocolo de leitura integral. Ela inflou `mixed_empirical`, `statistical_modeling` e `credibility_revolution_screen_applicable` por capturar palavras como "modelo", "correlação", "survey", "base de dados" e "regressões" fora de contexto.

2. **O artefato de leitura é a trava principal.**
   Exigir `section_reading_log` por artigo cria evidência auditável de leitura sequencial. Sem esse artefato, é fácil o agente otimizar para classificação rápida.

3. **Um artigo por contexto reduz mistura.**
   Passar muitos artigos em uma mesma conversa aumenta risco de contaminação entre decisões, perda de atenção e atalhos. Um `codex exec` por PID simula melhor o desenho posterior por API.

4. **O CSV analítico deve ficar limpo.**
   Reading logs e resumos devem ficar separados de `classifications/*.json` e do CSV final. Isso preserva o dataset analítico e mantém uma trilha de auditoria consultável.

5. **A validação precisa ser adversarial.**
   Não basta pedir `full_body_read: true`; o pipeline precisa rejeitar outputs sem seção, sem resumo geral, sem auditoria de decisão ou sem consistência com o manifest.

6. **Sandbox importa.**
   O dry-run roda sem escalonamento, mas a execução real chama `codex exec` como subprocesso e pode falhar no sandbox com erro de inicialização do app-server. Para batch real, pedir permissão escalonada desde o início evita uma rodada de falhas artificiais.

7. **UTF-8 deve ser testado explicitamente.**
   Relatórios em português precisam ser validados como UTF-8 real. Em etapas anteriores, R sob locale `C` gerou escapes em vez de acentos; para relatórios em R, usar `LC_ALL=pt_BR.UTF-8`.

8. **Revisão antes da execução pegou bugs reais.**
   A revisão Python antes do batch identificou problemas de integridade que teriam comprometido a auditoria: classificação órfã sem reading log, falhas antigas persistentes, falta de captura de timeout e conflito de instruções no prompt.

## Status metodológico

O pipeline agora está adequado para gerar classificações por leitura integral no piloto, desde que:

- a execução dos 175 seja feita com o mesmo runner;
- PIDs falhos sejam reprocessados até haver reading log e classificação válidos;
- uma amostra dos reading logs seja auditada antes de declarar o conjunto como gold.

Os outputs anteriores em `data/processed/credibility_prompt_v3_pilot/outputs/` devem ser tratados como triagem preliminar por regras, não como classificação por leitura integral.
