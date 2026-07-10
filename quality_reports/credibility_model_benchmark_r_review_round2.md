# Revisão independente — segunda rodada

**Veredito: NÃO APROVADO para executar o benchmark real.**

## Bloqueadores 🔴

1. **Validação de valores ainda incompleta.**  
   A função exclui `has_statistical_inference` e `credibility_revolution_method_present` da validação booleana. Valores não vazios como `"maybe"` passam como `<INVALID>` e entram no cálculo de discordância. Também não há validação das categorias permitidas em `empirical_evidence_type`, `quantitative_analysis_type`, `credibility_revolution_screen_reason` e nos métodos dentro do JSON. Apenas a sintaxe JSON é verificada. Evidência: [39_compare_credibility_model_benchmark.R](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:192).

2. **Logs das referências são verificados, mas não são gate.**  
   O script inspeciona logs do GPT-5.5 high e do baseline xhigh, porém `new_log_failures` considera somente os três braços novos. Assim, referências com logs inválidos ainda podem sustentar comparação, piso histórico e recomendação. Evidência: [39_compare_credibility_model_benchmark.R](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:457).

## Achados importantes 🟡

- **Timing:** há exatamente um timing **bem-sucedido** por label/PID, não necessariamente uma única linha. Tentativas falhas adicionais são permitidas. Isso é adequado se retries forem intencionais; não satisfaz literalmente “um timing exatamente uma vez”. Além disso, `n_failed_attempts` ignora `return_code != 0` quando `status == "complete"`. Evidência: [39_compare_credibility_model_benchmark.R](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:305).
- O teste end-to-end passou, mas cobre apenas o caminho feliz com braços idênticos ao baseline. Não exercita o ramo com discordância de `title` nem rejeições por valor inválido, hash, log, timing duplicado ou piso histórico. Evidência: [test_credibility_model_benchmark_R.R](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/test_credibility_model_benchmark_R.R:118).

## Pontos resolvidos ✓

- Join e uso de `title_baseline`.
- Hashes ausentes/divergentes no baseline e candidatos.
- Validação estrutural dos logs: status, PID, metadados, hash, leitura integral, seções e resumos.
- Mapeamento `label/model/effort`.
- Denominador de **12 campos × 10 PIDs**.
- Cotas exclusivas 7/2/1; a seleção atual contém exatamente dez PIDs.
- Piso histórico GPT-5.5 high aplicado aos desacordos críticos e à concordância média.
- `Rscript scripts/test_credibility_model_benchmark_R.R`: **PASS**.
- Seletor executado integralmente com saída em `/dev/null`: **10 PIDs**.
- `git diff --check`: **PASS**.

Nenhum arquivo foi editado.