# Revisão de código R: artefatos do paper

Revisor: `review-r` independente  
Data: 2026-07-08  
Escopo: `scripts/37_audit_paper_corpus_completeness.R`, `scripts/38_build_paper_analysis_artifacts.R` e os CSVs listados pelo solicitante.  
Modo: somente leitura para scripts e artefatos; este relatório é o único arquivo criado.

## Resumo executivo

Os scripts estão organizados, usam `dplyr::select` de forma consistente nas seleções pós-leitura, escrevem outputs em UTF-8 e registram `sessionInfo()`. As contagens dos CSVs revisados reproduzem os cálculos centrais dos scripts, e não encontrei evidência de outputs stale por mtime ou divergência entre hash de classificação e hash do manifest para os 699 classificados.

O principal problema é metodológico: o próprio Gate 0 registra que a classificação cobre apenas 699 de 5.250 PIDs, mas o script 38 ainda escreve tabelas e figuras em caminhos finais de paper. Além disso, há quatro casos em que o screen de credibilidade é `TRUE` apesar de `causal_or_explanatory_claim_present = FALSE`, e a tabela 3 mistura categorias de método que não são mutuamente exclusivas sem declarar isso claramente.

## Nota geral: C

A infraestrutura é boa para artefatos preliminares, mas ainda não é segura para alimentar resultados substantivos finais do paper sem reforçar gates, invariantes e rótulos de denominadores.

## Problemas críticos

### 1. Gate 0 falha, mas o pipeline ainda gera artefatos com nomes finais

- Evidência: `data/processed/paper_analysis/gate0_validation_checks.csv:12` marca `classification_covers_full_manifest` como `FAIL`, com 699 de 5.250 PIDs classificados.
- Evidência: `output/tables/paper/denominator_summary.csv:2-4` mostra que apenas 13,3% do manifest foi classificado e 86,7% ainda falta.
- Evidência: `output/tables/paper/table_1_corpus_description.csv:2-12` mostra cobertura extremamente desbalanceada: dois periódicos completos, Contexto Internacional parcial e vários periódicos com 0 classificados.
- Causa no código: `scripts/37_audit_paper_corpus_completeness.R:258-299` reconhece que resultados devem ser preliminares, mas não cria um bloqueio operacional; `scripts/38_build_paper_analysis_artifacts.R:459-469` escreve tabelas em `output/tables/paper/` independentemente do Gate 0.

Impacto: alto risco de o manuscrito usar tabelas e figuras como se fossem resultados do corpus completo elegível, quando elas refletem um subconjunto parcial e não balanceado por periódico/período. A nomenclatura dos arquivos (`table_1`, `table_2`, `figure_1` etc.) reforça esse risco.

Recomendação: fazer o script 38 consumir explicitamente o Gate 0 e, se `classification_covers_full_manifest = FAIL`, escrever somente em caminhos com sufixo `preliminary` ou abortar por padrão. Se a intenção for produzir artefatos preliminares, o modo deveria exigir flag explícita.

### 2. O screen de credibilidade não é validado como subconjunto do claim causal/explicativo

- Evidência computada em checagem read-only: 4 PIDs têm `credibility_revolution_screen_applicable = TRUE` e `causal_or_explanatory_claim_present = FALSE`.
- PIDs: `S1981-38212020000300202`, `S2236-57102023000100206`, `S2236-57102023000100403`, `S2236-57102023000100404`.
- Esses quatro casos são empíricos quantitativos, têm `credibility_revolution_method_present = FALSE` e `credibility_revolution_method_type = ["none_detected"]`.
- Causa no código: `scripts/38_build_paper_analysis_artifacts.R:275-306` valida apenas que `strict_design_method` é subconjunto do screen. Não há check de `screen -> causal_or_explanatory_claim_present`, nem de `screen -> is_empirical_quant_paper_torreblanca`.
- Evidência do output: `data/processed/paper_analysis/paper_artifact_validation_checks.csv:2-6` está todo `PASS`, apesar dessa inconsistência conceitual.

Impacto: se o screen de credibilidade for definido como aplicável apenas a artigos com claim causal/explicativo, o denominador `n_screen = 147` está inflado por quatro casos. Mesmo que a definição atual permita screening puramente por modelagem estatística, isso precisa estar explicitamente documentado porque contradiz a leitura natural do funil causal.

Recomendação: adicionar checks separados para `screen_subset_of_empirical_quant`, `screen_subset_of_causal_or_explanatory_claim` ou documentar formalmente que o screen pode ser acionado por critérios alternativos. Sem isso, a tabela 3 e a figura 1 ficam metodologicamente ambíguas.

