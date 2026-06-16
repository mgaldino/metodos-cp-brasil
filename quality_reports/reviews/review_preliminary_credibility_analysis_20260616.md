# Revisão independente: análise preliminar de credibilidade

Data da revisão: 2026-06-16

Arquivos revisados:

- `scripts/34_build_preliminary_credibility_analysis.R`
- `scripts/35_render_preliminary_credibility_report.R`
- `quality_reports/preliminary_credibility_analysis.Rmd`
- `docs/credibility_method_counting_rule.md`

## Resumo executivo

A implementação produz uma análise preliminar útil e, nos artefatos atuais, não encontrei evidência de que os 400 resultados classificados estejam desalinhados com o manifest: em checagem externa de leitura, os 400 PIDs são únicos, correspondem aos `eligible_order` 1-400, têm 400 reading logs, têm `input_text_hash` igual ao manifest e não apresentam divergência evidente de encoding nos textos principais.

O problema central é que algumas dessas garantias não estão implementadas como validações duras no script. Para um pipeline em que identidade de PID, hash do texto e validação de corpo são gates metodológicos, o relatório atual está substantivamente plausível, mas ainda não está suficientemente blindado contra regressões antes de virar base final do paper.

## Nota geral: B

Boa estrutura e boa cautela interpretativa, com lacunas importantes de validação e apresentação. Eu aceitaria como relatório preliminar interno, mas exigiria correção dos problemas críticos antes de usar o mesmo pipeline como base final reproduzível.

## Problemas críticos

1. A validação dura não verifica `input_text_hash` contra o manifest.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 96-127, 163-181 e 237-291.
   - O script exige `input_text_hash` no CSV de classificações, mas não exige nem junta o `input_text_hash` do manifest, embora `full_corpus_manifest.csv` contenha essa coluna. Com isso, a validação aprova apenas a presença do PID no manifest, não que a classificação foi feita sobre o mesmo corpo textual.
   - Por que importa: neste projeto, `pid` e `input_text_hash` são gates estritos de identidade. Um CSV combinado antigo, gerado antes de uma correção de corpo textual, poderia passar se os PIDs fossem os mesmos.
   - Checagem externa desta revisão: os artefatos atuais têm `hash_mismatch=0` e `hash_na=0` para os 400 classificados. Portanto, o problema é de validação implementada, não de evidência atual de resultado errado.
   - Recomendação objetiva: incluir `input_text_hash` em `required_manifest_cols`, renomear os hashes no join (`classification_input_text_hash`, `manifest_input_text_hash`) e adicionar uma linha `input_text_hash_matches_manifest` em `validation_summary` com falha se houver NA ou divergência.

2. Algumas validações podem produzir `PASS` falso em caso de valores ausentes ou diretório ausente.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 233-235 e 257-262.
   - `failed_files <- list.files(failed_dir, full.names = TRUE)` seguido de `length(failed_files) == 0` não distingue diretório vazio de diretório inexistente. Se o caminho mudar ou o diretório não for criado, a validação pode registrar ausência de falhas sem ter inspecionado a fila de falhas.
   - As checagens `years_in_expected_range`, `document_type_research_article` e `fulltext_validation_pass` usam `all(..., na.rm = TRUE)`. Se os campos estiverem ausentes/NA, essas validações podem passar indevidamente.
   - O relatório afirma que "todas as validações duras passaram" em `quality_reports/preliminary_credibility_analysis.Rmd`, linhas 71-79. Essa afirmação fica forte demais enquanto esses falsos positivos forem possíveis.
   - Checagem externa desta revisão: os artefatos atuais têm `missing_year=0`, `missing_doc_type=0`, `missing_status=0`, diretório `failed/` existente e 400 logs. O risco é futuro/reprodutível.
   - Recomendação objetiva: validar `dir.exists(reading_logs_dir)` e `dir.exists(failed_dir)` explicitamente; substituir `all(cond, na.rm = TRUE)` por `all(!is.na(campo) & cond)`; registrar contagens de NA no `value` da validação.

## Melhorias importantes

1. A linguagem sobre `other_modern_causal_method` está ambígua porque os dois casos atuais já estão no numerador conservador.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 228-230, 318-339 e 654-688; `quality_reports/preliminary_credibility_analysis.Rmd`, linhas 57-61 e 174-184; `docs/credibility_method_counting_rule.md`, linhas 61-67.
   - Nos artefatos atuais: conservadora = 15, `other_modern` = 2, inclusiva = 15, overlap = 2, broad-only = 0.
   - Isso é matematicamente coerente se a medida inclusiva for uma união de artigos únicos, mas a frase "soma métodos estritos e `other_modern_causal_method`" sugere 15 + 2 = 17. A fila também mistura casos adicionais com casos já contados por método estrito.
   - Recomendação: reportar explicitamente `other_modern_overlap_with_strict` e `other_modern_broad_only`; chamar a sensibilidade de "união de artigos únicos" ou, se o objetivo for fila de adjudicação adicional, definir a fila como `other_modern_audit_queue & !conservative_credibility_design`.

