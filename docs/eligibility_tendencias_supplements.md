# Decisão de elegibilidade: encartes *Tendências*

## Decisão

Os 14 encartes editoriais da série *Tendências* publicados por *Opinião Pública*
entre 2005 e 2013 não são elegíveis para a análise substantiva do paper.

## Justificativa

Os documentos compilam e apresentam resultados de pesquisas de opinião, mas
não identificam autores e não se apresentam como artigos acadêmicos assinados.
Sua indexação como `research-article` ou `rapid-communication` no SciELO não é
suficiente para tratá-los como unidades comparáveis aos artigos acadêmicos que
compõem o corpus. Mantê-los alteraria os denominadores e atribuiria práticas
metodológicas a unidades editoriais sem autoria.

A regra é documental e anterior à observação dos resultados metodológicos:
exclui a série não assinada como um todo, e não apenas os encartes que geraram
um conflito entre análise descritiva e inferência estatística.

## Implementação e preservação

- A decisão está registrada por PID em
  `data/processed/excluded_articles.csv`, com o motivo
  `non_article_data_supplement` e data de 18 de julho de 2026.
- Os dados brutos, textos integrais, metadados e classificações existentes são
  preservados no repositório.
- `scripts/45_build_current_paper_analysis.R` remove os PIDs do ledger antes de
  construir a base analítica e os denominadores do paper.
- `scripts/50_audit_tendencias_supplements.R` valida a lista, a ausência de
  autoria e a correspondência com o ledger, produzindo
  `quality_reports/paper_variable_audit/tendencias_non_article_supplements.csv`.

## PIDs excluídos

- `S0104-62762005000200008`
- `S0104-62762006000100008`
- `S0104-62762006000200009`
- `S0104-62762008000100009`
- `S0104-62762008000200010`
- `S0104-62762009000100010`
- `S0104-62762009000200009`
- `S0104-62762010000100010`
- `S0104-62762010000200011`
- `S0104-62762011000100009`
- `S0104-62762012000100012`
- `S0104-62762012000200013`
- `S0104-62762013000100010`
