# Devil's Advocate Report

## Vulnerabilidade principal

A seção é conceitualmente cautelosa, mas ainda corre o risco de prometer mais do que o projeto pode sustentar neste momento. O problema central não está em uma frase isolada, e sim na combinação entre expectativas formuladas quase como diagnóstico substantivo para 2005-2025 e um Gate 0 que informa que apenas 699 de 5250 PIDs elegíveis estão classificados por leitura integral. Sem uma marcação mais forte de que se trata de hipótese orientadora e não resultado, a seção pode transformar desenho analítico em achado antes da consolidação do corpus.

## Ataques por dimensão

### Lógica interna

1. A seção oscila entre "expectativas descritivas" e afirmações que soam como resultado antecipado.
   - **Severidade**: Alta.
   - **Evidência no draft**: "A produção publicada deve mostrar sinais de ampliação..." e "espera-se observar uma distância..." aparecem como expectativas, mas a gramática é próxima de um achado esperado.
   - **Por que importa**: o plano substantivo diz que o desenho analítico só deve ser implementado depois que a base classificada elegível estiver consolidada; o Gate 0 mostra que isso ainda não ocorreu.
   - **Como o autor poderia responder**: transformar essas passagens em hipóteses condicionais e deixar claro que a seção antecipa padrões a testar, não descreve padrões já demonstrados.

2. A tese de "baixa padronização" depende de variáveis que ainda não estão plenamente disponíveis.
   - **Severidade**: Alta.
   - **Evidência no plano**: `method_explicitness` "não captura isso de forma perfeita" no classificador atual; `empirical_article_format` precisa ser construído a partir dos `section_reading_log` ou de classificação complementar.
   - **Por que importa**: a seção coloca explicitação metodológica e arquitetura textual no centro do argumento. Se essas variáveis ainda forem derivadas de forma frágil, a seção cria uma dívida empírica grande demais para uma introdução de expectativas.
   - **Como o autor poderia responder**: explicitar que essas dimensões serão medidas por classificação complementar ou por regras de derivação auditadas, e evitar apresentar "baixa padronização" como fato estabelecido antes dessa etapa.

3. O texto tenta evitar ataque ao pluralismo, mas ainda pode ser lido como preferência normativa por um formato textual específico.
   - **Severidade**: Média.
   - **Evidência no draft**: a seção diz que IMRaD não é sinônimo de qualidade e reconhece estudos qualitativos/históricos bem explicitados. Isso é bom. Mas a repetição de "padronização", "arquitetura estável" e "formato empírico" pode ainda parecer uma régua importada de artigo quantitativo.
   - **Por que importa**: um leitor qualitativo pode aceitar a crítica à opacidade, mas rejeitar a premissa de que uma arquitetura textual mais padronizada seja desejável em todos os subcampos.
   - **Como o autor poderia responder**: distinguir mais explicitamente "rastreabilidade" de "padronização formal", fazendo da primeira a exigência normativa e da segunda apenas uma dimensão descritiva.

### Mecanismo causal

1. A seção atribui plausibilidade explicativa a periódico e período, mesmo dizendo que não identifica causalmente essas diferenças.
   - **Severidade**: Alta.
   - **Evidência no draft**: "Periódicos diferem em escopo..." e "períodos diferem na disponibilidade de treinamento..." são mecanismos plausíveis, mas ainda não testados pelo desenho descrito.
   - **Por que importa**: o texto se protege ao dizer que não identifica causalmente por que as diferenças ocorrem, mas logo antes fornece explicações substantivas para essas diferenças. Isso pode induzir leitura causal indireta.
   - **Como o autor poderia responder**: reformular esses trechos como razões para estratificar a descrição, não como explicações dos padrões observados.

2. A periodização 2005-2011, 2012-2018 e 2019-2025 carrega uma narrativa de difusão metodológica que pode virar mecanismo não identificado.
   - **Severidade**: Média.
   - **Evidência no plano**: o terceiro período é descrito como momento em que práticas internacionais estão mais disponíveis; o draft ecoa essa ideia ao falar em software, bases, transparência e circulação de convenções.
   - **Por que importa**: disponibilidade não implica adoção, e adoção não implica efeitos sobre formato textual ou identificação causal. Sem evidência externa ou desenho específico, período deve ser dimensão descritiva, não explicação.
   - **Como o autor poderia responder**: tratar os períodos como conveniência analítica e contraste histórico, evitando linguagem de mecanismo salvo quando houver evidência adicional.

