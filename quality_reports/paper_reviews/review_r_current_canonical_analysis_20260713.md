# Revisão de código: análise canônica corrente do paper

## Resumo executivo

A implementação reproduz corretamente o retrato numérico do snapshot corrente: 5.249 artigos elegíveis, 1.798 classificações únicas, quatro periódicos completos com 1.466 artigos e 27 artigos com desenho estrito em um screen de 463. Os denominadores estão, em geral, bem separados, o código usa caminhos relativos ao projeto, `dplyr::select`, outputs versionáveis e `sessionInfo()`, e os 12 checks implementados passam.

Há, porém, dois bloqueios antes de tratar o manuscrito como versão submetível. Primeiro, o paper não documenta nem valida substantivamente o processo de classificação que produz todas as variáveis de resultado. Segundo, a descrição do universo excluído não corresponde ao ledger vigente: o texto declara duas exclusões de periódico, enquanto `data/processed/excluded_journals.csv` contém quatro títulos excluídos. Além disso, o gate do script atual é menos completo do que os validadores já existentes no repositório e há vários números e nomes de estratos hard-coded que ficarão obsoletos na próxima atualização do CSV canônico.

## Nota geral: B-

O snapshot numérico corrente é internamente consistente, mas a validade de mensuração e a transparência do universo ainda não sustentam uma versão final do paper.

## Problemas críticos 🔴

### 1. O paper não descreve nem demonstra a validade do classificador

Toda a análise deriva de `classifications_integral_reading.csv` (`scripts/45_build_current_paper_analysis.R`, linhas 29--32), mas a Estratégia Empírica apenas descreve o significado pretendido das variáveis (`paper/paper.Rmd`, linhas 147--159). O manuscrito não informa, no texto ou em apêndice referenciado:

- modelo, versão, prompt/schema e unidade de leitura usados;
- procedimento de classificação integral e consolidação dos batches;
- amostra de validação humana, métricas por variável, concordância e adjudicação de casos difíceis;
- sensibilidade de resultados raros, especialmente os 27 desenhos estritos;
- como erros de classificação afetam comparações entre periódicos e períodos.

Os “12 de 12 PASS” do audit são checks estruturais e lógicos, não validação de construto ou acurácia. Isso é particularmente importante para resultados como 954 de 971 artigos qualitativos com objetivo claro e para o numerador raro de 27 desenhos estritos: poucos falsos positivos ou falsos negativos mudam substantivamente a conclusão. Antes de submissão, é necessário acrescentar uma subseção de protocolo de mensuração e um apêndice de validação, com estimativas de erro por variável-chave e revisão humana estratificada dos positivos raros.

### 2. A descrição do universo excluído diverge do ledger vigente

`paper/paper.Rmd`, linha 110, afirma que dois periódicos do levantamento inicial não entram na análise e nomeia apenas `Brazilian Journal of Political Economy` e `Civitas`. Entretanto, `data/processed/excluded_journals.csv` contém quatro títulos com `exclude_from_analysis == TRUE`: esses dois, `Revista de Administração Pública` e `Sur. Revista Internacional de Direitos Humanos`. A lista bruta tem 15 títulos; o manifest analítico tem 11.

O problema é substantivo, não apenas editorial. O paper inclui `Cadernos Gestão Pública e Cidadania` e declara escopo de Administração Pública, mas omite que a `Revista de Administração Pública` foi excluída precisamente por escopo de administração pública. A regra pode ser defensável, mas precisa ser explicitada e justificada de modo coerente.

O script atual também não lê `excluded_journals.csv`: os inputs declarados incluem apenas manifest, classificações e exclusões por artigo (`scripts/45_build_current_paper_analysis.R`, linhas 29--33 e 201--215). No snapshot corrente, nenhum periódico excluído aparece no manifest ou na base analítica, de modo que os números atuais não estão contaminados. Ainda assim, a análise depende silenciosamente de uma exclusão aplicada upstream. O gate deve carregar o ledger de periódicos e falhar se qualquer título/ISSN excluído entrar no manifest ou na base analítica.

## Melhorias importantes 🟡

### 3. O gate de validação permite falhas silenciosas que validadores anteriores já bloqueavam

O script classifica JSON inválido como `parse_error` e tokens desconhecidos como `unclassified` (`scripts/45_build_current_paper_analysis.R`, linhas 305--327), mas os 12 checks (`linhas 721--767`) não falham nesses casos. De modo semelhante, a conversão das categorias em factors (`linhas 295--296`) transforma níveis desconhecidos em `NA` sem um check específico.

