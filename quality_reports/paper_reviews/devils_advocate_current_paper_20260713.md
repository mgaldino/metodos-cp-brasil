# Devil's Advocate Report

## Veredito executivo

**Não está pronto para submissão como teste substantivo da "revolução da credibilidade".** A versão atual é defensável como relatório intermediário de mensuração e cobertura, mas ainda não mede o seu construto central: adequação entre claim, evidência, método e condições de inferência. Ela mede presença de evidência, quantificação, inferência estatística e famílias nominais de desenho; as variáveis de explicitação metodológica e formato continuam ausentes, e o campo de claim agrega causalidade, explicação qualitativa e argumento teórico.

Há três bloqueadores antes de transformar os resultados em tese substantiva: validação humana do classificador, neutralização da mudança de modelo ao longo dos lotes e redefinição do estimando de "credibilidade". A aritmética e a disciplina de denominadores são, em geral, cuidadosas; o problema é de validade do construto e da mensuração, não de soma simples.

## Vulnerabilidade principal

O paper formula a pergunta em termos de rastreabilidade e alinhamento entre claim, evidência e método (`paper/paper.Rmd`, linhas 78--92), mas reconhece que não dispõe de `method_explicitness` nem `empirical_article_format` (linhas 90, 163 e 308). Além disso, 95,6% dos artigos empíricos recebem o rótulo amplo de claim causal **ou explicativo** (`output/tables/paper/table_3_causality_credibility.csv`, linha 3). Portanto, a distância entre 463 artigos no screen e 27 com método nominalmente estrito não demonstra desalinhamento claim--método nem qualidade da identificação; demonstra apenas que certas famílias de desenho são raras sob uma regra classificatória particular.

Se o título e a contribuição continuarem centrados em "revolução da credibilidade", um parecerista pode derrubar o argumento dizendo que a variável dependente ainda não existe.

## Bloqueadores antes de usar os achados como tese substantiva

### 1. A classificação em escala não tem validação humana suficiente para sustentar métricas substantivas

- **Severidade:** Crítica.
- **Evidência:** o próprio relatório do piloto afirma que os `tough_call` precisam de revisão humana antes de a classificação ser usada para estimar métricas substantivas e que o schema não estava pronto para escala sem auditoria (`data/processed/credibility_prompt_v3_pilot/outputs/takeaways_report_pilot_175.md`, linhas 76--98). No conjunto agora analisado, `tough_call` varia de 51,0% a 73,3% nas células dos quatro periódicos completos (`output/tables/paper/tough_call_profile.csv`, linhas 2--11). A planilha de auditoria manual existente continua sem preenchimento das colunas `manual_*`.
- **Por que ameaça o argumento:** um censo de textos não é um censo de medidas verdadeiras. Com tamanha fração de decisões marcadas como difíceis, diferenças entre periódicos e períodos podem refletir erro diferencial de classificação. Os 12 checks do audit atual validam integridade lógica, hashes e completude; não estimam acurácia, viés ou confiabilidade substantiva.
- **Resposta mínima do autor:** concluir e reconciliar auditoria humana independente de todos os `method_present == TRUE`, todos os desenhos estritos e uma amostra estratificada representativa dos demais casos, com oversampling de `tough_call`; reportar matriz de confusão/concordância por variável e por periódico/período; propagar a incerteza de classificação às proporções. Sem isso, rotular todos os resultados como **automatizados e não adjudicados**.

### 2. A comparação temporal está potencialmente confundida por mudança do classificador

