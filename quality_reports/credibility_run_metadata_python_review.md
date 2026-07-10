# Revisão independente: metadados de execução dos batches de credibilidade

## Resumo executivo

Os três testes novos passam, e o encaminhamento explícito de `model_reasoning_effort` e `service_tier` pelo orquestrador está correto. Contudo, a implementação ainda não impede mistura de configurações em retomadas: os metadados são vinculados ao `combined_stem`, enquanto os resultados reutilizados por PID não carregam nem validam proveniência. **Nota geral: D.**

## Achados

### 🔴 Crítico — resultados já existentes podem ser atribuídos à configuração nova

Em `scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:542-576`, o contrato é criado por `combined_stem`; porém, em `:675-699` e `:875-880`, qualquer saída válida já existente para o PID é aceita e ignorada (`SKIP`) sem verificar modelo, esforço ou tier que a produziu. Assim:

- uma retomada de batch parcialmente executado antes da criação dos metadados grava um contrato novo e incorpora silenciosamente resultados antigos;
- executar o mesmo conjunto com outro `combined_stem` e outra configuração reutiliza os PIDs completos da execução anterior;
- `--combine-only` (`:855-858`) recompõe/reescreve saídas sem consultar qualquer contrato de proveniência.

O JSON resultante pode, portanto, afirmar uma configuração única para `selected_pids` que não foi usada em todos eles. A correção exige proveniência por artefato/PID (ou um índice imutável por PID) e validação dessa proveniência antes de `SKIP` e antes de combinar. Para saídas legadas sem proveniência, a retomada deve falhar de modo seguro ou exigir reexecução explícita.

### 🟠 Alto — a configuração lida para os metadados pode não ser a configuração lida pelo Codex

`codex_config()` fixa `~/.codex/config.toml` (`:492-500`), mas o CLI usa `$CODEX_HOME/config.toml`. Quando `CODEX_HOME` estiver definido, `effective_runtime()` (`:503-509`) poderá registrar modelo/esforço/tier diferentes dos efetivamente usados pelo comando em `:702-725`. O caminho de configuração deve seguir a mesma resolução do CLI; mais seguro ainda é materializar os três valores resolvidos como argumentos explícitos no comando executado.

### 🟡 Importante — `dry-run` cria um contrato definitivo sem executar o modelo

`write_run_metadata()` é chamado em `:860-864`, antes do desvio de `dry-run` em `:886-889`. Um ensaio seco pode, portanto, bloquear uma execução real posterior com outra configuração, mesmo sem ter produzido nenhuma classificação. Falha do binário ou interrupção antes da primeira chamada tem efeito semelhante. O `dry-run` deveria produzir apenas metadados de planejamento, ou o contrato de execução deveria ser criado/selado somente quando houver uma chamada real.

### 🟡 Importante — tier não é sempre identificado e retomadas ocultam mudanças de ambiente

No runner direto, `--service-tier` é opcional e `effective_runtime()` aceita `None`; ao contrário de modelo e esforço, `write_run_metadata()` não exige tier resolvido (`:534-550`). Isso viola o requisito de registrar sempre o tier efetivo quando nem argumento nem configuração o definem. Além disso, `codex_version`, `codex_binary` e `runner_script_sha256` ficam fora de `contract` (`:563-575`): uma retomada após atualização do CLI, troca do binário ou alteração do runner é aceita, mas o arquivo conserva apenas os valores da primeira execução, ocultando a heterogeneidade.

## Testes ausentes

- rejeição de `SKIP`/`combine-only` quando a saída por PID não tem proveniência ou tem configuração incompatível;
- resolução com `CODEX_HOME` alternativo e igualdade entre comando efetivo e contrato;
- ausência de tier tanto nos argumentos quanto no arquivo de configuração;
- sequência `dry-run` seguida de execução real com configuração diferente;
- retomada após mudança de versão/binário/script;
- testes de `runner_base()` cobrindo modelo, esforço e tier, além dos fluxos completos de `scripts/36_run_credibility_integral_next_batch.py`.

## Verificações realizadas

- leitura integral dos três arquivos e do diff atual;
- `python3 -m unittest scripts/test_credibility_run_metadata.py`: **3 testes, OK**;
- `python3 -m py_compile` nos três arquivos: **OK**.