Também faltam checks explícitos para:

- unicidade dos PIDs no manifest;
- anos dentro de 2005--2025 e `document_type == "research-article"`;
- igualdade de `journal_title` entre classificação e manifest;
- ausência de periódicos do ledger de exclusões;
- `has_statistical_inference` não ausente quando há análise quantitativa;
- análise quantitativa implicar artigo empírico;
- inferência estatística implicar flag quantitativa;
- método estrito implicar `method_present == TRUE` e citação de desenho;
- `method_present == TRUE` implicar ao menos um tipo parseado;
- `classified_n <= eligible_n` em cada periódico/período.

Na checagem independente do snapshot corrente, todos esses pontos materiais estavam íntegros: zero PIDs duplicados no manifest, zero divergências de periódico, zero anos fora da janela, zero documentos não `research-article`, zero inferências fora do subconjunto quantitativo, zero desenhos estritos fora do screen ou sem citação, zero categorias ausentes e zero `parse_error`/`unclassified`. Portanto, o problema é de proteção de reruns futuros, não de erro numérico observado agora.

### 4. Os numeradores aninhados deveriam ser calculados dentro de seus próprios subconjuntos

Em `metric_summary()` (`scripts/45_build_current_paper_analysis.R`, linhas 416--438), `n_quantitative`, `n_inference` e `n_strict` são somados sobre todas as linhas e depois divididos, respectivamente, por empíricos, quantitativos e screen. Os dados correntes obedecem à hierarquia esperada, mas a função depende dos flags estarem perfeitamente consistentes.

É mais seguro calcular diretamente:

- quantitativos como `is_empirical_paper & is_empirical_quant_paper_torreblanca`;
- inferência como `is_empirical_quant_paper_torreblanca & has_statistical_inference`;
- desenho estrito como `credibility_revolution_screen_applicable & strict_design_method`.

Alternativamente, os checks correspondentes devem bloquear qualquer violação antes do cálculo. Isso evita percentuais inválidos ou numeradores fora do denominador se um batch futuro contiver classificação inconsistente.

### 5. O paper e duas figuras contêm valores de snapshot hard-coded

O título e o resumo têm “quatro periódicos”, 5.249, 1.798, 1.466, 1.446, 833, 308, 463 e 27 escritos literalmente (`paper/paper.Rmd`, linhas 2 e 14--15). A Figura de perfil fixa “Quatro periódicos, 1.466 artigos” (`scripts/45_build_current_paper_analysis.R`, linha 909), e a figura temporal fixa os nomes BPSR, Contexto e Dados (`linha 955`). Há ainda várias frases do corpo com nomes e números de estratos escritos manualmente.

Os valores coincidem com o PDF corrente, mas a próxima rodada do CSV pode atualizar tabelas sem atualizar resumo, título, subtítulos e narrativa. Como o objetivo do script é atualizar o paper repetidamente, esses textos devem ser derivados dos objetos calculados ou cobertos por assertions de snapshot que interrompam a renderização quando houver divergência.

### 6. O paper precisa documentar fonte, snapshot e data de acesso

O manuscrito identifica o SciELO, mas não informa a data de acesso/coleta, o snapshot canônico, regras completas de elegibilidade, hashes/proveniência ou a data de fechamento das classificações. O audit registra apenas a data de geração do relatório. Para reprodutibilidade científica, a seção Dados deve apontar a fonte, data de acesso e versão/snapshot do manifest e do CSV canônico, deixando detalhes operacionais em apêndice ou material de replicação.

### 7. A média temporal igual ponderada é transparente, mas precisa de sensibilidade ponderada por artigos

O perfil temporal usa média simples das proporções de BPSR, Contexto e Dados (`scripts/45_build_current_paper_analysis.R`, linhas 656--671), e o texto declara essa escolha. Isso responde a uma pergunta editorial — o periódico médio — e evita que `Dados` domine por tamanho. Ainda assim, o paper deveria apresentar como robustez a estimativa agrupada/ponderada por artigos e, idealmente, intervalos de incerteza ou diferenças absolutas por periódico. Sem isso, a afirmação de crescimento pode refletir a escolha de ponderação, ainda que esteja corretamente qualificada como descritiva.

## Sugestões 🟢

