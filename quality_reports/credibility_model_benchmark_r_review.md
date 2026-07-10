# Revisão independente de código R

## Resumo executivo

Há **um bloqueador** em `39_compare...R`: o relatório falhará ao montar a tabela de divergências. Além disso, os gates de validade, logs e timing ainda permitem que dados inválidos ou históricos de execução contaminem a escolha do modelo.

**Nota geral: D — não aprovar antes da correção do bloqueador e dos gates de alta severidade.**

## Bloqueador 🔴

- **Coluna `title` perdida no join.** O `inner_join()` aplica os sufixos `_baseline` e `_candidate` a `title` e `journal_title` ([R39:L250](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:250)), mas o código acessa `joined$title` ([R39:L279](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:279)). A coluna não será criada em `disagreement_rows`, e o `dplyr::select(título = title)` posterior falhará ([R39:L382](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:382)). Como os dez casos foram selecionados justamente por divergirem entre high e xhigh, esse caminho será necessariamente executado.

## Alta severidade 🟠

- **Valores inválidos podem virar concordância.** Booleanos ausentes ou não reconhecidos são todos convertidos para a string `"NA"`; JSON malformado em `method_type` vira vazio ([R39:L129](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:129), [R39:L134](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:134)). Assim, dois valores inválidos podem contar como concordância. `n_complete` mede apenas número de linhas, sem validar preenchimento e domínio dos campos críticos ([R39:L299](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:299)).

- **Integridade de hashes e reading logs é incompleta.** O baseline xhigh não é confrontado com o hash do manifesto. Nos candidatos, `filter(candidate_hash != manifest_hash)` não captura hashes ausentes, pois a comparação produz `NA` ([R39:L242](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:242)). Um log passa contendo apenas `full_body_read = TRUE`, hash correto e uma lista não vazia: não são verificados `status`, PID, títulos ou resumos das seções ([R39:L183](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:183)). Os logs xhigh nem sequer entram nessa auditoria.

- **A métrica de velocidade depende do histórico de tentativas.** `total_elapsed_seconds` soma tentativas bem-sucedidas e falhas acumuladas, enquanto média e mediana usam apenas sucessos ([R39:L317](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:317)). A escolha usa o total acumulado, podendo penalizar falhas transitórias ou reruns. Também não há validação de dez sucessos por braço, PIDs, tempos finitos/não negativos ou correspondência entre `label`, `model` e `effort`. Como o agrupamento inclui três chaves, mas o join usa somente `label`, timings heterogêneos podem duplicar braços e alterar o vencedor ([R39:L333](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:333)).

- **O A/B histórico é apenas descritivo.** GPT-5.5 high aparece nas tabelas, mas é removido da regra por `filter(is_new)` ([R39:L333](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:333)). Portanto, o script pode recomendar um GPT-5.6 mesmo que todos sejam piores que GPT-5.5 high. Falta um delta ou guardrail explícito em relação ao A/B histórico.

## Severidade média 🟡

- **Denominadores pouco transparentes.** A concordância média usa `12 × nrow(candidate)`, não necessariamente `12 × 10`, e inclui concordâncias em campos estruturalmente não aplicáveis ([R39:L254](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:254)). Embora `n_compared` seja calculado, ele é omitido da tabela por campo ([R39:L378](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:378)).

- **As cotas 7/2/1 não são garantidamente exclusivas.** A seleção estrutural exclui somente PIDs já escolhidos, não todos os casos com problema de screen/método; o mesmo vale para `tough_call` ([R37:L117](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/37_select_credibility_model_benchmark_10.R:117)). No artefato atual, porém, a composição observada corresponde corretamente a 7/2/1.

- **Reprodutibilidade parcial.** Os scripts são determinísticos, parametrizados e geram seus outputs, mas dependem de execução a partir da raiz via `normalizePath(".")` ([R37:L21](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/37_select_credibility_model_benchmark_10.R:21), [R39:L23](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:23)). Não há `renv.lock`; ambos os scripts e os artefatos de seleção estavam não rastreados pelo Git. Os outputs dos novos braços e o arquivo de timings ainda estão ausentes, impedindo teste end-to-end sem executar o benchmark.

## Pontos positivos ✓

- Todas as seleções de colunas usam explicitamente `dplyr::select`; não encontrei uso inseguro de `select`.
- A seleção atual contém dez PIDs únicos, todos cobertos pelo manifesto, baseline e GPT-5.5 high, com hashes atuais coincidentes.
- Há verificações úteis de duplicidade, cobertura, existência dos task packets e UTF-8.
- Os joins da seleção são protegidos por unicidade e pertencimento dos PIDs.

**Conclusão:** há bloqueador; `39_compare...R` não deve ser usado para escolher o modelo no estado atual.