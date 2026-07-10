## Parecer independente

**Veredito: APROVADO COM RESSALVAS**

A aritmética central está correta e Sol medium vence segundo a regra lexicográfica implementada. Contudo, o benchmark não demonstra que Sol medium seja mais correto substantivamente nem justifica sua adoção irrestrita no próximo batch.

### Principais ressalvas — motivos para não adotar Sol medium ainda

1. **Ausência de verdade de referência.** A taxa de 87,5% mede concordância com GPT-5.5 xhigh, não acurácia. O próprio relatório reconhece essa limitação ([relatório](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/credibility_prompt_v3_ab_gpt56_model_benchmark_10.md:16)). Sem adjudicação humana independente, Sol pode apenas reproduzir melhor os padrões — inclusive erros — do baseline.

2. **Amostra insuficiente para troca operacional.** São somente dez casos difíceis, sem incerteza estatística ou replicação. A diferença Sol–Terra medium equivale a sete células em 120 comparações, com campos semanticamente dependentes. Isso não sustenta generalização para o corpus.

3. **Confiabilidade operacional fraca.** Sol teve 6 falhas em 16 tentativas, isto é, **37,5% das tentativas**, embora todos os casos tenham sido recuperados no segundo processamento ([timings](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt56_model_benchmark_10/benchmark_timings.csv:16)). O padrão é semelhante ao Terra xhigh e parece um incidente compartilhado, mas a causa não é registrada.

4. **`Usage limit` não é auditável.** O CSV contém apenas `return_code=1` e `status=failed`; não contém mensagem ou categoria do erro. Portanto, não se pode afirmar, a partir dos quatro artefatos, que as falhas foram causadas por usage limit. “Falhas transitórias” significa apenas que retries posteriores funcionaram.

### Resultados da auditoria

- **Números e denominadores:** corretos. A concordância média usa 12 campos × 10 PIDs = 120 células:

  - GPT-5.5 high: 91/120 = 75,8%;
  - Sol medium: 105/120 = 87,5%;
  - Terra medium: 98/120 = 81,7%;
  - Terra xhigh: 99/120 = 82,5%.

  O denominador inclui concordâncias entre valores ausentes e dá peso igual a campos relacionados — `screen_applicable`, `screen_reason`, `method_present` e `method_type`. Assim, uma única decisão conceitual pode afetar várias células.

- **Regra lexicográfica:** implementada corretamente em [39_compare_credibility_model_benchmark.R](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/39_compare_credibility_model_benchmark.R:597). Sol empata com Terra medium em desacordos críticos, 4 contra 4, e vence no critério seguinte, concordância média. O tempo não decide essa comparação.

- **Formulação da recomendação:** imprecisa. Sol não “liderou [...] por [...] tempo” ([relatório](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/credibility_prompt_v3_ab_gpt56_model_benchmark_10.md:137)). Terra xhigh foi mais rápida: 818,8 segundos de parede contra 1.068,1 de Sol, além de menor mediana e média ([comparação](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt56_model_benchmark_10/combined/benchmark_model_comparison.csv:3)). Sol vence apesar do tempo, não por causa dele.

- **GPT-5.5 high:** incorporado corretamente nos mesmos dez PIDs como piso histórico. Porém, ele não participa como candidato na ordenação e não possui tempos. Tampouco há comparação de velocidade com GPT-5.5 xhigh. Logo, o benchmark escolhe Sol apenas entre os três braços GPT-5.6; não demonstra superioridade global sobre o processo vigente.

- **Tempos:** totais e medianas foram recomputados e conferem. Entretanto, “tempo ativo” é `perf_counter`, não tempo de CPU: inclui espera do subprocesso e deixa de refletir certas suspensões do sistema. O “tempo total de parede” soma durações das tentativas, mas não inclui o intervalo entre a primeira rodada e os retries; portanto, não é latência integral do batch.

- **Integridade textual:** o relatório e uma célula do CSV estão corrompidos, contendo sequências literais como `<c3><a7>` no lugar de acentos. O mecanismo de escrita UTF-8 não protege contra execução do script sob locale incompatível.

### Conclusão

Sol medium é o vencedor **formal e condicional** da regra definida, mas não há base para tratá-lo como vencedor em acurácia ou confiabilidade. Eu só o utilizaria no próximo batch como **piloto monitorado**, com adjudicação humana de amostra, preservação das causas de falha e comparação direta com GPT-5.5 xhigh. Para adoção sem essas salvaguardas, o parecer seria **NÃO APROVADO**.