- **Severidade:** Crítica.
- **Evidência:** artigos antigos de `Dados` foram classificados com GPT-5.5/xhigh (por exemplo, `data/processed/credibility_prompt_v3_integral_reading/full_corpus/run_logs/S0011-52582005000200002.stderr.log`), enquanto artigos recentes do mesmo periódico foram classificados com GPT-5.6 Sol/medium (por exemplo, `.../S0011-52582022000200205.stderr.log` e `.../S0011-52582025000200200.stderr.log`). A classificação canônica não preserva modelo, esforço, versão do runner ou data como colunas analíticas.
- **Por que ameaça o argumento:** ano e regime de classificação não são ortogonais, pois os lotes foram processados em ordem operacional, inclusive cronológica dentro dos periódicos. Logo, o crescimento temporal de empiria, screen ou inferência pode combinar mudança editorial real e mudança de modelo/prompt. O benchmark disponível mede sobretudo concordância entre modelos, não verdade humana, e registra desacordos em empiria, claim, screen e método.
- **Resposta mínima do autor:** anexar proveniência do classificador a cada PID; refazer uma amostra estratificada `periódico × período × modelo` com um único classificador congelado e adjudicação humana; estimar diferenças de classificação por regime. Se houver mudança material, reclassificar todo o suporte temporal comum com uma configuração única antes de afirmar tendência.

### 3. O constructo "revolução da credibilidade" precisa ser redefinido ou o paper precisa ser rebaixado a nota de mensuração

- **Severidade:** Crítica.
- **Evidência:** o campo de claim é positivo para 1.382/1.446 artigos empíricos (95,6%) e para 582/612 artigos somente qualitativos (95,1%) (`output/tables/paper/table_6_claim_evidence_matrix.csv`, linhas 7--8). O screen pode ser acionado por modelagem quantitativa mesmo sem claim causal, conforme `paper/paper.Rmd`, linha 157. Já o numerador "estrito" conta presença nominal de famílias como matching/weighting e DAG (`docs/credibility_method_counting_rule.md`, linhas 13--34), sem avaliar se os pressupostos de identificação são plausíveis ou se a implementação é válida.
- **Por que ameaça o argumento:** o denominador 463 não é um risk set causal claramente definido, e o numerador 27 mede adoção nominal, não credibilidade. A taxa de 5,8% não é diretamente comparável a uma taxa entre artigos quantitativos com claim causal explícito. Mais importante, um artigo que usa matching mal executado entra no numerador; um estudo qualitativo transparente e rigoroso não tem caminho positivo equivalente.
- **Resposta mínima do autor:** separar `causal_claim_explicit`, `causal_claim_implicit`, `explanatory_noncausal_claim` e `descriptive_claim`; definir antes da análise um denominador causal-quantitativo principal; renomear o resultado atual como **presença de famílias de desenho de identificação**; auditar qualidade/pressupostos em segundo estágio. Até lá, não usar "alinhamento" nem "credibilidade" como achado medido.

## Ataques por dimensão

### Lógica interna

1. **A tese anunciada é mais ampla que a evidência disponível.**
   - **Severidade:** Alta.
   - O texto diz que observa se o artigo identifica dados, explicita procedimentos e reconhece limites (`paper/paper.Rmd`, linha 78), mas nenhuma das variáveis atuais mede essas três propriedades. O paper corrige parcialmente o excesso ao admitir a lacuna, porém mantém a promessa no título, na introdução e na arquitetura do argumento.
   - **Como o autor poderia responder:** escolher entre duas versões coerentes: (a) paper interino sobre ecologias metodológicas e difusão de famílias de desenho; ou (b) paper completo sobre credibilidade, após criar as variáveis ausentes.

2. **"Claim versus desenho" é apresentado como alinhamento, mas as categorias não compartilham a mesma exigência inferencial.**
   - **Severidade:** Alta.
   - Um claim explicativo qualitativo não exige DiD, IV ou RDD. Logo, 772 artigos com claim empírico quantitativo sem desenho estrito e 583 claims empíricos sem componente quantitativo não constituem, por si, desalinhamento. A Figura 4 descreve cruzamentos; ela não testa adequação.
   - **Como o autor poderia responder:** retirar a palavra "alinhamento" e apresentar a figura como decomposição descritiva até que o tipo e a força do claim sejam classificados.

