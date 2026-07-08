# Devil's Advocate Report: seção Conclusão

Revisão independente da seção `quality_reports/paper_drafts/07_conclusao_draft.md`, com base em `AGENTS.md`, `quality_reports/plans/2026-07-08-paper_sintese_variaveis_finais.md`, `quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md`, `quality_reports/paper_variable_audit/variable_gap_audit.md` e `output/tables/paper/denominator_summary.csv`.

## Vulnerabilidade principal

A conclusão é cuidadosamente cautelosa e explicita o limite de 699 artigos classificados em um manifest elegível de 5.250 PIDs. Ainda assim, sua vulnerabilidade principal é retórica: algumas frases continuam apresentando "padrões", "dissociação", "contribuição" e "discussão sobre a revolução da credibilidade no Brasil" como se o subconjunto já classificado autorizasse um diagnóstico substantivo do campo. O texto precisa impedir que o leitor transforme uma base de 13,3% do manifest em achado final sobre a Ciência Política brasileira entre 2005 e 2025.

## Ataques por dimensão

### Lógica interna

1. A conclusão alterna entre duas posições: "resultado preliminar do subconjunto" e "resposta à pergunta substantiva do paper".
   - **Severidade**: Alta.
   - **Problema**: A seção abre perguntando como se organiza a prática metodológica dos artigos brasileiros entre 2005 e 2025 e oferece uma "resposta preliminar" sobre a transformação metodológica da produção publicada. A própria conclusão depois reconhece que só 699 de 5.250 PIDs estão classificados e que nada autoriza inferência final sobre o corpus completo. A tensão não é fatal, mas a abertura ainda convida o leitor a ler o parágrafo como resposta substantiva ao campo, não como diagnóstico operacional do subconjunto classificado.
   - **Como o autor poderia responder**: Rebaixar a abertura para algo como "esta versão não responde ainda à pergunta substantiva; ela testa um funil e identifica riscos analíticos no subconjunto classificado". A pergunta de 2005-2025 pode permanecer, mas a resposta deve ser explicitamente adiada.

2. "Permanece limitada ou ainda não mensurada" mistura achado e ausência de mensuração.
   - **Severidade**: Alta.
   - **Problema**: A frase sobre "explicitação metodológica validada e arquitetura textual padronizada" diz que elas permanecem "limitadas ou ainda não mensuradas de modo suficiente". Para `method_explicitness` e `empirical_article_format`, a auditoria de variáveis é clara: elas não estão disponíveis no classificador atual e exigem rodada complementar. Logo, o texto não pode sugerir limitação substantiva dessas dimensões; pode dizer apenas que elas ainda não foram mensuradas de modo validado.
   - **Como o autor poderia responder**: Separar as dimensões já mensuradas das dimensões ausentes. Desenho estrito de identificação pode ser descrito como raro no subconjunto classificado; explicitação metodológica e arquitetura textual devem aparecer somente como lacunas de mensuração e hipóteses.

3. A "contribuição preliminar" ainda parece uma contribuição substantiva, não apenas uma contribuição de desenho.
   - **Severidade**: Média.
   - **Problema**: O segundo parágrafo afirma que a contribuição preliminar é deslocar o diagnóstico para a forma do artigo empírico brasileiro. Isso é intelectualmente forte, mas a forma do artigo empírico ainda depende de variáveis não classificadas. Como contribuição desta versão, o que está sustentado é mais estreito: a disciplina de funil, denominadores, regra conservadora para desenho estrito e identificação das variáveis faltantes.
   - **Como o autor poderia responder**: Formular a contribuição desta versão como "propor e auditar o desenho de mensuração" em vez de "avaliar a forma do artigo empírico". A avaliação da forma deve ficar condicionada à rodada complementar.

