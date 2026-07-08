# Devil's Advocate Report: seção Dados

Gerado em: 2026-07-08

## Escopo da revisão

Revisei a seção `quality_reports/paper_drafts/03_dados_draft.md` contra `AGENTS.md`, `README.md`, `quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md` e `data/processed/paper_analysis/gate0_validation_checks.csv`. Para checar o risco de dessincronização da tabela, também consultei os artefatos derivados citados pelo Gate 0 e os scripts que geram denominadores e tabelas.

Não editei o draft nem `paper/paper.Rmd`.

## Vulnerabilidade principal

A seção Dados é honesta sobre a limitação central: há texto integral para os 5.250 PIDs do manifest, mas só 699 artigos foram classificados por leitura integral. A vulnerabilidade devastadora é que a honestidade depende de uma disciplina de denominadores que ainda parece frágil: a tabela do draft mistura cobertura do corpus, variáveis classificadas e um numerador de desenho estrito vindo de outra camada analítica. Se essa tabela for atualizada manualmente ou citada sem fonte geradora explícita, o paper pode rapidamente passar de "preliminar e transparente" para "preciso em aparência, mas dessincronizado".

## Ataques por dimensão

### Lógica interna

1. A abertura define o universo empírico como o conjunto SciELO 2005-2025, mas a base efetivamente analisável no momento é só o subconjunto classificado de 699 artigos.
   - **Severidade**: Alta.
   - **Problema**: o texto corrige isso depois, mas o leitor pode reter a primeira definição como promessa de inferência sobre o universo. A seção precisa fazer a arquitetura em três degraus desde o início: bruto de 8.400, manifest elegível de 5.250, classificados atuais de 699.
   - **Como o autor poderia responder**: manter a formulação atual, mas tornar o funil a primeira frase substantiva da seção e usar "universo-alvo" para 5.250, não "base analisada".

2. A exclusão de `Civitas - Revista de Ciências Sociais` tensiona a expressão "Ciências Sociais adjacentes".
   - **Severidade**: Média-Alta.
   - **Problema**: se o corpus inclui Ciências Sociais adjacentes, um revisor perguntará por que `Civitas` sai enquanto `Dados`, `RBCS`, `Lua Nova` e `Novos Estudos CEBRAP` entram. O draft informa a decisão, mas não dá uma regra substantiva suficiente para distinguir "adjacente elegível" de "fora do escopo".
   - **Como o autor poderia responder**: explicitar em uma frase a regra de escopo ou remeter a um apêndice/ledger que justifique a fronteira, não apenas dizer que o ledger existe.

3. A unidade de observação como PID é coerente, mas não resolve sozinha a unidade substantiva "artigo".
   - **Severidade**: Média.
   - **Problema**: Gate 0 valida unicidade de PID, não necessariamente ausência de duplicatas substantivas, traduções, republicações ou pares com mesmo corpo. O README já menciona duplicidade de body/hash em validação do corpus amplo; a seção Dados não diz se isso é irrelevante para o manifest analítico atual.
   - **Como o autor poderia responder**: acrescentar uma nota curta de que o controle de duplicatas foi ou será tratado em validação específica, ou evitar que "PID único" seja lido como garantia de artigo substantivamente único.

### Mecanismo causal ou interpretativo

1. A seção trata "log de leitura" como garantia forte de leitura integral.
   - **Severidade**: Alta.
   - **Problema**: o Gate 0 confirma que 699 de 699 classificados têm log, mas isso não prova, por si só, qualidade da classificação, suficiência do texto processado, nem que o classificador avaliou corretamente todas as seções relevantes. É evidência de rastreabilidade, não validação substantiva do conteúdo codificado.
   - **Como o autor poderia responder**: manter "classificações por leitura integral", mas especificar que a evidência é operacional: texto integral disponível, input/log rastreável e classificação combinada. A validação substantiva do schema deve ser citada em outra seção.