3. **A oposição entre "screen" e "desenho estrito" mistura um denominador construído pelo próprio classificador com um numerador de taxonomia.**
   - **Severidade:** Média-alta.
   - Como o screen inclui modelagem ou claim amplo, 27/463 é sensível às regras de entrada. Os mesmos 27 equivalem a 3,2% dos 833 quantitativos e 3,4% dos 799 artigos com claim empírico quantitativo. Nenhum desses denominadores é intrinsecamente correto; a escolha precisa ser teoricamente defendida e alinhada ao benchmark internacional.
   - **Como o autor poderia responder:** mostrar todas as taxas em uma tabela de sensibilidade, predefinir o denominador principal e replicar exatamente a regra de Torreblanca et al. quando alegar comparação.

### Mecanismo causal

1. **O paper descreve tendência, mas não oferece mecanismo para a mudança metodológica.**
   - **Severidade:** Média.
   - Formação, internacionalização, normas editoriais, composição disciplinar, disponibilidade de dados e mudança geracional aparecem apenas como pano de fundo. Os dados não distinguem esses mecanismos, e o paper corretamente diz que não identifica causas; ainda assim, "profissionalização" é usada como interpretação agregadora.
   - **Como o autor poderia responder:** transformar os mecanismos em hipóteses observáveis para uma etapa futura — por exemplo, mudança em instruções aos autores, composição de autoria, colaboração internacional, disponibilidade de repositórios e editorias metodológicas — sem apresentá-los como explicação atual.

2. **Diferenças entre periódicos podem ser composição, não cultura editorial.**
   - **Severidade:** Média-alta.
   - BPSR, CGPC, `Contexto Internacional` e `Dados` atendem áreas, perguntas e populações distintas. As diferenças podem ser explicadas por tema, subárea, tipo de dado, idioma, composição autoral ou período de existência, não por "ecologia editorial".
   - **Como o autor poderia responder:** usar "perfil observado no periódico", controlar/descrever composição temática e disciplinar e evitar atribuir o padrão a missão editorial sem evidência adicional.

### Evidência empírica

1. **A tendência de inferência estatística não é robusta à ponderação.**
   - **Severidade:** Alta.
   - A média com igual peso por periódico cresce de 30,3% para 32,0% e 34,9% (`output/tables/paper/period_equal_weight_profile.csv`, linhas 2--4). Mas, usando os próprios numeradores e denominadores por periódico (`period_complete_journal_profile.csv`, linhas 2--10), a taxa ponderada por artigo quantitativo é 52/138 = 37,7%, 82/224 = 36,6% e 101/260 = 38,8%. Isso é essencialmente estabilidade com leve formato em U, não aumento progressivo.
   - **Como o autor poderia responder:** reportar lado a lado médias equiponderadas e agregados por artigo; adicionar intervalos de incerteza e um modelo com efeitos fixos de periódico ou tendência por periódico. A frase de crescimento deve ser condicionada à ponderação ou retirada.

2. **A seleção dos quatro periódicos completos é operacional, não substantiva nem probabilística.**
   - **Severidade:** Alta para generalização; baixa para descrições internas.
   - O estrato inclui 1.466 artigos porque esses periódicos foram concluídos primeiro. Ele não é uma amostra representativa da área. O paper reconhece isso, o que salva as estatísticas por periódico, mas expressões como "produção brasileira", "campo" e "profissionalização metodológica" ainda aparecem em passagens interpretativas.
   - **Como o autor poderia responder:** restringir toda inferência ao nome dos quatro periódicos; explicitar que o conjunto sobrerrepresenta BPSR e `Dados` entre os periódicos completos e não inclui nenhum dos quatro periódicos ainda não iniciados. Manter resultados agregados dos 1.798 apenas como status de classificação.