4. A expressão "hipótese forte" pode ser forte demais para uma cobertura de 13,3%.
   - **Severidade**: Média.
   - **Problema**: O texto diz que o funil indica "uma hipótese forte e uma direção analítica promissora". "Promissora" está correto; "forte" pode ser contestado, porque não há ainda demonstração de representatividade do subconjunto classificado. A hipótese pode ser substantivamente interessante, mas sua força empírica ainda é limitada.
   - **Como o autor poderia responder**: Trocar por "hipótese plausível", "hipótese prioritária" ou "hipótese a ser testada no corpus completo".

### Mecanismo causal

1. A conclusão evita causalidade explicativa, mas a linguagem de "transformação metodológica" sugere processo de campo.
   - **Severidade**: Média.
   - **Problema**: "Transformação metodológica da produção publicada" implica mudança histórica e processo de profissionalização. Com 4.551 PIDs ainda não classificados, o material atual não permite separar mudança temporal real de composição do subconjunto lido por periódico, período, idioma, subcampo ou facilidade de recuperação/classificação.
   - **Como o autor poderia responder**: Usar "perfil observado no subconjunto classificado" para resultados atuais e reservar "transformação metodológica" para a versão com cobertura completa e análise temporal adequada.

2. A conclusão sugere dissociação entre empiria/quantificação/claim causal e desenho de identificação, mas ainda não mostra por que essa dissociação não é artefato de composição.
   - **Severidade**: Média.
   - **Problema**: Entre os classificados, a diferença entre 568 empíricos, 324 quantitativos, 597 com claim causal ou explicativo, 147 no screen de credibilidade e 16 com desenho estrito é real dentro do denominador atual. Mas sem cobertura completa ou auditoria de representatividade, essa dissociação pode refletir quais periódicos ou períodos foram classificados primeiro.
   - **Como o autor poderia responder**: Manter a dissociação como achado descritivo do subconjunto e acrescentar que sua interpretação substantiva depende de completar a cobertura ou demonstrar que o subconjunto não é composicionalmente enviesado.

3. A relação entre baixa padronização e pluralismo ainda precisa ser protegida por critérios específicos a cada tradição.
   - **Severidade**: Média.
   - **Problema**: A conclusão afirma que preserva pluralismo e que artigos teóricos, qualitativos, históricos, interpretativos e de revisão não devem ser avaliados por régua causal quantitativa. Esse é um ponto forte. Mas a ideia de "arquitetura textual padronizada" pode ser lida como imposição indireta de um formato único, especialmente quando o plano menciona `imrad_like` como categoria central.
   - **Como o autor poderia responder**: Explicitar que padronização significa rastreabilidade mínima entre pergunta, evidência, método e inferência, não adesão universal ao IMRaD. O critério deve variar por tipo de claim e tradição metodológica.

### Evidência empírica

1. O gate de completude é uma ameaça substantiva, não apenas uma nota de cautela.
   - **Severidade**: Alta.
   - **Problema**: O Gate 0 registra `classification_covers_full_manifest` como falha: 699 classificados, 4.551 ainda não classificados e 5.250 PIDs elegíveis com texto integral disponível. A conclusão menciona isso corretamente, mas depois ainda chama os padrões do denominador parcial de "substantivamente relevantes". Essa frase é defensável como motivação, mas vulnerável como evidência, porque relevância substantiva depende de como o subconjunto foi produzido.
   - **Como o autor poderia responder**: Trocar "substantivamente relevantes" por "analiticamente relevantes para orientar a próxima rodada" ou "descritivamente relevantes no subconjunto classificado".

2. As variáveis centrais da tese ainda não existem como variáveis validadas.
   - **Severidade**: Alta.
   - **Problema**: A auditoria de variáveis diz que `method_explicitness` e `empirical_article_format` não estão disponíveis e que os `section_reading_log` não codificam sozinhos uma regra validada. Portanto, qualquer afirmação sobre baixa explicitação, opacidade, reconstruibilidade pelo leitor ou padronização textual precisa ser classificada como hipótese de pesquisa, não resultado.
   - **Como o autor poderia responder**: Criar uma barreira terminológica rígida: "achados atuais" só para variáveis já classificadas; "hipóteses e variáveis futuras" para explicitação e formato.

