# Devil's Advocate Report — Introdução

## Escopo

Revisão independente da seção `quality_reports/paper_drafts/01_introducao_draft.md`, à luz de `AGENTS.md`, `quality_reports/plans/2026-07-08-paper_sintese_variaveis_finais.md`, `quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md` e artefatos de auditoria de variáveis já existentes. Não foram editados o draft nem `paper/paper.Rmd`.

## Vulnerabilidade principal

A introdução ainda promete mais do que a base atual pode entregar. Ela formula a contribuição em torno de explicitação metodológica, arquitetura textual e padronização do artigo empírico, mas essas duas variáveis centrais ainda não estão disponíveis no classificador atual e exigem rodada complementar. A cautela sobre resultados preliminares aparece no texto, mas não neutraliza totalmente a impressão de que o paper já mede o fenômeno amplo da prática metodológica brasileira entre 2005 e 2025.

## Ataques por dimensão

### Lógica interna

1. A tese central depende de variáveis ainda ausentes.
   - **Severidade**: Alta.
   - **Problema**: A introdução afirma que o artigo amplia o diagnóstico para incluir "explicitação metodológica" e "arquitetura textual do artigo empírico" e depois diz que o paper mede padrões por periódico, área e período. Mas o plano reconhece que `method_explicitness` e `empirical_article_format` são indispensáveis para essa tese e ainda precisam ser construídas por classificação complementar. A auditoria de variáveis é ainda mais direta: essas variáveis não estão disponíveis e a tese sobre baixa explicitação e padronização deve aparecer como hipótese/desenho, não como resultado confirmado.
   - **Evidência**: `01_introducao_draft.md`, linhas 9, 11, 13 e 17; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 145, 177 e 271-279; `variable_gap_audit.md`, linhas 10-17.
   - **Como o autor poderia responder**: Rebaixar a contribuição da introdução para "desenhar uma mensuração" e "apresentar resultados preliminares sobre o funil já classificado", deixando explícito que explicitação metodológica e formato do artigo empírico são agenda complementar, não achado desta versão.

2. A disciplina de denominadores está presente, mas ainda vulnerável a leitura indevida.
   - **Severidade**: Alta.
   - **Problema**: O draft corretamente diz que 699 de 5.250 PIDs foram classificados e que os números não são resultados finais. Mesmo assim, a pergunta e a contribuição são formuladas como se o objeto empírico já fosse a prática metodológica dos artigos brasileiros de 2005 a 2025. O Gate 0 mostra que 4.551 PIDs ainda não têm classificação combinada; portanto, qualquer padrão substantivo observado nos 699 classificados pode refletir ordem de processamento, composição de periódicos/períodos, dificuldade de classificação ou viés de cobertura.
   - **Evidência**: `gate0_corpus_completeness_audit.md`, linhas 7-11 e 28-30; `01_introducao_draft.md`, linhas 5, 15, 17 e 19.
   - **Como o autor poderia responder**: Usar sempre "subconjunto atualmente classificado por leitura integral" quando houver números. Evitar que "entre 2005 e 2025" pareça uma conclusão sobre o corpus completo. Se o draft mantiver resultados na introdução, acrescentar uma frase sobre a não representatividade ainda não demonstrada dos 699 PIDs.

3. O número de 16 desenhos estritos aparece sem ancoragem suficiente na introdução.
   - **Severidade**: Média-Alta.
   - **Problema**: O Gate 0 valida 699 classificados, 568 empíricos, 324 empíricos quantitativos, 597 com claim causal/explicativo e 147 no screen de credibilidade, mas não valida diretamente os 16 desenhos estritos. Esse número vem de uma variável derivada (`strict_design_method`) e precisa ser apresentado como preliminar, derivado por regra conservadora, com denominadores apropriados: 16/699 e, preferencialmente, 16/147.
   - **Evidência**: `gate0_corpus_completeness_audit.md`, linhas 14-22; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 181-198 e 199-209; `variable_mapping_final.csv`, linha 9; `01_introducao_draft.md`, linha 15.
   - **Como o autor poderia responder**: Acrescentar "por regra derivada conservadora" e não listar o 16 no mesmo nível de status dos indicadores auditados pelo Gate 0, ou deslocar esse detalhe para a seção de estratégia empírica.

4. A denominação do universo ainda é ampla demais.
   - **Severidade**: Média-Alta.
   - **Problema**: A introdução alterna entre "Ciência Política brasileira", "artigos brasileiros de Ciência Política, Relações Internacionais e Administração Pública" e "periódicos brasileiros elegíveis no SciELO". O universo operacional correto é mais estreito: artigos elegíveis no SciELO, em periódicos incluídos no manifest, com exclusões substantivas de `Brazilian Journal of Political Economy` e `Civitas`. Sem essa precisão, o leitor pode entender que o paper cobre toda a produção brasileira da área.
   - **Evidência**: `AGENTS.md`, objetivo do repositório; `01_introducao_draft.md`, linhas 3, 5, 13, 15 e 17; `gate0_corpus_completeness_audit.md`, linhas 8-12.
   - **Como o autor poderia responder**: Trocar formulações abrangentes por "produção em periódicos brasileiros elegíveis no SciELO no escopo do manifest". Reservar "Ciência Política brasileira" para motivação, não para descrição do universo empírico.