3. O argumento sobre "profissionalização seletiva" pressupõe um processo de mudança que o desenho atual pode apenas descrever.
   - **Severidade**: Média.
   - **Evidência no draft**: a seção espera "ampliação da pesquisa empírica, da quantificação e da linguagem inferencial" com distribuição desigual.
   - **Por que importa**: se a classificação final for transversal por artigos publicados, o paper pode mostrar associação temporal e heterogeneidade, mas não demonstrar profissionalização como processo causal.
   - **Como o autor poderia responder**: reservar "profissionalização" para enquadramento de literatura e usar termos mais observacionais nos resultados: composição do corpus, frequência de práticas, distribuição por periódico/período.

### Evidência empírica

1. O maior risco empírico é a incompletude do corpus classificado.
   - **Severidade**: Crítica.
   - **Evidência no Gate 0**: 5250 PIDs elegíveis; 699 classificados com leitura integral no manifest; 4551 ainda sem classificação combinada; falha explícita em `classification_covers_full_manifest`.
   - **Por que importa**: a seção fala da produção brasileira entre 2005 e 2025. Com 13,3% do manifest classificado, qualquer frase que antecipe padrões gerais precisa ser marcada como preliminar ou condicionada à classificação completa.
   - **Como o autor poderia responder**: inserir uma trava textual forte: enquanto o corpus completo não estiver classificado, as expectativas não devem ser apresentadas como evidência do campo.

2. A seção promete denominadores corretos, mas não resolve o problema de denominadores efetivamente disponíveis.
   - **Severidade**: Alta.
   - **Evidência no draft**: o parágrafo final lista denominadores corretos; o Gate 0 fornece denominadores apenas para o subconjunto classificado.
   - **Por que importa**: "corpus completo elegível" é um denominador retórico se as variáveis centrais ainda só existem para classificados. O leitor precisa saber se as tabelas serão finais ou preliminares.
   - **Como o autor poderia responder**: separar denominadores conceituais de denominadores atualmente observáveis e declarar que resultados substantivos só serão finais quando houver cobertura integral.

3. As variáveis ausentes são vulnerabilidade direta, não detalhe operacional.
   - **Severidade**: Alta.
   - **Evidência no plano**: `sample_or_data_source_present` precisa de regra explícita; `claims_statistical_significance` e `specifies_estimate_equations` precisam ser avaliadas antes de uso; `method_explicitness` e `empirical_article_format` podem exigir rodada complementar.
   - **Por que importa**: a seção depende exatamente dessas dimensões para sustentar a contribuição brasileira além de Torreblanca. Se elas forem instáveis, a contribuição distintiva fica menos auditável que o funil importado.
   - **Como o autor poderia responder**: anexar uma matriz variável-fonte-regra-status antes de transformar a seção em texto do paper, e qualificar toda dimensão ainda não validada.

4. A regra conservadora sobre métodos de credibilidade é correta, mas cria risco de falso negativo substantivo.
   - **Severidade**: Média.
   - **Evidência no draft**: regressão observacional, SEM, mediação causal e efeitos fixos só contam com identificação explícita e defesa de pressupostos.
   - **Por que importa**: a regra evita inflar a revolução da credibilidade, mas pode ser contestada por autores que usam desenhos observacionais com argumento causal verbal, mesmo sem rótulo design-based. O paper precisa distinguir "não é método de credibilidade estrito" de "não tem valor explicativo".
   - **Como o autor poderia responder**: manter duas camadas: presença de claim/modelagem explicativa e presença de desenho estrito. Isso reduz disputa normativa sobre o corte.

### Escopo e generalização

1. O escopo declarado é amplo demais para o estado atual da base.
   - **Severidade**: Crítica.
   - **Evidência no draft**: a seção apresenta a produção brasileira em Ciência Política, Relações Internacionais e Administração Pública entre 2005 e 2025 como universo substantivo; o Gate 0 exige rotular resultados como preliminares.
   - **Por que importa**: mesmo uma seção de contexto pode induzir o leitor a esperar resultados finais. Se a versão atual do paper usar dados parciais, o escopo precisa ser explicitamente preliminar desde o enquadramento.
   - **Como o autor poderia responder**: acrescentar linguagem de fase do projeto ou adiar afirmações de escopo amplo até a classificação completa.

