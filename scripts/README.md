# Scripts

## Coleta e corpus

- `01_discover_journals.py`: consulta a API ArticleMeta do SciELO, lista periódicos e aplica filtros de área.
- `02_collect_articles.py`: coleta metadados e XMLs dos artigos, preservando respostas brutas e logs.
- `03_sample_articles.R`: gera amostra estratificada para validação manual.

## Classificação

- `04_classify_articles.py`: classifica a amostra usando a API Claude e consolida JSONs individuais em CSV.
- `classify_batch.py`: classifica subconjuntos de PIDs definidos em arquivos `batch_*.txt`.
- `classify_writing_codex.py`: classifica características de escrita via Codex CLI.

## Benchmark e auditoria

- `build_benchmark.py`: processa PDFs internacionais e calcula benchmarks de readability/style.
- `readability_audit.py`: calcula métricas de readability e estilo para `.Rmd`, `.tex` ou `.pdf`.

## Testes

```bash
python3 -m pytest scripts
```

Estado em 2026-06-01: 59 testes passaram; houve apenas um aviso de compatibilidade entre `requests` e `urllib3`.