### Mecanismo causal

1. A passagem de profissionalização formal para prática publicada é plausível, mas causalmente subespecificada.
   - **Severidade**: Média.
   - **Problema**: A introdução sugere que artigos publicados são um teste mais exigente da profissionalização da disciplina. Isso é defensável como escolha observacional, mas não como inferência sobre o efeito de programas, ensino de métodos, internacionalização ou recomendações normativas sobre práticas publicadas. O próprio plano manda evitar claims causais sobre periódicos, subcampos e posição institucional.
   - **Evidência**: `01_introducao_draft.md`, linhas 3 e 7; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 45-48 e 281-285.
   - **Como o autor poderia responder**: Formular a relação como "janela observável" ou "indicador público" da prática disciplinar, não como teste causal da profissionalização formal.

2. Há risco de escorregar para sociologia do campo fora do escopo.
   - **Severidade**: Média.
   - **Problema**: A introdução menciona expansão de pós-graduação, inserção internacional e formação metodológica. Isso funciona como contexto, mas pode atrair cobrança por uma explicação sociológica das diferenças entre periódicos, áreas e períodos. O plano diz explicitamente que o eixo principal não deve ser sociologia do campo científico.
   - **Evidência**: `01_introducao_draft.md`, linhas 3 e 17; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 45-48, 86-89 e 281-286.
   - **Como o autor poderia responder**: Manter essas referências como motivação bibliográfica e dizer que o desenho é descritivo, não explicativo das causas institucionais das práticas observadas.

### Evidência empírica

1. A introdução pode transformar "desenho final do projeto" em "base empírica já pronta".
   - **Severidade**: Alta.
   - **Problema**: A linha 13 diz que o desenho final tem 5.250 PIDs, todos com texto integral preservado, e descreve variáveis de classificação. A linha 15 corrige isso ao dizer que só 699 foram classificados, mas a ordem retórica é perigosa: primeiro cria a imagem de um corpus integral pronto; depois introduz a limitação. O Gate 0 exige que resumo, Dados, Resultados e Conclusão rotulem os resultados como preliminares.
   - **Evidência**: `01_introducao_draft.md`, linhas 13-15; `gate0_corpus_completeness_audit.md`, linhas 7-11 e 28-30.
   - **Como o autor poderia responder**: Na primeira menção empírica, separar "corpus de texto integral preservado" de "subconjunto classificado". Exemplo conceitual: "O corpus textual completo está preservado, mas a classificação substantiva desta versão cobre 699 PIDs".

2. As variáveis ausentes não podem aparecer como resultado por antecipação.
   - **Severidade**: Alta.
   - **Problema**: O texto fala em lacunas de explicitação e padronização como questão substantiva e em arquitetura rastreável como problema central. Esse é o coração do paper planejado, mas a base atual só sustenta diretamente o funil já classificado: empírico, tipo de evidência, quantitativo, inferência estatística, claim causal, screen de credibilidade e desenho estrito derivado. Sem classificação complementar, a introdução deve evitar qualquer frase que soe como "já encontramos baixa explicitação" ou "já medimos baixa padronização".
   - **Evidência**: `01_introducao_draft.md`, linhas 5, 9, 11, 13 e 17; `variable_gap_audit.md`, linhas 10-17; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 130-146 e 158-178.
   - **Como o autor poderia responder**: Distinguir três camadas: resultados preliminares disponíveis; dimensões centrais ainda em classificação; hipótese interpretativa que só poderá ser confirmada depois.

3. Falta cautela explícita sobre seleção dos 699 classificados.
   - **Severidade**: Média-Alta.
   - **Problema**: Dizer que 699 correspondem a 13,3% do manifest é necessário, mas insuficiente. Para evitar overclaiming, a introdução deveria informar se esses 699 são ordem operacional, batch acumulado, amostra estratificada, primeiros disponíveis ou outra lógica. Sem isso, não há base para usar sua composição como evidência do campo.
   - **Evidência**: `gate0_corpus_completeness_audit.md`, linhas 7-10 e 14-22; `01_introducao_draft.md`, linha 15.
   - **Como o autor poderia responder**: Acrescentar uma frase curta: "Este subconjunto ainda não deve ser tratado como amostra representativa do manifest completo".

### Escopo e generalização

1. O pluralismo metodológico está protegido, mas a norma de "arquitetura reconhecível" ainda pode soar como padronização excessiva.
   - **Severidade**: Média.
   - **Problema**: A introdução afirma explicitamente que ensaios, qualitativos, históricos, revisões e normativos são legítimos. Isso é bom. O risco residual é que "arquitetura rastreável" e "maneira reconhecível para o leitor" sejam lidos como cobrança de um formato único, especialmente IMRaD, contra tradições qualitativas ou históricas.
   - **Evidência**: `01_introducao_draft.md`, linhas 5 e 11; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 13, 169-177 e 281-287.
   - **Como o autor poderia responder**: Amarrar a cobrança a rastreabilidade mínima de evidência, método e inferência, não a um formato único. Dizer explicitamente que estruturas não-IMRaD podem ser adequadas quando deixam dados, procedimento e limites inferenciais legíveis.