2. O texto reconhece desbalanceamento por periódico, mas subestima seu peso interpretativo.
   - **Severidade**: Alta.
   - **Problema**: a cobertura atual não é uma amostra aleatória de 13,3%; ela está concentrada em poucos periódicos e períodos, com vários periódicos centrais em 0% de classificação. Isso não é apenas uma limitação genérica; é um risco de composição que pode inverter padrões temporais, subdisciplinares e metodológicos.
   - **Como o autor poderia responder**: trocar linguagem de "cobertura parcial" por "cobertura parcial e composicionalmente concentrada", com uma frase dizendo que percentuais atuais descrevem a fila classificada, não uma amostra representativa.

### Evidência empírica

1. A checagem crítica do Gate 0 falha exatamente no ponto que permitiria resultados finais.
   - **Severidade**: Alta.
   - **Problema**: `classification_covers_full_manifest` é FAIL: 699 de 5.250 PIDs classificados, ou 13,3%. O draft responde corretamente ao chamar os resultados de preliminares, mas qualquer seção posterior que use linguagem final derruba a defesa construída aqui.
   - **Como o autor poderia responder**: transformar essa regra em requisito editorial rígido: resumo, resultados, discussão e conclusão devem repetir que a inferência é preliminar e restrita aos 699 classificados.

2. A Tabela 1 é vulnerável a denominadores ambíguos.
   - **Severidade**: Alta.
   - **Problema**: "Artigos empíricos quantitativos classificados" é 324 de 699, mas um leitor pode esperar 324 de 568 artigos empíricos. Ambas as proporções respondem a perguntas diferentes. O draft diz que o denominador é "classificados", mas os rótulos ainda permitem leitura condicional errada.
   - **Como o autor poderia responder**: renomear as linhas para "entre os 699 classificados" ou adicionar uma coluna "Pergunta respondida". Quando o subconjunto for empírico, reportar também 324/568 se a interpretação substantiva exigir.

3. A linha "Artigos classificados com desenho estrito" está correta como produto analítico, mas é órfã no Gate 0.
   - **Severidade**: Média-Alta.
   - **Problema**: o Gate 0 Markdown e `gate0_denominator_summary.csv` não incluem essa linha; ela aparece na tabela do draft e é gerada por outra camada do pipeline (`scripts/38_build_paper_analysis_artifacts.R`). Isso não é necessariamente erro, mas é uma quebra de proveniência dentro da seção Dados.
   - **Como o autor poderia responder**: ou remover essa linha da tabela de Dados e deixá-la para Estratégia/Resultados, ou citar explicitamente que ela vem da tabela preliminar gerada por `scripts/38_build_paper_analysis_artifacts.R`, não do Gate 0.

4. A diferença entre 6.642 PIDs com texto integral e 5.250 PIDs elegíveis precisa de uma frase defensiva adicional.
   - **Severidade**: Média.
   - **Problema**: o draft diz que o subconjunto analítico é o manifest de 5.250, mas um revisor pode perguntar o que são os 1.392 PIDs excedentes e se alguma exclusão substantiva está escondida aí.
   - **Como o autor poderia responder**: declarar que o excedente pertence a registros preservados fora do manifest por critérios de escopo, ledgers de exclusão ou filtros de tipo documental, e apontar o artefato de validação correspondente.

### Escopo e generalização

1. A seção ainda não protege totalmente contra inferência sobre o corpus completo.
   - **Severidade**: Alta.
   - **Problema**: a cobertura atual descreve BPSR, Contexto Internacional até 2018, Cadernos Gestão Pública e Cidadania no período presente e uma parte de Contexto Internacional 2019-2025. Ela não descreve, ainda, `Dados`, `Opinião Pública`, `RBCS`, `Revista de Sociologia e Política`, `Lua Nova`, `Novos Estudos CEBRAP` e outros blocos importantes sem classificação combinada.
   - **Como o autor poderia responder**: manter a lista de cobertura, mas acrescentar que a base atual é uma "fila operacional classificada" e não um desenho amostral.

2. O intervalo 2005-2025 passa nos checks, mas completude temporal não é a mesma coisa que min/max de ano.
   - **Severidade**: Média.
   - **Problema**: `manifest_years_2005_2025` e `classified_years_2005_2025` dizem que os anos mínimos e máximos estão corretos. Eles não provam que a cobertura de 2025 está completa em relação à indexação SciELO nem documentam data de coleta/acesso.
   - **Como o autor poderia responder**: informar data de coleta e tratar 2025 como ano indexado até o snapshot usado, caso haja risco de atraso de indexação.