2. As tabelas de casos não filtram diretamente pelas flags analíticas finais.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 399-425; `quality_reports/preliminary_credibility_analysis.Rmd`, linhas 160-184.
   - `strict_method_cases` e `other_modern_audit_queue` são derivados de `method_long` por `method_class`, não por `conservative_credibility_design` ou `other_modern_audit_queue` calculados em `analysis_df`.
   - No dado atual, isso não parece gerar caso errado. Mas se surgir uma inconsistência classificatória, por exemplo método estrito listado com `credibility_revolution_method_present == FALSE`, a tabela "Casos no numerador conservador" pode mostrar um caso que a flag final não contaria.
   - Recomendação: construir tabelas de casos a partir de `analysis_df` ou juntar as flags finais ao `method_long` e filtrar explicitamente pelas flags usadas nos numeradores.

3. O PDF duplica a numeração de tabelas e figuras.

   - Local: `quality_reports/preliminary_credibility_analysis.Rmd`, exemplos nas linhas 66, 78, 95, 103, 113, 129, 137, 155, 169, 183 e 200; figuras nas linhas 84, 88, 118, 122, 144 e 148.
   - A extração de texto do PDF mostra captions como "Tabela 1: Tabela 1. ..." e "Figura 1: Figura 1. ...".
   - Recomendação: remover "Tabela N." e "Figura N." do texto dos captions e deixar o Pandoc numerar automaticamente, ou desativar a numeração automática e manter a numeração manual. A primeira opção é preferível.

4. A reprodutibilidade depende do diretório de trabalho.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 16-17; `scripts/35_render_preliminary_credibility_report.R`, linhas 10-18; `quality_reports/preliminary_credibility_analysis.Rmd`, linhas 21-22.
   - O script assume execução a partir da raiz do repositório (`normalizePath(".")`) e o Rmd assume caminhos relativos com `..`. Isso é aceitável para uso interno, mas frágil para automação, `make`, cron ou execução a partir de outro diretório.
   - Recomendação: usar `here::here()`/`rprojroot`, ou no mínimo abortar com mensagem clara se `scripts/34_build_preliminary_credibility_analysis.R` e os diretórios esperados não existirem sob `project_dir`.

5. `pilot_exclusion_policy` é usado mas não está nos requisitos do manifest.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 118-127 e 163-174.
   - A coluna é selecionada em `manifest_meta`, mas não aparece em `required_manifest_cols`. Se um manifest futuro não trouxer essa coluna, o erro virá de `dplyr::select()`, não da validação inicial.
   - Recomendação: adicionar `pilot_exclusion_policy` a `required_manifest_cols` se ela for necessária; se não for usada no relatório, removê-la do `select`.

6. Valores booleanos não parseados viram NA e depois são parcialmente silenciados.

   - Local: `scripts/34_build_preliminary_credibility_analysis.R`, linhas 43-50, 143-154, 311-321 e 442-449.
   - `parse_bool()` é conservador, mas não há validação de que campos booleanos obrigatórios foram parseados sem NA. Depois, vários indicadores usam `sum(..., na.rm = TRUE)` ou `mean(..., na.rm = TRUE)`, o que pode esconder erro de schema.
   - Recomendação: adicionar validação para NAs introduzidos por parsing em campos obrigatórios, com contagem por coluna no `validation_summary`.

## Sugestões

1. Documentar o comando canônico com locale explícito, por exemplo `LC_ALL=pt_BR.UTF-8 Rscript --vanilla scripts/35_render_preliminary_credibility_report.R`. A execução de parsing nesta revisão emitiu warnings de locale no sandbox, embora o `session_info.txt` gerado pela implementação registre `pt_BR.UTF-8`.

2. Criar um alvo simples de reprodução (`Makefile`, `justfile` ou script wrapper) que rode a sequência `34` -> `35` e deixe claro quais artefatos são regenerados.

3. Adicionar testes mínimos não interativos para: hash mismatch, PID ausente, diretório `failed/` inexistente, campo `year` NA, campo `fulltext_validation_status` NA, overlap entre `strict` e `other_modern`, e captions sem numeração duplicada.

4. Melhorar a legibilidade das tabelas longas no PDF. As tabelas de casos carregam quotes longos e podem ficar difíceis de ler em PDF; uma versão com quotes truncados no corpo e CSV completo como apêndice/artefato seria mais limpa.

5. No relatório, declarar explicitamente que a medida inclusiva é uma união de artigos únicos, não soma aritmética de ocorrências de método. Isso evita confusão quando um artigo tem múltiplos rótulos.