### 3. A tabela 3 não é uma partição de categorias, mas pode ser lida como se fosse

- Evidência: `scripts/38_build_paper_analysis_artifacts.R:236-241` define classes por método; `scripts/38_build_paper_analysis_artifacts.R:259-265` transforma essas classes em flags independentes por PID.
- Evidência: `output/tables/paper/table_3_causality_credibility.csv:4-6` reporta `Desenho estrito`, `Diagnóstico, não desenho` e `Outro método moderno a auditar` como linhas paralelas.
- Checagem read-only encontrou sobreposição: 1 PID é simultaneamente `strict` e `diagnostic`; 2 PIDs são simultaneamente `strict` e `other_modern_causal_method`.

Impacto: as linhas de credibilidade podem ser interpretadas como mutuamente exclusivas, mas não são. Isso é especialmente sensível porque `Desenho estrito` usa denominador `screen de credibilidade`, enquanto `Diagnóstico` e `Outro método moderno` usam `classificados`.

Recomendação: declarar na tabela que categorias de método não são exclusivas, ou construir uma classificação hierárquica exclusiva para a tabela principal.

## Melhorias importantes

### 4. O gráfico de funil continua perigoso mesmo com a legenda correta

- Evidência: `scripts/38_build_paper_analysis_artifacts.R:482-510` constrói `funnel_data` com sequência `Corpus -> Classificados -> Empíricos -> Quantitativos -> Claim causal -> Screen -> Desenho estrito`.
- O próprio subtítulo em `scripts/38_build_paper_analysis_artifacts.R:506` diz que os degraus substantivos não são todos aninhados.
- Contagens: `Quantitativos = 324`, `Claim causal/explicativo = 597`. Logo, a sequência cresce no meio do "funil".

Impacto: a figura pode induzir leitura de fluxo aninhado mesmo quando o texto alerta o contrário. Em apresentações e versões PDF, leitores tendem a interpretar barras sequenciais como funil real.

Recomendação: trocar o desenho por barras independentes com denominadores explicitados, ou separar cobertura, evidência, causalidade e credibilidade em painéis distintos.

### 5. Validações de rastreabilidade ainda são fracas para prevenir outputs dessincronizados

- `scripts/37_audit_paper_corpus_completeness.R:85-90` valida logs por presença de arquivo `.json`; `scripts/37_audit_paper_corpus_completeness.R:108-110` e `:145` não verificam conteúdo, PID interno, hash, schema ou prompt/modelo.
- `scripts/37_audit_paper_corpus_completeness.R:112-120` e `:145-146` validam texto integral por presença de PID no fulltext, não por hash/status. Na checagem read-only, `fulltext_validation_status` estava `PASS` e `body_word_count` batia no manifest, mas essa validação não está codificada no Gate 0.
- `scripts/38_build_paper_analysis_artifacts.R:172-214` carrega `classification_input_text_hash` e `manifest_input_text_hash`, mas `scripts/38_build_paper_analysis_artifacts.R:275-306` não inclui check de igualdade. Na checagem read-only, os 699 hashes de classificação batem com o manifest, mas o script não falharia se isso mudasse.

Impacto: futuros reprocessamentos podem misturar classificações, manifest e logs de versões diferentes sem que os CSVs de validação falhem.

Recomendação: adicionar checks explícitos para igualdade de hash classificação-manifest, `fulltext_validation_status == PASS`, consistência de `body_word_count`, e validação mínima do JSON de cada reading log.

### 6. Denominadores estão explícitos, mas ainda há risco de citação cruzada errada

- `output/tables/paper/denominator_summary.csv:9` reporta `Artigos classificados com desenho estrito = 16` como 2,3% dos classificados.
- `output/tables/paper/table_3_causality_credibility.csv:4` reporta o mesmo numerador como 10,9% do screen de credibilidade.

Impacto: ambos os percentuais são defensáveis, mas a coexistência de 2,3% e 10,9% para o mesmo numerador aumenta o risco de citação ambígua no texto.

Recomendação: padronizar rótulos do tipo `16/699` e `16/147` em todas as tabelas, ou criar duas colunas percentuais: `% dos classificados` e `% do screen`.

### 7. Tabela 1 sai com colunas de período fora da ordem cronológica

- Evidência: `output/tables/paper/table_1_corpus_description.csv:1` aparece como `manifest_n_2019-2025`, `manifest_n_2005-2011`, `manifest_n_2012-2018`.
- Causa provável: `period_3` é character em `scripts/38_build_paper_analysis_artifacts.R:59-66`, e `pivot_wider()` em `scripts/38_build_paper_analysis_artifacts.R:388-392` usa ordem de aparição.

