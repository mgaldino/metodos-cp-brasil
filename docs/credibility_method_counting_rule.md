# Regra de contagem para métodos da revolução da credibilidade

Atualizado em: 2026-06-16

## Objetivo

Esta nota define como contar métodos da revolução da credibilidade nas análises preliminares e finais do corpus SciELO classificado pelo `credibility_prompt_v3`.

A regra é conservadora: a medida principal deve contar apenas desenhos de identificação causal claramente classificados. Categorias residuais ou ambíguas devem ser preservadas para auditoria, mas não entram automaticamente no numerador principal.

## Classes analíticas

### Métodos estritos de identificação causal

Entram automaticamente no numerador principal quando `credibility_revolution_method_present == TRUE` e o método está em uma destas categorias:

- `experiment_field`
- `experiment_survey`
- `experiment_lab`
- `experiment_list`
- `difference_in_differences`
- `event_study`
- `instrumental_variables`
- `regression_discontinuity`
- `regression_kink`
- `synthetic_control`
- `synthetic_difference_in_differences`
- `matching_or_weighting`
- `dag_or_formal_causal_graph`
- `doubly_robust`
- `causal_trees_or_forests`
- `causal_discovery`

Estes métodos formam o numerador principal/conservador do paper.

### Categoria residual: `other_modern_causal_method`

`other_modern_causal_method` não entra automaticamente no numerador principal.

Essa categoria deve ser tratada como fila de auditoria manual, porque pode misturar casos substantivamente válidos com falsos positivos: SEM, mediação causal, path analysis, regressão observacional com linguagem causal ou técnicas modernas sem discussão suficiente de identificação.

Um caso `other_modern_causal_method` só pode ser promovido ao numerador principal depois de auditoria manual confirmar que o artigo:

1. apresenta explicitamente uma estratégia, hipótese ou argumento de identificação causal; e
2. defende a plausibilidade dessa identificação no contexto empírico.

Exemplos de evidência relevante incluem discussão de ignorabilidade, ignorabilidade sequencial, randomização, desenho quasi-experimental, análise de sensibilidade, restrições de exclusão, descontinuidade, paralelismo ou argumento equivalente.

### Rótulos diagnósticos que não contam como desenho

Os rótulos abaixo não entram no numerador principal:

- `observational_regression_with_causal_claim_no_design`
- `fixed_effects_causal_panel_claim`
- `none_detected`

Eles são úteis para diagnosticar linguagem causal, modelagem observacional ou ausência de desenho de identificação, mas não indicam, por si só, adoção de métodos da revolução da credibilidade.

## Convenção para tabelas e gráficos

Relatórios preliminares e finais devem apresentar pelo menos três medidas separadas:

1. **Medida principal/conservadora**: apenas métodos estritos de identificação causal.
2. **Fila de auditoria**: casos `other_modern_causal_method` ainda não adjudicados.
3. **Medida inclusiva de sensibilidade**: métodos estritos + `other_modern_causal_method`, sempre rotulada como inclusiva/preliminar enquanto não houver auditoria manual.

A manchete substantiva do paper deve usar a medida principal/conservadora. A medida inclusiva serve para transparência e sensibilidade, não como estimativa principal antes da auditoria.

## Implicação para o relatório preliminar

O relatório preliminar dos primeiros blocos classificados deve:

- contar `other_modern_causal_method` fora do numerador principal;
- listar esses casos em uma tabela de auditoria manual;
- mostrar a medida inclusiva apenas como sensibilidade;
- deixar claro que a decisão final sobre esses casos depende de revisão manual do texto e das citações de identificação.