## Pontos positivos

1. A separação entre script de construção (`34`) e script de renderização (`35`) é adequada, e os outputs derivados estão organizados em `data/processed`, `output/tables`, `output/figures` e `quality_reports`.

2. A regra de contagem em `docs/credibility_method_counting_rule.md` é metodologicamente conservadora e compatível com o objetivo do paper: `other_modern_causal_method` fica fora do numerador principal, e os rótulos diagnósticos não contam como desenho de identificação.

3. O Rmd sinaliza corretamente que a análise é preliminar, parcial e não aleatória, evitando tratar os primeiros 400 artigos como estimativa substantiva final.

4. O código usa `dplyr::select()` explicitamente, respeitando a regra local do projeto.

5. Os artefatos atuais passaram por checagens externas de integridade nesta revisão: 400 linhas, 400 PIDs únicos, `eligible_order` 1-400, 400 reading logs, diretório `failed/` existente e vazio, hashes atuais compatíveis com o manifest, PDF existente e PNGs gerados com dimensões válidas.

6. A cópia de segurança dos agregados originais existe em `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined_backup_20260616_before_preliminary_analysis/`, o que reduz o risco operacional da consolidação preliminar.

## Addendum pós-correção

Data da revisão pós-correção: 2026-06-16.

Escopo: revisão curta dos pontos críticos e das correções declaradas, sem editar scripts, Rmd ou outputs. A verificação foi feita por inspeção do código, parsing dos scripts e leitura dos artefatos já gerados.

### Resultado

Os problemas críticos apontados na revisão original foram sanados. Não encontrei bloqueador remanescente para uso interno do relatório preliminar, desde que a base continue tratada como parcial e não aleatória.

### Checagens realizadas

- `scripts/34_build_preliminary_credibility_analysis.R` agora inclui `input_text_hash` em `required_manifest_cols`, renomeia os hashes como `classification_input_text_hash` e `manifest_input_text_hash`, e valida `input_text_hash_matches_manifest` com falha para divergência ou hash ausente.
- O script valida explicitamente `dir.exists(reading_logs_dir)` e `dir.exists(failed_dir)` antes de contar logs/falhas.
- As validações de `year`, `document_type` e `fulltext_validation_status` agora exigem valores não ausentes e não dependem de `na.rm = TRUE` para aprovar.
- A regra condicional de `has_statistical_inference` está implementada: `NA` é aceito quando `quantitative_analysis_type == "none"` e é bloqueado quando há análise quantitativa.
- `method_present_null_consistent_with_screen` adiciona uma checagem útil de consistência entre screen e presença de método.
- A medida inclusiva foi corrigida conceitualmente como união de artigos únicos; os outputs agora reportam `other_modern_causal_method`, `other_modern sem método estrito` e a medida inclusiva separadamente.
- As tabelas de casos passaram a filtrar usando as flags finais (`conservative_credibility_design` e `other_modern_audit_queue`), reduzindo o risco de divergência entre numeradores e listas de casos.
- O Rmd removeu a numeração manual dos captions. A extração de texto do PDF atual mostra `Tabela 1: Medidas...` e `Figura 1: Progresso...`, sem duplicação do tipo `Tabela 1: Tabela 1`.

### Artefatos atuais verificados

- `validation_summary.csv` registra `PASS` para `input_text_hash_matches_manifest`, com `0 divergências`, `0 hashes de classificação ausentes` e `0 hashes de manifest ausentes`.
- `validation_summary.csv` registra `PASS` para existência dos diretórios de reading logs e falhas, `400 de 400` reading logs e `failed_directory_empty = 0`.
- `validation_summary.csv` registra `PASS` para anos, `document_type` e fulltext, com `NA=0` nesses campos.
- `sensitivity_summary.csv` registra: conservadora = 15, fila `other_modern` = 2, `other_modern sem método estrito` = 0 e inclusiva = 15. Isso resolve a ambiguidade anterior: os dois casos `other_modern` atuais sobrepõem métodos estritos e não adicionam casos ao numerador inclusivo.

### Observações residuais não bloqueantes

- Ainda recomendo manter testes automatizados mínimos para os cenários negativos principais: hash divergente, diretório `failed/` ausente, ano/document type/fulltext com `NA`, e inconsistência entre screen e método. A lógica agora está correta por inspeção, mas testes ajudariam a impedir regressões.
- A dependência do diretório de trabalho foi mitigada por checagem explícita de arquivos esperados na raiz do repositório. Isso é suficiente para o fluxo atual; `here::here()`/`rprojroot` continua sendo melhoria opcional, não bloqueador.

### Conclusão pós-correção

Revisão pós-correção aprovada. Os bloqueadores críticos foram fechados e o relatório preliminar está adequado como artefato interno de validação e estruturação da análise final.