3. O numerador de "claim causal ou explicativo" não deve virar "linguagem causal".
   - **Severidade**: Média.
   - **Problema**: A conclusão fala em "linguagem explicativa ou causal" e depois em "claims causais". A variável disponível combina causal ou explicativo. Se o texto abreviar para causal, pode inflar a interpretação de que 597 de 699 artigos fazem claims causais, quando a categoria é mais ampla.
   - **Como o autor poderia responder**: Preservar sempre a expressão composta "causal ou explicativo" quando usar o número 597/699. Reservar "causal" estrito para designs, identificação e subdenominadores apropriados.

4. O número de 16 desenhos estritos é interpretável por denominadores diferentes.
   - **Severidade**: Média.
   - **Problema**: `denominator_summary.csv` apresenta 16 artigos com desenho estrito como 2,3% dos 699 classificados. Dentro do screen de credibilidade, 16 de 147 seria outra proporção substantiva. A conclusão usa o funil corretamente, mas precisa evitar que o leitor leia 16 como prevalência final do corpus ou como julgamento de todos os artigos empíricos.
   - **Como o autor poderia responder**: Dizer explicitamente que 16/699 mede raridade no subconjunto classificado total, enquanto qualquer leitura dentro do screen deve usar 147 como denominador e ainda permanecer preliminar.

### Escopo e generalização

1. A conclusão ainda pode ser citada fora de contexto como diagnóstico nacional.
   - **Severidade**: Alta.
   - **Problema**: Mesmo com todas as ressalvas, frases como "a discussão sobre a revolução da credibilidade no Brasil deve ser ampliada" e "a Ciência Política brasileira superou, reformulou ou preservou lacunas" criam um enquadramento nacional. O último período é condicional e seguro, mas a conclusão inteira será lida como a mensagem final do paper. Qualquer formulação nacional precisa carregar o qualificador de cobertura incompleta.
   - **Como o autor poderia responder**: Padronizar o sujeito: "no subconjunto classificado" para achados; "no corpus completo" apenas para objetivos futuros; "na Ciência Política brasileira" apenas para a pergunta e a contribuição esperada após completar a classificação.

2. A promessa de claims finais após completar 5.250 PIDs é correta, mas ainda otimista se as variáveis complementares não forem validadas.
   - **Severidade**: Média.
   - **Problema**: A conclusão diz que, após completar a classificação dos 5.250 PIDs e incorporar as duas variáveis ausentes, será possível afirmar em que medida a área superou ou preservou lacunas metodológicas. Isso é quase correto, mas falta uma condição: validação intercodificador/manual, regras estáveis e tratamento de ambiguidade. Cobertura completa sozinha não garante validade das variáveis.
   - **Como o autor poderia responder**: Condicionar claims finais não só à cobertura, mas também à validação das regras complementares de classificação e à auditoria de qualidade das codificações.

3. O pluralismo é preservado, mas ainda mais como ressalva do que como desenho analítico positivo.
   - **Severidade**: Média.
   - **Problema**: A conclusão protege artigos teóricos, qualitativos, históricos, interpretativos e de revisão contra uma régua causal quantitativa. Porém, ela ainda não diz quais critérios positivos de transparência e validade se aplicam a essas tradições. Um leitor pluralista pode aceitar a ressalva e ainda rejeitar o vocabulário guarda-chuva de "credibilidade" como excessivamente design-based.
   - **Como o autor poderia responder**: Acrescentar que transparência inferencial será operacionalizada por tipo de claim: rastreabilidade documental em pesquisa histórica, coerência conceitual em teoria, explicitação de seleção e interpretação em qualitativos, identificação em claims causais quantitativos.

### Contra-argumentos de leitores críticos

1. Um leitor cético dirá que a conclusão já sabe a tese antes de medir as duas variáveis mais importantes.
   - **Severidade**: Alta.
   - **Problema**: O plano substantivo trata `method_explicitness` e `empirical_article_format` como núcleo do paper. A conclusão reconhece que elas não existem no classificador atual, mas ainda organiza a contribuição em torno de explicitação e arquitetura textual. Esse é o ponto mais atacável por parecer uma conclusão antecipada.
   - **Como o autor poderia responder**: Reposicionar a conclusão atual como "conclusão de uma etapa de validação do desenho", não como conclusão substantiva do paper final.

