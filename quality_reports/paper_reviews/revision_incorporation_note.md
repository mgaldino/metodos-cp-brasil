# Nota de incorporação das revisões independentes

Data: 2026-07-08

## Síntese

Os sete drafts substantivos foram escritos em `quality_reports/paper_drafts/` por implementadores separados e revisados por agentes Devil's Advocate independentes em `quality_reports/paper_reviews/`. A integração em `paper/paper.Rmd` foi feita depois da leitura das revisões, sem editar os drafts originais.

## Correções aceitas e incorporadas

- Rebaixar o escopo da versão atual para "fração classificada por leitura integral", evitando apresentar os 699 artigos como diagnóstico final do corpus completo.
- Declarar que os 699 de 5.250 PIDs não são amostra representativa demonstrada e que a cobertura é parcial e composicionalmente concentrada.
- Trocar linguagem de "transformação", "profundidade" e "resultado central" por formulações mais estreitas: diagnóstico do subconjunto classificado, aderência a padrões de identificação quando o claim demanda esse padrão e hipótese a testar no corpus completo.
- Explicitar que as dimensões `method_explicitness` e `empirical_article_format` não são resultados desta versão; elas permanecem como variáveis para rodada complementar.
- Descrever a Figura 1 como denominadores e dimensões parcialmente cruzadas, não como funil estritamente aninhado em todos os degraus.
- Explicitar que a Tabela 3 usa denominadores distintos e não forma uma distribuição única.
- Reforçar que periódico e período são estratos de descrição e auditoria de cobertura, não explicações causais nem rankings de qualidade.
- Tratar os logs de leitura como evidência operacional de rastreabilidade, não como validação substantiva plena da qualidade da classificação.
- Gerar tabelas no Rmd a partir dos CSVs produzidos pelos scripts, reduzindo risco de números copiados manualmente ficarem dessincronizados.

## Correções parcialmente incorporadas

- A crítica de que `strict_design_method` deveria ser tratado como candidato sujeito a auditoria manual foi incorporada na redação como regra conservadora derivada e passível de auditoria complementar. O texto mantém a variável como resultado preliminar porque ela é gerada por script e passou por checagens auxiliares.
- A recomendação de retirar completamente comparações por periódico e período foi incorporada apenas parcialmente. As figuras permanecem porque fazem parte do plano operacional, mas a redação as interpreta como perfil da fração classificada e diagnóstico de cobertura.
- A sugestão de justificar mais amplamente todas as fronteiras de escopo foi incorporada de forma curta no texto principal. Uma defesa mais detalhada das exclusões deve ficar no apêndice ou em relatório de corpus.

## Pontos deixados para o autor ou para rodada futura

- Classificação complementar de `method_explicitness` e `empirical_article_format`.
- Validação manual específica dos casos com `strict_design_method == TRUE` e dos casos limítrofes.
- Auditoria substantiva da suficiência dos `section_reading_log`, além da checagem de existência de um log por PID.
- Justificativa mais extensa das fronteiras de escopo entre periódicos incluídos e excluídos.
- Tratamento de Qualis, gênero de autoria e outras heterogeneidades secundárias somente depois de fontes e regras de derivação auditadas.
