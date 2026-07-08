# Devil's Advocate Report: Estratégia Empírica

## Vulnerabilidade principal

A seção é cuidadosa ao declarar que os resultados são preliminares, mas ainda vende a estratégia como um "funil" descritivo do corpus elegível quando os artefatos sustentam algo mais estreito: uma classificação parcial, concentrada em poucos periódicos e possivelmente determinada pela ordem operacional dos batches. O risco mais grave é o leitor interpretar os percentuais como diagnóstico preliminar do campo, quando eles podem ser sobretudo diagnóstico da cobertura atualmente classificada.

## Escopo da revisão

Arquivos lidos: `AGENTS.md`, `quality_reports/paper_variable_audit/variable_gap_audit.md`, `quality_reports/paper_variable_audit/variable_mapping_final.csv`, `scripts/37_audit_paper_corpus_completeness.R`, `scripts/38_build_paper_analysis_artifacts.R`, `quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, e artefatos tabulares derivados já existentes em `output/tables/paper/` e `data/processed/paper_analysis/`.

## Ataques por dimensão

### Lógica interna

1. O "funil" não é um funil aninhado.
   - **Severidade**: Alta.
   - **Evidência**: O draft apresenta uma sequência na qual, depois de artigos empíricos quantitativos, vêm claims causais ou explicativos e screen de credibilidade (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linhas 7 e 19). Mas os números mostram 324 artigos empíricos quantitativos e 597 artigos com claim causal/explicativo (`output/tables/paper/denominator_summary.csv`, linhas 6-7). Logo, o degrau de claim causal é maior que o degrau anterior; ele não pode ser interpretado como subconjunto dos quantitativos.
   - **Por que isso importa**: A palavra "funil" comunica subconjuntos sucessivamente restritos. Aqui há dimensões parcialmente cruzadas. Um crítico poderá dizer que a figura e a narrativa induzem o leitor a uma estrutura de seleção que os dados não implementam.
   - **Como o autor poderia responder**: Reestruturar a seção como "matriz de dimensões" ou "árvore com ramos" em vez de funil único. Se quiser manter "funil", cada degrau precisa ser explicitamente recalculado como subconjunto do degrau anterior.

2. A seção reconhece a incompletude, mas subestima a assimetria da cobertura.
   - **Severidade**: Alta.
   - **Evidência**: O gate informa 699 classificados de 5.250 PIDs, isto é, 13,3%, e 4.551 sem classificação (`quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md`, linhas 7-10). Mais grave: a tabela de cobertura mostra classificação completa para `Brazilian Political Science Review`, `Cadernos Gestão Pública e Cidadania`, parte de `Contexto Internacional`, e zero para vários outros periódicos centrais (`output/tables/paper/table_1_corpus_description.csv`, linhas 2-12).
   - **Por que isso importa**: Não é apenas "base parcial"; é uma base parcial altamente concentrada. Percentuais por período, área ou periódico podem refletir a ordem de processamento dos batches, não padrões substantivos do campo.
   - **Como o autor poderia responder**: Declarar explicitamente que a base classificada atual não é amostra representativa do corpus elegível. Resultados substantivos devem ser chamados de "diagnóstico da fração já classificada", não de "diagnóstico preliminar do corpus" sem qualificação adicional.

3. A seção mistura contagem de cobertura com evidência substantiva.
   - **Severidade**: Média.
   - **Evidência**: O draft afirma que o desenho "descreve como os artigos elegíveis publicados entre 2005 e 2025 se distribuem" (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 3), mas os resultados substantivos disponíveis descrevem somente os 699 já classificados. O próprio gate diz que a classificação do manifest completo falha (`data/processed/paper_analysis/gate0_validation_checks.csv`, linha 12).
   - **Como o autor poderia responder**: Trocar a formulação por: "descreverá, quando concluída, como os artigos elegíveis se distribuem; nesta versão, descreve a fração já classificada".

### Mecanismo causal e identificação

1. `strict_design_method` ainda depende do rótulo do classificador, não de uma auditoria independente das hipóteses de identificação.
   - **Severidade**: Alta.
   - **Evidência**: O script define `strict_design_method` como presença de qualquer tipo listado em `strict_design_methods` dentro de `credibility_revolution_method_type` (`scripts/38_build_paper_analysis_artifacts.R`, linhas 96-113 e 228-249). Ele não reavalia, nesse estágio, se o artigo realmente explicita suposições, plausibilidade, ameaça à identificação, placebo, pré-tendência ou lógica causal.
   - **Por que isso importa**: A seção insiste corretamente em não confundir modelagem observacional com identificação (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linhas 15-17), mas a operação empírica ainda herda a decisão do classificador. Um leitor cético pode argumentar que "desenho estrito" é apenas um rótulo LLM derivado de leitura integral, não uma validação metodológica independente.
   - **Como o autor poderia responder**: Tratar `strict_design_method` como "candidato a desenho estrito" até auditoria manual ou segunda rodada cega dos 16 casos positivos e dos casos limítrofes.

2. A cláusula sobre SEM, mediação e efeitos fixos é mais clara conceitualmente do que operacionalmente.
   - **Severidade**: Média-Alta.
   - **Evidência**: O draft diz que SEM, mediação causal, regressão observacional e efeitos fixos "só podem contar" se houver desenho explícito e discussão de hipóteses (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 15). Porém o script implementa uma whitelist de tipos estritos e uma pequena lista diagnóstica (`scripts/38_build_paper_analysis_artifacts.R`, linhas 96-119); ele não contém uma regra específica para casos excepcionais de SEM/mediação com identificação explícita.
   - **Por que isso importa**: A redação sugere uma regra condicional sofisticada; o código implementa uma decisão categorial herdada do classificador. Essa diferença abre espaço para contestação.
   - **Como o autor poderia responder**: Escrever que, na regra atual, SEM, mediação e efeitos fixos não entram no numerador estrito salvo se uma auditoria complementar recodificar o caso como desenho de identificação explícito.

3. A proporção 16/147 presume que todo caso estrito pertence ao screen de credibilidade, mas isso não aparece como checagem formal.
   - **Severidade**: Média.
   - **Evidência**: A tabela reporta 16 desenhos estritos sobre 147 no screen (`output/tables/paper/table_3_causality_credibility.csv`, linha 4), mas o script calcula `n_strict` diretamente de `strict_design_method` e `n_screen` de `credibility_revolution_screen_applicable`, sem uma validação explícita de subconjunto (`scripts/38_build_paper_analysis_artifacts.R`, linhas 251-257 e 363-369).
   - **Como o autor poderia responder**: Acrescentar uma checagem de auditoria: `strict_design_method == TRUE` deve implicar `credibility_revolution_screen_applicable == TRUE`; se houver exceções, elas devem ser listadas e resolvidas.

4. Falhas de parse em `credibility_revolution_method_type` podem virar falso negativo silencioso.
   - **Severidade**: Média.
   - **Evidência**: `parse_method_types()` retorna `character()` em caso de erro de JSON (`scripts/38_build_paper_analysis_artifacts.R`, linhas 40-46), e `unnest(..., keep_empty = FALSE)` descarta entradas vazias (`scripts/38_build_paper_analysis_artifacts.R`, linha 218). Isso pode remover casos do universo de métodos sem alerta.
   - **Como o autor poderia responder**: O relatório de auditoria deve contar JSON inválido, método vazio em casos screen-applicable e método "unclassified". Sem isso, o numerador estrito pode estar conservador por erro técnico, não por decisão metodológica.

### Evidência empírica

1. A alegação de "leitura integral" é forte demais para o que o gate atual verifica.
   - **Severidade**: Alta.
   - **Evidência**: O draft diz que as classificações foram produzidas por leitura integral de cada artigo e não por heurísticas (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 9). O gate, porém, só checa se cada PID classificado tem um arquivo `.json` de reading log (`scripts/37_audit_paper_corpus_completeness.R`, linhas 85-90 e 108-110), e reporta "699 de 699 classificados com log" (`data/processed/paper_analysis/gate0_validation_checks.csv`, linha 6). Ele não valida aqui a qualidade do log, cobertura das seções, tamanho do corpo lido, nem consistência entre log e texto.
   - **Por que isso importa**: Um revisor poderá aceitar "protocolo de leitura integral" mas rejeitar "leitura integral verificada" sem auditoria de conteúdo dos logs.
   - **Como o autor poderia responder**: Rebaixar a redação para "classificações produzidas por um protocolo que exige leitura integral e gera logs por seção; o gate atual verifica a existência dos logs, enquanto auditorias adicionais avaliam sua suficiência".

2. "Todos os PIDs têm texto integral associado" não é idêntico a "todos têm texto integral validado para leitura substantiva".
   - **Severidade**: Média.
   - **Evidência**: O draft afirma que todos os 5.250 PIDs têm texto integral associado (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 5). O script de gate verifica anti-join entre manifest e arquivo de texto integral (`scripts/37_audit_paper_corpus_completeness.R`, linhas 112-120 e 145-146), mas não mostra no relatório uma checagem de `fulltext_validation_status`, contaminação por referências, ou suficiência textual por PID.
   - **Como o autor poderia responder**: Manter a afirmação apenas se houver uma auditoria separada de qualidade textual citada no apêndice. Caso contrário, dizer "há registro de texto processado para todos os PIDs do manifest".

3. As variáveis indisponíveis são corretamente excluídas, mas continuam centrais para a promessa teórica.
   - **Severidade**: Alta.
   - **Evidência**: O audit declara que `method_explicitness` e `empirical_article_format` não existem no classificador atual e exigem classificação complementar (`quality_reports/paper_variable_audit/variable_gap_audit.md`, linhas 10-11 e 20-23; `quality_reports/paper_variable_audit/variable_mapping_final.csv`, linhas 3 e 7). O draft reconhece isso (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linhas 23-25).
   - **Por que isso importa**: Se a tese do paper é baixa explicitação metodológica e baixa padronização textual, a seção empírica atual ainda não mede diretamente duas variáveis nucleares. O paper pode defender a necessidade do desenho, mas não pode ainda sustentar a tese substantiva.
   - **Como o autor poderia responder**: Separar explicitamente "resultados disponíveis nesta versão" de "hipóteses e variáveis necessárias para a versão final".

### Escopo e generalização

1. As comparações por periódico e área são especialmente frágeis nesta versão.
   - **Severidade**: Alta.
   - **Evidência**: A matriz por periódico tem apenas três linhas classificadas: `Brazilian Political Science Review`, `Cadernos Gestão Pública e Cidadania` e `Contexto Internacional` (`output/tables/paper/journal_dimension_matrix.csv`, linhas 1-4). Vários periódicos centrais têm cobertura zero no manifest classificado (`output/tables/paper/coverage_journal_period.csv`, linhas 9-32).
   - **Por que isso importa**: O draft diz que `journal_title` e `journal_area` permitem comparar padrões por periódico e área (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 21). Nesta versão, essas comparações são quase puramente comparação entre poucos periódicos já processados.
   - **Como o autor poderia responder**: Mover comparações por periódico/área para diagnóstico de cobertura, não resultados substantivos, até haver cobertura mínima ou amostragem justificável em cada estrato.

2. A variação temporal pode estar confundida com composição de periódicos classificados.
   - **Severidade**: Média-Alta.
   - **Evidência**: A figura temporal é calculada por período entre classificados (`scripts/38_build_paper_analysis_artifacts.R`, linhas 495-519), mas a cobertura por período varia fortemente por periódico, inclusive com zero em todos os períodos para muitos periódicos (`output/tables/paper/coverage_journal_period.csv`, linhas 9-32).
   - **Como o autor poderia responder**: Apresentar qualquer tendência temporal como diagnóstico interno da fração classificada, e não como evolução da Ciência Política brasileira, até completar o corpus ou introduzir ponderação/estratificação explícita.

3. O texto ainda pode soar como estratégia de identificação, apesar de declarar que não estima efeitos causais.
   - **Severidade**: Média.
   - **Evidência**: A seção abre dizendo que não estima efeito causal de periódicos, subcampos ou períodos (`quality_reports/paper_drafts/04_estrategia_empirica_draft.md`, linha 3), o que é correto. Mas termos como "estratégia empírica", "screen de credibilidade" e "desenho estrito de identificação" podem fazer o leitor esperar inferência sobre difusão metodológica, quando o desenho atual é medição descritiva por classificação.
   - **Como o autor poderia responder**: Usar linguagem de "estratégia de mensuração e auditoria" e reservar "identificação" exclusivamente para classificar os métodos dos artigos, não para descrever a identificação do próprio paper.

## Ranking de vulnerabilidades

1. Cobertura parcial e assimétrica: 699/5.250 classificados, concentrados em poucos periódicos, pode derrubar qualquer inferência substantiva sobre o corpus.
2. "Funil" não aninhado: 597 claims causais depois de 324 quantitativos quebra a lógica visual e conceitual da sequência.
3. Alegação forte de leitura integral: existência de log por PID não equivale a auditoria da qualidade da leitura integral.
4. `strict_design_method` como derivação do classificador: o numerador conservador ainda precisa de validação independente dos 16 positivos e dos limítrofes.
5. Variáveis centrais ausentes: `method_explicitness` e `empirical_article_format` são indispensáveis para a tese, mas ainda não estão classificadas.
6. Comparações por periódico, área e período: nesta versão, elas são diagnóstico de cobertura e batch composition, não evidência robusta de heterogeneidade substantiva.

## O que sobrevive ao escrutínio

- A seção faz a coisa certa ao declarar explicitamente 5.250 PIDs no manifest, 699 classificados e 4.551 pendentes.
- O draft reconhece que `method_explicitness` e `empirical_article_format` não podem ser usadas como resultados nesta versão.
- A exclusão de `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` parece consistente com o manifest e com as checagens do gate.
- A regra conceitual de `strict_design_method` é defensavelmente conservadora: ela tenta evitar que regressão observacional, SEM, mediação e efeitos fixos virem "credibility revolution" por associação superficial.
- A seção já contém a ressalva correta de que diferenças por periódico, área ou tempo não devem ser interpretadas causalmente.

## Veredito adversarial

A seção é promissora como descrição de uma arquitetura de mensuração, mas ainda não está blindada como estratégia empírica do paper. Para sobreviver a um revisor hostil, ela precisa trocar a promessa de "funil do corpus" por uma linguagem de "classificação parcial auditável"; explicitar que a base atual não é representativa; rebaixar a alegação de leitura integral para uma afirmação sobre protocolo e logs; e transformar `strict_design_method` em variável candidata sujeita a auditoria independente, não em evidência definitiva de identificação causal.
