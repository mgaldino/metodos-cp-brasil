# Devil's Advocate Report: seção Discussão

Revisão independente da seção `quality_reports/paper_drafts/06_discussao_draft.md`, com base em `AGENTS.md`, `quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md`, `quality_reports/paper_variable_audit/variable_gap_audit.md` e `output/tables/paper/denominator_summary.csv`.

## Vulnerabilidade principal

A discussão é mais cautelosa do que um draft típico, mas ainda corre o risco de transformar um subconjunto parcialmente classificado em diagnóstico substantivo da "transformação metodológica da Ciência Política brasileira". O ponto crítico não é a ausência de disclaimers: o texto repete que os resultados são preliminares. A vulnerabilidade é que alguns substantivos, verbos e enquadramentos ainda sugerem processo de campo, tendência temporal e perfis de periódico quando a cobertura atual é de 699 de 5.250 PIDs elegíveis, isto é, 13,3% do manifest, com 4.551 PIDs ainda sem classificação combinada.

## Ataques por dimensão

### Lógica interna

1. O argumento oscila entre "subconjunto classificado" e "Ciência Política brasileira".
   - **Severidade**: Alta.
   - **Problema**: O draft abre afirmando que os resultados preliminares sugerem como entender a "transformação metodológica da Ciência Política brasileira", mas a auditoria Gate 0 diz que a classificação ainda não cobre o manifest completo e que qualquer manuscrito deve rotular resultados como preliminares. A frase inicial cria uma ambição substantiva de campo que o próprio denominador não sustenta.
   - **Como o autor poderia responder**: Reancorar toda formulação agregada no universo efetivamente observado: "no subconjunto classificado até aqui" e "como hipótese sobre o corpus completo, ainda a ser testada". Reservar "Ciência Política brasileira" para perguntas, não para inferências.

2. A linguagem de "expansão", "transformação" e "profundidade" pressupõe uma dinâmica que a base parcial ainda não identifica.
   - **Severidade**: Alta.
   - **Problema**: A discussão fala em alcance e profundidade avançando em ritmos diferentes e em dissociação entre expansão empírica/explicativa e incorporação profunda de desenhos de identificação. Mesmo com cautelas, isso interpreta contagens parciais como trajetória. O corpus classificado pode estar captando composição de periódicos, janelas temporais e subcampos, não transformação do campo.
   - **Como o autor poderia responder**: Trocar linguagem processual por linguagem descritiva: "coexistem, no subconjunto classificado, alta frequência de empiria/claims explicativos e baixa frequência de desenhos estritos". Só usar "expansão" ou "avanço" depois da cobertura completa ou com desenho explícito de comparação temporal.

3. O draft reconhece a lacuna das variáveis centrais, mas ainda usa essa lacuna como ponte para a contribuição.
   - **Severidade**: Alta.
   - **Problema**: A tese mais interessante do texto é sobre explicitação metodológica e arquitetura textual, mas `method_explicitness` e `empirical_article_format` não estão disponíveis no classificador atual. O draft admite isso, mas em seguida afirma que a base parcial mostra a relevância dessa agenda. Essa é uma inferência plausível, mas não demonstrada: contar métodos e desenhos estritos mostra que a pergunta é possível, não que opacidade ou baixa padronização sejam substantivamente prováveis.
   - **Como o autor poderia responder**: Separar com mais força "achado" de "motivação para nova rodada". A base atual justifica a necessidade de medir arquitetura textual, mas não fornece evidência direta sobre sua distribuição.

4. A categoria "claim causal ou explicativo" pode ser lida como mais causal do que é.
   - **Severidade**: Média.
   - **Problema**: O denominador combina claim causal e claim explicativo. Quando a discussão aproxima essa variável de "vocabulário causal", o leitor pode inferir que 85,4% dos classificados fazem claims causais. Isso excede a variável.
   - **Como o autor poderia responder**: Manter sempre a expressão composta "causal ou explicativo" e evitar abreviações como "linguagem causal" quando o número for 597/699.