3. **"Censo" transmite precisão populacional que não existe para a mensuração.**
   - **Severidade:** Média.
   - É um censo de artigos nos quatro periódicos, mas cada rótulo ainda contém erro de medida automatizado e não adjudicado. Com `tough_call` acima de 50% em quase todas as células completas, a palavra pode induzir falsa segurança.
   - **Como o autor poderia responder:** escrever "cobertura integral dos artigos, com classificação automatizada ainda sujeita a validação".

4. **O achado qualitativo de 98,2% mede clareza do objetivo, não rigor ou transparência.**
   - **Severidade:** Média.
   - O texto reconhece a limitação, mas a presença do resultado no corpo pode funcionar como substituto retórico de uma variável ausente. Objetivos claros são um threshold muito mais fraco que seleção de casos, documentação, procedimento analítico e reflexividade.
   - **Como o autor poderia responder:** manter o resultado em apêndice/descritivo e não usá-lo para equilibrar ou validar a dimensão qualitativa até existir medida comparável de explicitação.

### Escopo e generalização

1. **O título ainda sugere um domínio mais amplo que o estrato demonstrado.**
   - **Severidade:** Média-alta.
   - "Periódicos brasileiros" pode ser lido como universo nacional, embora o subtítulo diga quatro periódicos. A área coberta também combina Ciência Política, RI, Administração Pública e Ciências Sociais políticas.
   - **Como o autor poderia responder:** adotar título estritamente descritivo, por exemplo: "Práticas metodológicas em quatro periódicos brasileiros: evidência preliminar sobre a difusão de desenhos de identificação (2005--2025)".

2. **A exclusão de BJPE e Civitas é declarada, mas a fronteira do campo permanece contestável.**
   - **Severidade:** Média.
   - A justificativa de foco é plausível, porém não há regra operacional replicável que explique por que alguns periódicos de Ciências Sociais entram e esses dois saem. Um crítico pode alegar seleção por conveniência.
   - **Como o autor poderia responder:** documentar critérios predefinidos de elegibilidade por escopo, indexação, área e tipo de artigo; mostrar uma análise de sensibilidade do universo, mesmo que sem classificação substantiva desses excluídos.

### Contra-argumentos na literatura

1. **A literatura é estreita demais para sustentar um paper sobre pluralismo e credibilidade.**
   - **Severidade:** Média-alta.
   - As referências cobrem o diagnóstico brasileiro, ensino de métodos, transparência e um benchmark internacional, mas não enfrentam críticas à identificação design-based, pluralismo inferencial, pesquisa qualitativa transparente, validade externa, replicabilidade ou o risco de transformar taxonomias em rankings de qualidade.
   - **Como o autor poderia responder:** construir seção de controvérsia que delimite o que "credibilidade" significa e o que não significa, e derivar dessa discussão uma mensuração simétrica para métodos quantitativos e qualitativos.

2. **A comparação internacional é prometida, mas ainda não é realizada.**
   - **Severidade:** Média.
   - Torreblanca et al. funciona como inspiração taxonômica; o paper não mostra benchmark com denominadores harmonizados, períodos equivalentes ou intervalos comparáveis.
   - **Como o autor poderia responder:** ou retirar "comparável" e falar em adaptação conceitual, ou executar uma comparação harmonizada com regra idêntica e uma tabela explícita de diferenças de universo/schema.

## Ranking de vulnerabilidades

1. **Constructo central não observado** — pode derrubar a tese de revolução da credibilidade.
2. **Ausência de adjudicação humana apesar da alta taxa de `tough_call`** — pode invalidar as proporções e diferenças.
3. **Mudança de modelo correlacionada ao tempo/lote** — pode produzir tendência artificial.
4. **Aumento da inferência depende da ponderação escolhida** — enfraquece a principal narrativa temporal.
5. **Quatro periódicos escolhidos por completude operacional** — impede generalização para o campo brasileiro.
6. **Presença nominal de método tratada como desenho estrito** — superestima o que foi demonstrado sobre credibilidade.
7. **Literatura e benchmark internacional ainda incompletos** — reduz contribuição e posicionamento.

## Melhorias priorizadas