- Acrescentar um teste automatizado/snapshot para os denominadores centrais e para a lista de periódicos completos.
- Fazer `mean(..., na.rm = TRUE)` apenas após bloquear denominadores zero por periódico-período; hoje um único `NA` pode propagar para a média temporal.
- Registrar o hash dos três inputs principais no audit, além de `sessionInfo()`.
- Distinguir no texto “artigos elegíveis no corpus” de “artigos elegíveis para o screen”; em `paper/paper.Rmd`, linha 316, os 463 casos são chamados apenas de “artigos elegíveis”, o que pode ser confundido com os 5.249 do corpus.
- Atualizar `scripts/README.md`, cuja regra operacional ainda cita apenas BJPE e Civitas, para refletir todo o ledger vigente.

## Pontos positivos ✓

- Os 1.798 registros analíticos são PIDs únicos e todos reconciliam com o manifest e o hash do texto integral.
- BJPE, Civitas, RAP e Sur estão ausentes do manifest e da base analítica corrente.
- Os quatro periódicos completos e seus Ns foram confirmados: BPSR 268, CGPC 120, Contexto 456 e Dados 622, totalizando 1.466.
- Os denominadores principais conferem: 1.446/1.798 empíricos; 833/1.446 quantitativos; 308/833 com inferência; 463/1.798 no screen; 27/463 com desenho estrito.
- O claim amplo é corretamente separado de claim causal estrito; o texto reconhece que 1.535/1.798 inclui explicações qualitativas e argumentos não empíricos.
- As comparações editoriais são restritas aos periódicos completos e a comparação temporal mantém composição constante.
- O código usa pipe nativo de forma consistente, nomes descritivos, `dplyr::select` e caminhos derivados do próprio script.
- Dados intermediários, tabelas, figuras, audit e `sessionInfo()` têm caminhos previsíveis e script de geração.
- O PDF corrente foi extraído com sucesso, contém os números do snapshot e apresenta data em português.
- `git diff --check` não encontrou problemas de whitespace.

## Conclusão de gate

**Gate para atualização interna:** PASS com ressalvas. Os resultados descritivos atuais podem ser usados como fotografia do snapshot, desde que permaneçam explicitamente preliminares.

**Gate para submissão ou circulação como evidência validada:** FAIL até (1) documentar/quantificar a validade do classificador, (2) corrigir e justificar o universo de periódicos excluídos e (3) fortalecer o gate para impedir regressões silenciosas na próxima atualização canônica.

## Rechecagem após correções

Rechecagem realizada sobre os artefatos recompilados em 13 de julho de 2026, sem editar scripts, dados ou paper. O PDF corrente tem 13 páginas, foi criado às 11:09 -03, teve o texto extraído com sucesso e as páginas 4, 10 e 13 foram inspecionadas visualmente. Não encontrei texto cortado, sobreposição, tabela ilegível, glifo corrompido ou referência quebrada nas páginas afetadas pelas correções.

### Itens solucionáveis nesta rodada

- **PASS — ledger de periódicos como input.** `scripts/45_build_current_paper_analysis.R` agora exige e lê `data/processed/excluded_journals.csv`, verifica títulos excluídos no manifest e nas classificações, escreve filas diagnósticas e inclui o hash MD5 do ledger no audit. O snapshot tem zero ocorrências excluídas.
- **PASS — transparência do universo.** `paper/paper.Rmd` agora lista BJPE, Civitas, RAP e Sur, registra a data do snapshot e aponta a proveniência/hashes. O PDF recompilado contém os quatro títulos.
- **PASS — gate ampliado.** O script passou de 12 para 28 checks e agora bloqueia duplicatas no manifest, ano, `document_type`, flags quantitativas/inferenciais fora da hierarquia, inferência ausente entre quantitativos, desenho estrito sem screen/`method_present`/citação, método presente sem tipo, parse/taxonomia, níveis categóricos desconhecidos, periódicos excluídos, divergência de periódico, hash, fulltext, área, cobertura maior que elegibilidade e demais checks anteriores. O arquivo `current_analysis_validation_checks.csv` registra 28/28 PASS.
- **PASS — numeradores aninhados.** `metric_summary()` agora calcula quantitativos dentro dos empíricos, inferência dentro dos quantitativos e desenho estrito dentro do screen. Os denominadores e números do snapshot permaneceram 1.446, 833, 308, 463 e 27.
- **PASS — sensibilidade temporal por artigos.** O script gera `output/tables/paper/period_article_weight_profile.csv`. O paper lê o arquivo, apresenta a Tabela 5 e corrige a interpretação: inferência passa de 30,3% para 34,9% com peso igual por periódico e de 37,7% para 38,8% com artigos agrupados, com queda intermediária; a conclusão agora é estabilidade, não crescimento robusto.
- **PASS — risco de números hard-coded.** O resumo continua literal por limitação do YAML, mas o setup contém `stopifnot()` para todos os números centrais. Uma mudança do snapshot interromperá a renderização em vez de produzir silenciosamente resumo e corpo divergentes.
- **PASS — qualificação das conclusões.** Título, resumo, Estratégia Empírica, Discussão e Conclusão apresentam a análise como mensuração preliminar; “desenho estrito” foi qualificado como presença nominal de família de método, sem afirmar qualidade de implementação ou validade causal.
- **PASS — PDF recompilado.** A Tabela 5 e a narrativa de sensibilidade estão legíveis na página 10; a Tabela 1 e a nova subseção de validade estão bem compostas na página 4; referências e paginação fecham corretamente na página 13.