### Mecanismo causal

1. O texto quase evita causalidade, mas ainda sugere que período recente pode explicar maior presença da agenda metodológica.
   - **Severidade**: Alta.
   - **Problema**: A frase de que os padrões temporais são "substantivamente importantes" porque sugerem que a agenda metodológica contemporânea pode estar mais presente nos anos recentes flerta com uma interpretação temporal. O próprio draft reconhece que parte da variação pode refletir composição de periódicos, subcampos e janelas classificadas. Dado que só 13,3% do manifest está classificado, essa ressalva precisa dominar a interpretação, não aparecer depois do ganho substantivo.
   - **Como o autor poderia responder**: Apresentar as diferenças temporais como diagnóstico de risco amostral e guia de priorização da classificação, não como evidência substantiva de mudança temporal.

2. A heterogeneidade por periódico é tratada como eixo analítico central antes de ser isolada de composição.
   - **Severidade**: Alta.
   - **Problema**: O draft diz que o periódico individual deve permanecer como eixo central da análise. Isso é defensável como estratificação, mas perigoso como interpretação, porque periódico pode estar confundido com subcampo, idioma, escopo editorial, período coberto, tipo de artigo e velocidade de classificação. O texto nega ranking substantivo, mas ainda pode induzir leitura de "perfil metodológico do periódico" como atributo editorial.
   - **Como o autor poderia responder**: Dizer que periódico deve ser usado como variável de bloqueio, estratificação e auditoria de cobertura, não como explicação. Qualquer inferência sobre perfil editorial deve esperar cobertura completa ou ajuste por composição.

3. A relação entre revolução da credibilidade e "profundidade" pode importar uma hierarquia causal indevida.
   - **Severidade**: Média.
   - **Problema**: Mesmo preservando pluralismo, a discussão usa "profundidade" para se referir a desenhos de identificação e credibilidade inferencial. Isso pode ser lido como se design-based causal inference fosse metodologicamente mais profundo em geral, e não apenas mais apropriado para certos claims causais.
   - **Como o autor poderia responder**: Substituir "profundidade" por "aderência a padrões de identificação causal quando o claim demanda esse padrão". Isso preserva a crítica sem transformar pluralismo em concessão retórica.

### Evidência empírica

1. O principal problema empírico é a cobertura parcial, não apenas a necessidade de rótulo "preliminar".
   - **Severidade**: Alta.
   - **Problema**: O Gate 0 registra uma falha direta: `classification_covers_full_manifest`. A tabela de denominadores mostra 699 artigos classificados por leitura integral e 4.551 ainda não classificados. Esse desequilíbrio não é um detalhe de apresentação; ele ameaça todas as proporções se o subconjunto classificado não for representativo do manifest.
   - **Como o autor poderia responder**: Exigir que cada conclusão substantiva seja reescrita com o denominador explícito e com uma frase de não representatividade, quando aplicável. Em especial, não transformar percentuais do subconjunto em traços do campo.

2. As porcentagens de desenho estrito dependem de dois denominadores com interpretações diferentes.
   - **Severidade**: Média.
   - **Problema**: "16 artigos com desenho estrito" equivale a 2,3% dos classificados e 10,9% do screen de credibilidade. A primeira proporção pode subestimar a adoção entre artigos para os quais a comparação é aplicável; a segunda pode superestimar se o screen ainda for parcial e composicionalmente enviesado. O texto apresenta ambas, mas precisa proteger o leitor contra conclusões normativas fáceis.
   - **Como o autor poderia responder**: Explicar que 2,3% mede raridade no subconjunto classificado total, enquanto 10,9% mede incidência dentro de artigos comparáveis ao debate da credibilidade. Nenhuma das duas é, ainda, prevalência do corpus completo.