3. A exclusão de BJPE e Civitas está operacionalmente validada, mas metodologicamente exposta.
   - **Severidade**: Média-Alta.
   - **Problema**: os checks confirmam que BJPE e Civitas estão ausentes do manifest e das classificações, mas o paper ainda precisa defender por que essa decisão não é cherry-picking de escopo. BJPE poderia ser atacado por proximidade com economia política; Civitas, por proximidade com Ciências Sociais.
   - **Como o autor poderia responder**: formular uma justificativa substantiva curta: quais critérios definem Ciência Política/RI/Administração Pública no SciELO e por que esses dois periódicos violam esses critérios para a análise principal.

### Reprodutibilidade e manutenção

1. O maior risco operacional é a tabela manual ficar para trás quando a classificação crescer.
   - **Severidade**: Alta.
   - **Problema**: os números do draft batem com os artefatos atuais, mas a seção não mostra uma chamada dinâmica para a tabela. Com novos lotes classificados, `699`, `13,3%`, `4.551`, `568`, `324`, `597`, `147` e `16` podem mudar em bloco. Um único número esquecido comprometerá a credibilidade da seção.
   - **Como o autor poderia responder**: gerar a tabela no manuscrito a partir de `output/tables/paper/denominator_summary.csv` ou de objeto produzido por `scripts/38_build_paper_analysis_artifacts.R`, evitando copiar números para Markdown estático.

2. Há duas fontes de denominadores com nomes parecidos.
   - **Severidade**: Média-Alta.
   - **Problema**: `data/processed/paper_analysis/gate0_denominator_summary.csv` tem os denominadores de Gate 0 sem desenho estrito; `output/tables/paper/denominator_summary.csv` inclui desenho estrito. Se ambas circularem sem nomenclatura clara, um agente ou autor pode atualizar a tabela a partir da fonte errada.
   - **Como o autor poderia responder**: separar nomes e usos: "Gate 0 coverage denominators" para completude/escopo e "paper preliminary results denominators" para variáveis classificadas e desenho estrito.

## Ranking de vulnerabilidades

1. **Classificação parcial e composicionalmente concentrada**: pode derrubar qualquer leitura como resultado final do corpus SciELO 2005-2025.
2. **Tabela de denominadores potencialmente manual/dessincronizada**: ameaça a reprodutibilidade e pode produzir inconsistências numéricas visíveis.
3. **Mistura entre Gate 0 e resultados preliminares na Tabela 1**: desenho estrito pertence a outra camada analítica e precisa de proveniência explícita.
4. **Justificativa insuficiente para exclusão de BJPE/Civitas**: operacionalmente correto, mas vulnerável a acusação de fronteira ad hoc.
5. **Ano 2025 e data de coleta pouco documentados**: o check de intervalo não prova completude temporal do snapshot.
6. **Log de leitura integral tratado como validação substantiva**: rastreabilidade não equivale a acurácia da classificação.

## O que sobrevive ao escrutínio

- A seção acerta os denominadores centrais do Gate 0: 5.250 PIDs no manifest, 699 classificados, 4.551 pendentes e 13,3% de cobertura.
- A distinção entre texto integral recuperado e classificação combinada está clara e é substantivamente importante.
- BJPE e Civitas estão corretamente tratados como fora da base analítica, e os checks atuais confirmam ausência no manifest e nas classificações.
- O intervalo 2005-2025 passa nas checagens disponíveis para manifest e classificados.
- O texto já evita a principal falha que derrubaria a seção: não apresenta os 699 classificados como corpus completo.

## Recomendação Devil's Advocate

A seção é defensável como texto preliminar, mas só se o paper mantiver três travas: nenhum resultado final sobre o corpus completo, denominadores gerados automaticamente a partir dos artefatos canônicos, e uma justificativa substantiva explícita para as exclusões de escopo. Sem essas travas, a seção Dados parece sólida hoje, mas é exatamente o tipo de seção que quebra quando a classificação avança e um número copiado manualmente fica congelado.