2. Há risco de usar Torreblanca como molde único apesar da negação explícita.
   - **Severidade**: Média.
   - **Evidência no draft**: o texto afirma que Torreblanca é benchmark operacional, não molde único. Ainda assim, o funil Torreblanca organiza a camada comparável, os denominadores e boa parte da expectativa sobre credibilidade.
   - **Por que importa**: a contribuição brasileira pode ficar parecendo uma adaptação local de um funil externo, com a camada de explicitação metodológica adicionada depois.
   - **Como o autor poderia responder**: inverter a hierarquia argumentativa: partir da literatura brasileira sobre calcanhar/obscuridade metodológica e apresentar Torreblanca como uma ferramenta limitada para a subdimensão causal-quantitativa.

3. O texto ainda precisa proteger melhor os artigos qualitativos, históricos e interpretativos contra classificação depreciativa indireta.
   - **Severidade**: Média.
   - **Evidência no draft**: há defesa explícita do pluralismo, mas o problema é definido por falta de método, fonte, estratégia e limites inferenciais.
   - **Por que importa**: em tradições interpretativas, "método" e "estratégia analítica" podem aparecer com vocabulário menos padronizado. Um classificador rígido pode confundir estilo de escrita com opacidade.
   - **Como o autor poderia responder**: explicitar que a classificação deve reconhecer equivalentes funcionais, não apenas cabeçalhos formais ou vocabulário quantitativo.

### Contra-argumentos prováveis

1. "O paper mede conformidade com convenções internacionais, não qualidade metodológica."
   - **Severidade**: Alta.
   - **Por que importa**: mesmo com a cautela textual, os termos "fronteira internacional", "revolução da credibilidade" e "arquitetura estável" podem ser lidos como régua normativa.
   - **Como o autor poderia responder**: repetir que o paper mede legibilidade, rastreabilidade e alinhamento a convenções específicas, não qualidade científica total.

2. "O artigo confunde ausência de seções formais com ausência de método."
   - **Severidade**: Alta.
   - **Por que importa**: essa crítica atacaria a validade das variáveis de arquitetura textual.
   - **Como o autor poderia responder**: validar manualmente uma amostra de qualitativos/históricos e demonstrar que o classificador captura explicitação funcional mesmo quando não há seção chamada "Método".

3. "Periódicos e períodos estão sendo tratados como explicação sem identificação."
   - **Severidade**: Média.
   - **Por que importa**: essa crítica é previsível porque o texto lista diferenças de escopo, tradição editorial, treinamento, software e circulação internacional.
   - **Como o autor poderia responder**: manter periódico e período como estratos descritivos e evitar linguagem de causa, mecanismo ou difusão nos resultados.

## Ranking de vulnerabilidades

1. **Cobertura incompleta do corpus**: pode derrubar qualquer leitura substantiva geral sobre 2005-2025 se a versão atual não for explicitamente preliminar.
2. **Variáveis centrais ainda não consolidadas**: ameaça a contribuição distintiva do paper, que depende de explicitação metodológica e arquitetura textual.
3. **Hipóteses formuladas como achados esperados**: enfraquece a separação entre teoria, expectativa e resultado.
4. **Torreblanca como organizador dominante**: pode reduzir a originalidade do diagnóstico brasileiro e reforçar uma régua externa estreita.
5. **Periodização e periódico como quase-mecanismos**: risco de causalidade indevida, mesmo com disclaimer.
6. **Pluralismo protegido, mas ainda vulnerável**: há boa defesa textual, mas o vocabulário de padronização pode ser contestado.

## O que sobrevive ao escrutínio

A seção não é um ataque frontal ao pluralismo. Ela afirma explicitamente a legitimidade de ensaios teóricos, estudos qualitativos, análises interpretativas, revisões e trabalhos históricos. Também acerta ao separar quantificação, causalidade, identificação estrita e transparência inferencial; essa decomposição é a melhor defesa contra overclaiming.

O uso de Torreblanca como benchmark operacional é defensável se permanecer secundário à literatura brasileira e limitado à camada causal-quantitativa do funil. A regra conservadora para SEM, mediação causal, regressão observacional e efeitos fixos também é metodologicamente defensável, desde que o paper mantenha uma categoria separada para modelagem explicativa sem desenho estrito.

O parágrafo final é a parte mais segura da seção: ele explicita denominadores e impede a inferência automática de que poucos desenhos estritos significam fragilidade metodológica ampla. O problema é que essa cautela precisa migrar para toda a seção e para a versão compilável, especialmente enquanto o Gate 0 indicar que a classificação cobre apenas uma fração do manifest elegível.