3. Modelagem e inferência estatística aparecem no draft sem estarem no resumo de denominadores fornecido para esta revisão.
   - **Severidade**: Média.
   - **Problema**: O draft reporta 117 artigos com modelagem estatística e 104 com inferência estatística. Esses números podem estar corretos em outro artefato, mas não aparecem em `denominator_summary.csv` nem nas duas auditorias lidas para esta revisão. Para uma seção que depende de disciplina de denominadores, os números deveriam ser rastreáveis em tabela ou auditoria adjacente.
   - **Como o autor poderia responder**: Garantir que a versão compilável cite tabela/artefato que contenha esses denominadores ou mover esses números para uma formulação menos numérica até a trilha de auditoria estar explícita.

4. A tese sobre opacidade metodológica depende de variáveis ainda inexistentes.
   - **Severidade**: Alta.
   - **Problema**: A auditoria de variáveis é inequívoca: `method_explicitness` e `empirical_article_format` exigem classificação complementar, e `section_reading_log` não codifica sozinho uma regra validada. Logo, qualquer afirmação sobre baixa explicitação, baixa padronização, arquitetura textual ou reconstruibilidade pelo leitor deve permanecer fora da zona de resultados.
   - **Como o autor poderia responder**: Criar uma barreira retórica clara: "O estudo ainda não mede X; portanto, X é a hipótese que motiva a próxima etapa, não um achado desta versão."

### Escopo e generalização

1. O draft ainda pode ser lido como diagnóstico do campo, apesar de negar conclusão final.
   - **Severidade**: Alta.
   - **Problema**: Expressões como "a produção analisada", "a área classificada" e "trajetória da Ciência Política brasileira" reduzem a tensão, mas não eliminam o problema. A unidade amostral real é "artigos já classificados por leitura integral e presentes no manifest". Sem amostragem aleatória ou cobertura completa, generalizações para área, campo ou trajetória nacional devem ser tratadas como hipótese.
   - **Como o autor poderia responder**: Padronizar a nomenclatura do universo observado e reservar termos de campo para objetivos de pesquisa e agenda futura.

2. O pluralismo é afirmado, mas a régua de avaliação ainda pode parecer importada do debate causal quantitativo.
   - **Severidade**: Média.
   - **Problema**: A passagem sobre pluralismo é forte e necessária. Ainda assim, se o vocabulário dominante da discussão continuar sendo "credibilidade", "profundidade" e "desenho estrito", leitores qualitativos, históricos ou interpretativos podem entender que seus métodos entram como exceções toleradas, não como tradições com critérios próprios de validade.
   - **Como o autor poderia responder**: Formular critérios de avaliação por tipo de claim: transparência documental para pesquisa histórica, rastreabilidade interpretativa para análise qualitativa, coerência conceitual para teoria, identificação para claims causais. Isso faz o pluralismo operar analiticamente, não apenas defensivamente.

3. Qualis, gênero e sociologia do campo estão corretamente secundarizados, mas a discussão deve evitar prometer mais do que a base permitirá.
   - **Severidade**: Baixa.
   - **Problema**: O draft é prudente ao tratar esses eixos como exploratórios. A vulnerabilidade é que, se aparecerem depois como explicações substantivas, o texto precisará de regras de inferência próprias, especialmente para gênero por nome e Qualis como marcador institucional agregado.
   - **Como o autor poderia responder**: Manter essas dimensões como heterogeneidade descritiva e nunca como mecanismo causal de preferência metodológica sem desenho específico.

### Contra-argumentos e leitores críticos

1. Um leitor cético dirá que a discussão já sabe a conclusão antes de medir a variável principal.
   - **Severidade**: Alta.
   - **Problema**: O paper quer avançar de métodos causais modernos para forma do artigo empírico, mas a forma do artigo empírico ainda não foi classificada. A resposta "isso é agenda futura" é correta, mas então a seção Discussão precisa reduzir a ambição interpretativa da contribuição atual.
   - **Como o autor poderia responder**: Apresentar a contribuição desta versão como "desenho validado de classificação e primeiros resultados do funil", não como diagnóstico da forma do artigo empírico brasileiro.