### Resíduos técnicos não bloqueantes para o snapshot corrente

- **PARTIAL — completude categórica.** Há checks para níveis desconhecidos, mas não há check explícito para `empirical_evidence_type` ou `quantitative_analysis_type` ausente/vazio. O snapshot atual tem zero ausências; um CSV futuro poderia converter ausência em `NA` e passar pelos checks atuais dependendo dos demais flags.
- **PARTIAL — consistência fora do screen.** O gate exige `method_present` preenchido dentro do screen e bloqueia desenho estrito fora dele, mas não reproduz explicitamente a regra do schema segundo a qual `method_present` e `method_type` devem ser `NULL` quando `screen_applicable == FALSE`. O snapshot atual tem zero violações.
- **PARTIAL — denominador zero na média temporal.** `period_equal_weight_profile` ainda usa `mean()` sem bloquear previamente `n_quantitative == 0` ou `n_screen == 0` por célula periódico--período. Não há `NA` no snapshot atual, mas um periódico completo futuro com denominador zero pode propagar `NA`.
- **PARTIAL — identificação do ledger por título.** A aplicação corrente deduplica e cruza periódicos excluídos por `journal_title`, não por ISSN. Funciona para os títulos atuais, mas uma variante ortográfica futura poderia escapar do gate apesar de o ledger possuir ISSNs.
- **PARTIAL — nomes de estratos hard-coded.** Os Ns centrais têm assertions, mas os nomes BPSR/Contexto/Dados em texto e subtítulo da figura temporal não têm assertion própria contra `temporal_complete_journals`. Não há divergência no snapshot atual.

### Bloqueadores que exigem decisão substantiva ou nova validação

- **FAIL para submissão — validade humana do classificador.** O paper agora declara corretamente que os 28 checks não estimam acurácia, concordância ou validade de construto e informa variação de modelo/esforço entre lotes. Isso resolve o problema de transparência para circulação interna, mas não substitui adjudicação humana, amostra estratificada, revisão dos positivos raros e estimativa de erro por variável. Este bloqueador exige nova validação/coleta, não outra correção de código neste snapshot.
- **FAIL para inferência temporal confirmatória — proveniência por PID.** A configuração de modelo/esforço ainda não está consolidada por PID, e a ordem dos lotes se relaciona ao período. O manuscrito reconhece explicitamente o possível confundimento e rebaixa a análise temporal a diagnóstico exploratório. Teste temporal substantivo exige reconstruir essa proveniência e, idealmente, reclassificar uma amostra ou o corpus com configuração congelada.
- **FAIL para a tese completa — variáveis ausentes.** `method_explicitness` e `empirical_article_format` continuam indisponíveis. O paper não as trata mais como achados, mas a tese sobre rastreabilidade e formato só poderá ser testada depois da rodada complementar.
- **PARTIAL para submissão — justificativa substantiva do escopo.** A lista das quatro exclusões está agora correta e a fronteira é reconhecida como contestável. Ainda falta explicar por que CGPC integra o núcleo de gestão pública enquanto RAP é excluída por `out_of_scope_public_administration`. Isso requer uma decisão autoral/teórica explícita ou uma regra de conteúdo verificável; não exige nova programação.

### Gate atualizado

- **Atualização interna do paper:** **PASS.** Os problemas corrigíveis desta rodada foram resolvidos em grau suficiente para usar o PDF como relatório intermediário do snapshot corrente.
- **Submissão como teste da revolução da credibilidade:** **FAIL.** Permanecem bloqueadores de validade humana, proveniência do classificador e variáveis ainda não coletadas.