### Prioridade 1 — bloqueadores metodológicos

1. Congelar um schema, um prompt e um modelo; registrar a proveniência por PID.
2. Concluir auditoria humana independente e reportar erro por variável, periódico e período.
3. Separar claim causal de claim explicativo não causal e definir um risk set causal-quantitativo.
4. Tratar os 27 casos como presença nominal de famílias de desenho até auditoria de qualidade/pressupostos.

### Prioridade 2 — robustez analítica

5. Mostrar médias equiponderadas e ponderadas por artigo, além de estimativas com efeito fixo de periódico.
6. Incluir intervalos de incerteza e sensibilidade à classificação/`tough_call`.
7. Restringir comparações editoriais e temporais aos quatro/três periódicos nominalmente identificados.

### Prioridade 3 — reposicionamento do paper

8. Enquanto as variáveis faltantes não existirem, reposicionar o manuscrito como paper de mensuração e ecologias metodológicas, não como teste final da revolução da credibilidade.
9. Expandir a literatura de pluralismo, validade de desenhos, transparência qualitativa e críticas ao design-based.
10. Apresentar a comparação internacional apenas depois de harmonizar universo, período, denominadores e regras.

## O que sobrevive ao escrutínio

- A separação explícita entre o universo elegível (5.249), o corpus classificado parcial (1.798) e os quatro periódicos completos (1.466) é correta e muito melhor que tratar 34,3% como amostra nacional.
- A exclusão de BJPE e Civitas está aplicada de modo transparente à base analítica.
- O paper evita afirmar que todo artigo deva usar desenho causal e reconhece que pesquisa qualitativa não deve ser julgada por IMRaD.
- A regra que exclui regressão observacional, efeitos fixos, SEM e mediação do numerador automático reduz falsos positivos óbvios.
- A narrativa reconhece que desenhos estritos não apresentam trajetória monotônica e que as conclusões nacionais são provisórias.
- Os denominadores estão, em geral, visíveis, e a maior parte da aritmética central é internamente consistente.

Esses pontos sustentam uma versão intermediária honesta. Eles não resolvem os três bloqueadores centrais: validade da classificação, comparabilidade temporal do classificador e ausência da variável substantiva de credibilidade.

## Rechecagem após correções

Rechecagem realizada em 2026-07-13 sobre `paper/paper.Rmd`, `paper/paper.pdf`, `output/tables/paper/period_article_weight_profile.csv` e `quality_reports/paper_variable_audit/current_canonical_analysis_audit.md`.

### Veredito da rechecagem

**As correções respondem adequadamente às sobreinterpretações identificadas no primeiro parecer.** A versão está agora coerentemente posicionada como relatório intermediário de mensuração e difusão nominal de famílias de desenho. Ela não se apresenta mais como teste concluído da revolução da credibilidade. O PDF compilado contém as ressalvas substantivas e a tabela de sensibilidade; não são apenas comentários mantidos fora do manuscrito.

Isso muda o veredito editorial para: **aprovado como snapshot preliminar e auditável; continua não aprovado como teste substantivo da revolução da credibilidade**.

### Correções que passaram

1. **Reposicionamento da contribuição — PASS.**
   - O título agora delimita quatro periódicos e anuncia "mensuração preliminar da difusão de desenhos de identificação".
   - O resumo declara que os rótulos são automatizados, não integralmente adjudicados, que a configuração variou entre lotes e que o resultado não é teste final da revolução da credibilidade.
   - Introdução e conclusão usam "presença nominal", "resultados intermediários" e "rótulos automatizados ainda sujeitos a validação humana". A antiga promessa de medir diretamente credibilidade foi retirada dos achados desta versão.

