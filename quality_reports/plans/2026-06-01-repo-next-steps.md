# Plano do Repositório — 2026-06-01

## Diagnóstico

O repositório já tem coleta substantiva, amostra de validação, classificações LLM, benchmarks internacionais e testes unitários para os scripts de readability/benchmark. A estrutura, porém, ainda estava mais próxima de um projeto de coleta do que de um repositório de paper: faltavam `README.md`, `paper/`, `references.bib`, projeto RStudio e diretórios padronizados para outputs finais.

## Próximos Passos

1. Normalizar e validar o schema das classificações em `data/processed/classifications/*.json`.
2. Regerar `data/processed/classifications_llm.csv` depois da normalização.
3. Escrever scripts R de análise em arquivos separados e criar um script mestre para tabelas e figuras finais.
4. Produzir estatísticas descritivas do corpus: artigos por ano, periódico, subfield, tipo de evidência, status do método e desenho causal.
5. Confrontar resultados brasileiros com benchmarks internacionais, mantendo separada a camada comparável a Torreblanca et al. e a camada expandida para o Brasil.
6. Escrever `paper/paper.Rmd` e `paper/appendix.Rmd`, com tabelas e figuras numeradas e captions.
7. Preparar `replication/` com dados processados, scripts necessários, metadados e instruções de execução.

## Risco Imediato

O CSV consolidado de classificações mistura saídas antigas e novas. Antes de qualquer inferência substantiva, é necessário validar categorias e tipos de campos. Em checagem rápida, `error_in_raw_text` tem valores fora do schema atual (`False` e vazio), o que indica necessidade de migração ou reclassificação parcial.