2. Um leitor design-based pode objetar que o screen de credibilidade está sendo usado para duas coisas diferentes.
   - **Severidade**: Média.
   - **Problema**: O screen aparece como comparabilidade com a revolução da credibilidade e como evidência da lacuna inferencial brasileira. Essas são funções diferentes. Se o screen delimita onde a comparação é aplicável, ele não deve simultaneamente condenar artigos fora do screen.
   - **Como o autor poderia responder**: Separar claramente: fora do screen, a pergunta é adequação entre claim e evidência; dentro do screen, a pergunta é presença de desenho de identificação.

3. Um leitor pluralista pode aceitar a crítica à baixa explicitação, mas rejeitar "credibilidade" como linguagem guarda-chuva.
   - **Severidade**: Média.
   - **Problema**: "Credibilidade" pode soar como importação de um padrão causal quantitativo para toda a produção empírica. Isso cria resistência desnecessária ao argumento mais defensável, que é sobre rastreabilidade entre evidência, método, resultados e inferência.
   - **Como o autor poderia responder**: Usar "credibilidade inferencial" apenas quando o claim for causal/explicativo e "avaliabilidade" ou "rastreabilidade" quando a discussão abranger tradições metodológicas distintas.

## Ranking de vulnerabilidades

1. **Generalização a partir de cobertura de 13,3%**: pode derrubar qualquer conclusão sobre a trajetória da Ciência Política brasileira se o subconjunto classificado for composicionalmente enviesado.
2. **Tese textual sem variável textual**: enfraquece a contribuição mais original, porque `method_explicitness` e `empirical_article_format` ainda não existem no classificador validado.
3. **Interpretação temporal confundida por periódico, subcampo e cobertura**: torna arriscadas frases sobre maior presença da agenda metodológica nos anos recentes.
4. **Heterogeneidade por periódico como quase-explicação**: pode ser lida como efeito editorial ou ranking metodológico sem identificação.
5. **Hierarquia implícita contra pluralismo**: termos como "profundidade" podem subordinar tradições qualitativas, históricas e interpretativas ao ideal de identificação causal.
6. **Ambiguidade de "claim causal ou explicativo"**: pode inflar a leitura de linguagem causal se a variável composta for abreviada indevidamente.

## O que sobrevive ao escrutínio

1. A seção acerta ao não dizer que a área é avessa à empiria, quantificação ou explicação. Dentro dos 699 classificados, os denominadores sustentam que 568 são empíricos, 324 são empíricos quantitativos e 597 têm claim causal ou explicativo.
2. A distinção entre presença de empiria/quantificação/claim explicativo e presença de desenho estrito é defensável, desde que apresentada como achado do subconjunto classificado.
3. A exclusão conservadora de SEM, mediação causal, regressão observacional e efeitos fixos do numerador de desenho estrito, salvo com discussão explícita de identificação, é metodologicamente sólida.
4. O draft já protege pontos importantes: reconhece a cobertura parcial, evita ranking substantivo de periódicos, secundariza Qualis/gênero e afirma pluralismo metodológico.
5. A agenda complementar para `method_explicitness` e `empirical_article_format` é correta e necessária. O problema não é a agenda, mas qualquer formulação que a trate como resultado antes da codificação validada.

## Recomendação editorial adversarial

Manter a discussão, mas baixar um nível a ambição interpretativa de todas as frases agregadas. A versão atual deve ser defendida como discussão de um estágio piloto ampliado de classificação por leitura integral, não como diagnóstico substantivo do campo. A fórmula segura é: **achado atual = funil descritivo no subconjunto classificado; hipótese futura = opacidade, padronização e arquitetura textual no corpus completo; inferência temporal/periódico = apenas exploratória até cobertura completa ou ajuste por composição**.