Impacto: baixo para os cálculos, mas ruim para tabela de paper e aumenta chance de leitura incorreta.

Recomendação: transformar `period_3` em factor ordenado antes de agregações/tabelas ou reordenar colunas depois do `pivot_wider()`.

### 8. Tabelas são numeradas por filename, mas não têm captions autocontidas

- Os arquivos `table_1_*`, `table_2_*` e `table_3_*` estão numerados no nome, mas os CSVs não carregam captions ou notas formais de tabela.
- As figuras geradas em `scripts/38_build_paper_analysis_artifacts.R:504-510`, `:532-538`, `:559-565` e `:577-583` têm captions via `ggplot2::labs(caption = ...)`.

Impacto: se os CSVs forem importados no manuscrito sem uma camada de renderização que injete caption e nota, a regra de tabelas numeradas com caption não estará satisfeita no artefato final.

Recomendação: gerar também uma versão `.tex`, `.md` ou `.pdf` das tabelas com caption e nota, ou criar metadados de captions versionados para o render do paper.

### 9. Locale/UTF-8 está bom nos arquivos, mas frágil no shell

- `file -I` reportou `charset=utf-8` para os scripts e CSVs revisados.
- `data/processed/paper_analysis/gate0_session_info.txt` e `paper_analysis_session_info.txt` registram locale `pt_BR.UTF-8/.../C/...`.
- Minhas checagens read-only com `Rscript --vanilla -e` emitiram avisos `Setting LC_CTYPE failed, using "C"`.

Impacto: os artefatos revisados estão em UTF-8, mas a reprodutibilidade depende do ambiente. Isso já é um risco conhecido neste repo.

Recomendação: documentar o comando de execução com `LC_ALL=pt_BR.UTF-8` ou forçar locale no wrapper de renderização, sem depender apenas de `options(encoding = "UTF-8")`.

## Sugestões

- `scripts/37_audit_paper_corpus_completeness.R:78-80` usa `readr::read_csv(col_select = ...)`. Não encontrei `select()` sem namespace; o uso de `col_select` é tecnicamente seguro, mas se a regra do projeto for literal, substituir por leitura seguida de `dplyr::select()` deixaria a conformidade inequívoca.
- `scripts/37_audit_paper_corpus_completeness.R:150-167` repete o mesmo `left_join()` para checar anos classificados. Criar um objeto intermediário reduziria risco de divergência e melhoraria legibilidade.
- `scripts/38_build_paper_analysis_artifacts.R:68-95` tem mapa manual de periódicos. Como isso afeta tabela principal, valeria escrever um CSV de referência versionado e validado, em vez de manter a taxonomia embutida no script.
- `scripts/38_build_paper_analysis_artifacts.R:400-409` usa denominador `classificados` para inferência estatística. Como `has_statistical_inference` é interpretada apenas para quantitativos no mapeamento de variáveis, a tabela principal poderia também reportar `104/324 = 32,1%` entre quantitativos, além de `104/699 = 14,9%` no corpus classificado.

## Pontos positivos

- Os scripts usam pipes de forma consistente e carregam pacotes no início.
- `dplyr::select` é usado explicitamente nas seleções de colunas pós-leitura.
- Os outputs revisados são UTF-8.
- `sessionInfo()` é salvo por ambos os scripts, o que melhora auditoria reprodutível.
- O Gate 0 identifica corretamente que a cobertura completa ainda falha e escreve essa implicação em relatório.
- BJPE e Civitas estão ausentes do manifest/classificações revisados.
- As contagens centrais dos CSVs revisados batem com os cálculos read-only: manifest 5.250; classificados 699; empíricos 568; quantitativos 324; claim causal/explicativo 597; screen 147; desenho estrito 16.
- Os hashes das classificações batem com os hashes do manifest para os 699 PIDs classificados.
- Não encontrei evidência de outputs dessincronizados por mtime: os CSVs revisados foram escritos após os scripts correspondentes em 2026-07-08.

## Verificações realizadas

- Leitura integral de `/Users/manoelgaldino/.codex/skills/review-r/SKILL.md`.
- Leitura com numeração de linhas dos dois scripts R e dos oito CSVs solicitados.
- Checagem de encoding com `file -I`.
- Checagem de mtimes com `stat`.
- Checagens read-only em R para reproduzir denominadores, invariantes de funil, sobreposição de classes de método, hash classificação-manifest e consistência fulltext-manifest.
- Não rerodei `scripts/37` nem `scripts/38`, porque ambos escrevem outputs e o pedido foi não editar scripts nem artefatos.