2. **Sensibilidade temporal — PASS.**
   - A nova tabela reproduz corretamente a proporção agrupada por artigos: 37,7%, 36,6% e 38,8% para inferência estatística, enquanto a média com peso igual por periódico é 30,3%, 32,0% e 34,9%.
   - O texto não escolhe silenciosamente a série conveniente: afirma explicitamente que o resultado depende da ponderação e adota "estabilidade, não crescimento robusto" como conclusão prudente.
   - O audit registra as duas regras de ponderação. A Figura 6 continua mostrando a média equiponderada, mas a Tabela 5 aparece imediatamente antes e a legenda identifica a regra; portanto, a apresentação não é enganosa.

3. **Presença nominal versus qualidade de identificação — PASS.**
   - Os 27 casos são descritos como menções a famílias de desenho, não como 27 identificações válidas.
   - Resultados e conclusão dizem expressamente que a contagem não audita execução, pressupostos ou qualidade da identificação.
   - O audit incorpora a mesma limitação, reduzindo o risco de divergência entre manuscrito e documentação técnica.

4. **Risk set e claim amplo — PASS.**
   - O manuscrito afirma que o screen é exploratório, inclui claim explicativo amplo e modelagem, e não constitui risk set causal puro.
   - A antiga linguagem de "alinhamento" foi substituída por distribuição conjunta/coexistência de atributos; o texto declara que o cruzamento não testa adequação entre claim e método.

5. **Classificador e validade da mensuração — PASS como transparência, ainda não como solução.**
   - A nova seção de protocolo informa a faixa de `tough_call` de 51,0% a 73,3%, a falta de adjudicação integral, a variação de modelo/esforço e o possível confundimento temporal.
   - O paper define corretamente as tendências como diagnóstico exploratório e especifica as etapas necessárias antes de um teste substantivo.

### O que ainda bloqueia um teste substantivo

1. **Adjudicação humana e erro de medida.** Ainda é necessário adjudicar os positivos raros e uma amostra estratificada dos demais casos, reportar acurácia/concordância por variável e estrato e incorporar a incerteza de classificação às estimativas.
2. **Proveniência e invariância do classificador.** Modelo, esforço, versão do runner e prompt precisam ser consolidados por PID. O suporte temporal comum deve ser calibrado ou parcialmente reclassificado com configuração congelada para distinguir mudança editorial de mudança do classificador.
3. **Constructo causal.** O campo unido de claim causal ou explicativo precisa ser separado em causal explícito, causal implícito, explicativo não causal e descritivo. Só então pode existir um risk set causal teoricamente defensável.
4. **Credibilidade substantiva.** Presença de DiD, IV, RDD, matching ou experimento não demonstra execução válida. Os casos positivos precisam de segunda etapa que avalie pressupostos, estimação, inferência, diagnósticos e transparência.
5. **Rastreabilidade metodológica.** `method_explicitness` e `empirical_article_format` ainda não existem. Sem elas, o paper não testa a sua pergunta mais ampla sobre avaliabilidade, opacidade ou adequação entre claim e evidência.
6. **Generalização nacional.** O corpus continua parcialmente classificado e os quatro periódicos completos foram determinados pela ordem operacional. A conclusão sobre a produção brasileira requer completar os onze periódicos ou um desenho amostral explícito.
7. **Comparação internacional.** A referência a Torreblanca et al. continua conceitual. Um teste comparativo exige harmonização de universo, período, denominadores e regras de codificação.

### Resíduos editoriais não bloqueadores

- A frase de que a cobertura atual permite "resultados substantivos delimitados" poderia dizer "resultados descritivos intermediários" para ficar perfeitamente alinhada ao novo posicionamento.
- Dizer que as diferenças entre periódicos "refletem missões editoriais" ainda sugere mecanismo não observado; "são compatíveis com diferenças de missão, área e composição" seria mais preciso.
- O resumo poderia nomear explicitamente classificação por modelo de linguagem, em vez de apenas "classificados automaticamente por leitura integral".

Esses resíduos não reabrem os bloqueadores do primeiro parecer. A correção central foi bem-sucedida: o manuscrito agora distingue com clareza o que o snapshot descreve do que uma futura análise substantiva ainda precisará demonstrar.