2. A generalização para "Ciência Política brasileira no período" é a maior armadilha externa.
   - **Severidade**: Alta.
   - **Problema**: Mesmo depois de classificar 5.250 PIDs, o universo será SciELO elegível, não todo o campo. Na versão atual, com 699 classificados, a generalização é ainda mais frágil. A introdução já diz que os números não são finais, mas a frase "base longitudinal de artigos publicados" pode ser lida como cobertura consolidada.
   - **Evidência**: `01_introducao_draft.md`, linhas 15 e 17; `AGENTS.md`, objetivo do repositório; `gate0_corpus_completeness_audit.md`, linhas 8-12.
   - **Como o autor poderia responder**: Usar "base longitudinal em construção" ou "corpus SciELO elegível" e evitar "diagnóstico final do campo".

### Citações e formulação

1. As chaves bibliográficas citadas existem, mas a sintaxe pode gerar redundância autor-data.
   - **Severidade**: Baixa-Média.
   - **Problema**: As chaves `soares2005`, `barberia2014`, `albuquerque2022`, `figueiredo2019` e `torreblanca2026` estão em `references.bib`. O problema provável não é ausência de referência, mas sintaxe narrativa: "Soares [@soares2005]" e "Torreblanca et al. [@torreblanca2026]" podem renderizar como duplicação do autor, dependendo do processador CSL. Em Pandoc/Quarto, o padrão mais seguro é usar citação textual do tipo `@soares2005` ou citação parentética integral.
   - **Evidência**: `01_introducao_draft.md`, linhas 7, 9 e 15; `references.bib`, entradas correspondentes.
   - **Como o autor poderia responder**: Padronizar citações narrativas antes de compilar o paper.

2. A introdução deve evitar que Torreblanca et al. pareça benchmark normativo único.
   - **Severidade**: Média.
   - **Problema**: O texto diz que Torreblanca et al. oferecem linguagem operacional e que o artigo amplia esse diagnóstico. Isso é adequado. O risco é parecer que o paper julga toda a produção brasileira por proximidade com a revolução da credibilidade. A defesa pluralista precisa permanecer junto da discussão do funil, não apenas no parágrafo anterior.
   - **Evidência**: `01_introducao_draft.md`, linhas 5, 9 e 11; `2026-07-08-paper_sintese_variaveis_finais.md`, linhas 36-43.
   - **Como o autor poderia responder**: Repetir que o funil de credibilidade é uma camada específica para artigos empíricos quantitativos/causais, não uma métrica geral de valor científico.

## Ranking de vulnerabilidades

1. **Promessa de medir explicitação e arquitetura sem variáveis disponíveis** — pode derrubar a coerência da contribuição se a introdução não for rebaixada para versão preliminar/desenho de pesquisa.
2. **Uso retórico do universo 2005-2025 apesar de só 699/5.250 PIDs classificados** — pode virar overclaiming sobre o campo.
3. **Denominação ampla demais do corpus como Ciência Política brasileira** — expõe o paper a crítica de cobertura, mesmo quando o manifest estiver completo.
4. **Número de 16 desenhos estritos sem qualificação derivada e denominador preferencial** — não derruba o paper, mas fragiliza a primeira impressão dos resultados.
5. **Risco residual de parecer ataque ao pluralismo** — parcialmente mitigado pelo texto, mas ainda depende de formulações sobre "arquitetura" e "padronização".
6. **Citações narrativas potencialmente redundantes** — problema mecânico, fácil de corrigir.

## O que sobrevive ao escrutínio

- A introdução já contém salvaguardas importantes: defende pluralismo metodológico, declara resultados preliminares, informa 699/5.250 e diz que os números não são resultados finais.
- O uso de Torreblanca et al. como lógica de funil é defensável, desde que não vire régua normativa para todo tipo de artigo.
- A ponte entre literatura nacional sobre formação/obscuridade metodológica e mensuração da prática publicada é promissora. O problema não é a ideia; é o grau de certeza que a versão atual sugere antes da classificação complementar.
- Não encontrei ausência óbvia das chaves bibliográficas citadas na introdução. A vulnerabilidade é mais de sintaxe e cautela interpretativa do que de bibliografia faltante.

## Veredito

Não aprovaria a introdução para integração ao `paper/paper.Rmd` sem revisão de cautela. Ela está próxima de uma formulação defensável, mas precisa reduzir a promessa substantiva para caber no estágio atual da evidência: corpus textual completo preservado, 699 PIDs classificados, resultados preliminares do funil disponível e duas variáveis centrais ainda pendentes de classificação complementar.