2. Um leitor design-based pode aceitar o funil, mas questionar a inclusão de "claim explicativo" no mesmo bloco de "claim causal".
   - **Severidade**: Média.
   - **Problema**: A categoria composta é útil para triagem, mas pode misturar explicações narrativas, argumentos causais fortes e claims associativos. O risco é fazer o funil parecer mais causal do que ele é.
   - **Como o autor poderia responder**: Diferenciar, quando possível, claim causal estrito, claim explicativo amplo e análise descritiva. Até lá, evitar inferência causal forte a partir da categoria composta.

3. Um leitor qualitativo pode objetar que "padronização" ainda soa como normalização de formato.
   - **Severidade**: Média.
   - **Problema**: A conclusão diz que pluralismo está preservado, mas "arquitetura textual padronizada" pode ser interpretada como valorização de formato comum sobre formas legítimas de argumentação qualitativa, histórica ou interpretativa.
   - **Como o autor poderia responder**: Substituir "padronização" por "rastreabilidade funcional" quando o objetivo for pluralista, e usar "padronização" apenas para padrões de declaração mínima de dados, método e inferência.

## Ranking de vulnerabilidades

1. **Variáveis centrais ainda ausentes**: pode derrubar a tese sobre baixa explicitação e arquitetura textual se o texto a tratar como achado.
2. **Cobertura de 699/5.250**: ameaça qualquer formulação sobre o corpus completo, periódicos, períodos ou Ciência Política brasileira como um todo.
3. **Mistura entre limitação observada e dimensão não mensurada**: "limitada ou ainda não mensurada" precisa ser dividido em claims distintos.
4. **Contribuição substantiva antecipada**: a conclusão deve vender desenho, funil e validação preliminar, não diagnóstico final da forma do artigo empírico.
5. **Categoria composta causal ou explicativa**: pode inflar a leitura de causalidade se abreviada para "claim causal".
6. **Pluralismo ainda defensivo**: a conclusão nega a régua causal universal, mas poderia explicitar critérios positivos por tradição metodológica.

## O que sobrevive ao escrutínio

1. A conclusão é, no conjunto, disciplinada. Ela explicita 699 de 5.250 PIDs, 13,3% de cobertura, 4.551 PIDs sem classificação combinada e nega inferência final sobre o corpus completo.
2. A separação entre variáveis já disponíveis e variáveis ausentes está presente e é honesta, especialmente quando o texto diz que `method_explicitness` e `empirical_article_format` exigem rodada complementar.
3. A leitura do funil no subconjunto classificado é defensável: entre 699 artigos classificados, há 568 empíricos, 324 empíricos quantitativos, 597 com claim causal ou explicativo, 147 no screen de credibilidade e 16 com desenho estrito.
4. O texto preserva o pluralismo metodológico melhor do que as seções anteriores poderiam sugerir, porque afirma explicitamente que artigos teóricos, ensaísticos, qualitativos, históricos, interpretativos ou de revisão não devem ser avaliados por uma régua causal quantitativa.
5. A conclusão acerta ao definir duas condições necessárias para claims finais: completar a classificação do manifest e incorporar a rodada complementar de variáveis ausentes. O ajuste necessário é acrescentar validação explícita dessas novas codificações.

## Recomendação editorial adversarial

A conclusão deve ser mantida, mas com três travas adicionais: primeiro, transformar todos os achados atuais em "achados descritivos do subconjunto classificado por leitura integral"; segundo, remover qualquer sugestão de que baixa explicitação ou baixa padronização já foram demonstradas; terceiro, substituir formulações nacionais por hipóteses a serem testadas no corpus completo. A frase segura para esta versão é: **o material classificado até aqui valida a necessidade e a arquitetura do diagnóstico, mas ainda não entrega o diagnóstico substantivo final da Ciência Política brasileira**.
