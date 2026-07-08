# Auditoria de variáveis finais do paper

Gerado em: 2026-07-08 20:42:54 -0300

## Síntese

- Manifest completo elegível: 5250 PIDs.
- Artigos classificados por leitura integral disponíveis: 699 (13.3% do manifest).
- O corpus completo ainda não está classificado: 4551 PIDs permanecem sem classificação combinada.
- `method_explicitness` e `empirical_article_format` não são variáveis disponíveis no classificador atual.
- Os `section_reading_log` podem subsidiar uma rodada complementar, mas não codificam sozinhos uma regra validada para essas duas dimensões.

## Regra de uso no manuscrito

- Resultados substantivos devem ser rotulados como preliminares.
- Figuras e tabelas devem informar o denominador de artigos classificados por leitura integral.
- A tese sobre baixa explicitação e baixa padronização deve aparecer como hipótese/desenho do projeto, não como resultado confirmado por esta base parcial.
- SEM, mediação causal, regressão observacional e efeitos fixos não entram no numerador de `strict_design_method` sem desenho explícito de identificação.

## Variáveis que exigem classificação complementar

- `method_explicitness`: clear, partial, absent.
- `empirical_article_format`: imrad_like, structured_non_imrad, essayistic_empirical, theoretical_or_review, unclear.
