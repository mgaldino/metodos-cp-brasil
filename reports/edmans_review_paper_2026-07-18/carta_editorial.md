# Carta Editorial — Framework Edmans (Contribution, Execution, Exposition)

## Decisão: Reject-and-Resubmit

## Scores consolidados

| Dimensão | Score | Rating |
|---|---:|---|
| Contribution | 4/10 | Fraca |
| Execution | 5/10 | Promissora, mas ainda insuficiente |
| Exposition | 6/10 | Adequada |
| **Global** | **5/10** | **Projeto promissor, manuscrito ainda não publicável** |

## Síntese editorial

O manuscrito tem duas forças claras: uma infraestrutura de mensuração potencialmente valiosa e uma disciplina incomum na apresentação dos denominadores e dos limites inferenciais. A principal fraqueza é que os dados ainda não constituem evidência validada sobre as práticas metodológicas efetivas: apenas 34,3% do universo foi classificado, o instrumento automatizado não foi integralmente adjudicado por humanos, sua configuração variou entre lotes de maneira associada ao tempo e as duas variáveis mais diretamente ligadas à tese de rastreabilidade ainda não existem. Essa limitação de execução reduz a força de resultados que já seriam substantivamente frágeis como contribuição para um periódico generalista de primeira linha. A exposição é a dimensão mais avançada, mas ainda apresenta o trabalho como três papers concorrentes — práticas metodológicas em geral, identificação causal e rastreabilidade — e mantém linguagem interna de controle no corpo do texto. O parecer consolidado é, portanto, de rejeição com convite a uma nova submissão somente depois de uma reconstrução substantiva, e não de uma revisão editorial incremental.

## Hierarquia Edmans aplicada

A hierarquia *contribution > execution > exposition* é decisiva neste caso. O gargalo primário é a contribuição: a versão atual oferece uma mensuração preliminar e resultados em grande medida esperados, enquanto a promessa mais distintiva — avaliar adequação entre afirmação, evidência, explicitação e formato — permanece sem as variáveis necessárias. O segundo gargalo é a execução: mesmo os resultados disponíveis dependem de um classificador ainda não validado e sujeito a mudança entre lotes. Melhorias de exposição seriam relativamente fáceis e úteis, mas não resolveriam nenhum desses dois problemas. Ainda assim, a contribuição potencial justifica continuar o projeto, porque um corpus completo, validado e teoricamente enquadrado poderia produzir um diagnóstico nacional relevante e comparável internacionalmente. O investimento recomendável não é polir esta versão; é completar e validar a mensuração, escolher uma única tese e então reescrever o paper a partir do resultado substantivo mais informativo.

## Prioridades para revisão

1. **Validar o instrumento de mensuração antes de interpretar prevalências.** Construir uma amostra humana estratificada por periódico, período, configuração do classificador e dificuldade; reportar precisão, recall e concordância por variável; adjudicar todos os 27 positivos e uma amostra informativa de negativos; e propagar a incerteza de classificação para as estimativas.
2. **Concluir o núcleo substantivo prometido.** Completar o corpus elegível, consolidar a proveniência do classificador, usar uma configuração congelada nas comparações temporais e implementar `method_explicitness` e `empirical_article_format`. Se isso não for feito, restringir explicitamente o paper às dimensões já observadas e abandonar a tese de rastreabilidade.
3. **Definir uma contribuição única e teoricamente informativa.** Escolher se o resultado central é a estabilidade da quantificação e da inferência, a raridade de estratégias explícitas ou a adequação entre afirmação e método; formular mecanismos e expectativas direcionais; e explicar por que o Brasil é um caso crítico para a literatura internacional, não apenas uma extensão geográfica.
4. **Revisar comparabilidade e consistência dos resultados.** Explicar ou corrigir as discrepâncias apontadas entre as Tabelas 2 e 4, testar definições alternativas para o subconjunto de 463 casos, padronizar comparações por uma janela temporal comum e evitar inferência temporal enquanto período e configuração do classificador estiverem confundidos.
5. **Reescrever o manuscrito como artigo, não como relatório de progresso.** Remover do corpo termos como PID, ledger, manifest, hashes, schema e caminhos de arquivos; reduzir repetições das mesmas limitações; corrigir a autoria e o alcance das referências; tornar 27/463 um resultado memorável caso sobreviva à validação; e mover figuras descritivas de menor rendimento, especialmente a Figura 7, para o apêndice.

## Recomendação estratégica ao autor

Não recomendo submeter a versão atual nem a um top journal generalista nem ainda a um periódico disciplinar brasileiro. A decisão apropriada é **Reject-and-Resubmit**, pois as mudanças necessárias envolvem novos dados, validação humana, reconciliação do instrumento e redefinição da contribuição — trabalho que excede um R&R convencional. Vale a pena continuar o projeto: uma versão completa pode ter boa adequação à *Brazilian Political Science Review*, a *Dados* ou a outro periódico interessado em métodos e desenvolvimento disciplinar; para APSR, AJPS, JOP ou IO, seria adicionalmente necessário transformar o caso brasileiro em teste de uma proposição geral sobre difusão metodológica, incentivos editoriais ou profissionalização científica. A estratégia mais produtiva é concluir a mensuração e a validação primeiro, decidir o achado central depois e só então reconstruir título, resumo, introdução e arquitetura empírica.

---

## Parecer completo — Contribution

# Parecer de Contribution (Framework Edmans)

## Score: 4/10

## Resumo da contribuição alegada

O manuscrito propõe uma mensuração reprodutível da evolução das práticas metodológicas em artigos brasileiros publicados entre 2005 e 2025, distinguindo empiria, quantificação, inferência estatística e menção a estratégias explícitas de identificação causal. A evidência atual cobre 1.798 de 5.249 artigos elegíveis, com quatro periódicos integralmente classificados, e sugere elevada presença de pesquisa empírica, forte heterogeneidade editorial e baixa frequência de estratégias explícitas de identificação entre os casos considerados relevantes.

## Avaliação por dimensão

### Novidade [Fraca]

A construção de um corpus amplo, com denominadores explícitos e leitura integral, tem potencial para gerar uma contribuição original à compreensão da Ciência Política brasileira. Contudo, os resultados atualmente demonstrados são, em grande medida, compatíveis com expectativas já presentes na literatura citada: profissionalização incompleta, desigualdade entre periódicos, distância entre quantificação e identificação e persistência de fragilidades metodológicas.

O resultado potencialmente mais informativo — somente 27 dos 463 casos relevantes mencionarem estratégia explícita de identificação — pode produzir alguma atualização de crenças. Essa atualização, entretanto, é severamente descontada porque o próprio manuscrito reconhece que o subconjunto não corresponde apenas a estudos causais, que os rótulos ainda não foram adjudicados por humanos e que diferentes lotes foram processados com configurações distintas do classificador (pp. 6 e 8). Além disso, a adaptação do esquema de Torreblanca et al. ao Brasil ainda aparece predominantemente como extensão geográfica, sem uma expectativa institucional suficientemente desenvolvida sobre por que o caso brasileiro deveria confirmar ou contrariar padrões internacionais.

As variáveis que poderiam produzir a contribuição mais nova — `method_explicitness` e `empirical_article_format` — ainda não foram construídas. Assim, a principal promessa intelectual do artigo permanece futura.

### Importância [Fraca]

A pergunta é importante para a disciplina: editores, programas de pós-graduação e associações científicas poderiam usar um diagnóstico confiável para orientar formação metodológica, padrões de transparência e práticas editoriais. Um survey sobre a evolução metodológica da Ciência Política brasileira provavelmente mencionaria uma versão final deste levantamento.

Os resultados atuais, porém, ainda não sustentam decisões. A presença nominal de uma estratégia não mede sua qualidade; a ausência não significa inadequação; a categoria de afirmação “causal ou explicativa” é deliberadamente ampla; e os quatro periódicos completos não representam toda a produção elegível. O manuscrito demonstra corretamente essas limitações, mas essa honestidade também revela que, nesta versão, ele oferece um relatório de mensuração mais do que um resultado substantivo de primeira ordem. Não está demonstrado que uma política editorial, curricular ou associativa deveria mudar com base nas contagens atuais.

### Adequação ao escopo [Questionável]

O tema é claramente pertinente à Ciência Política e tem boa adequação para a *Brazilian Political Science Review* ou outro periódico interessado na institucionalização e nas práticas da disciplina no Brasil. A relevância para uma audiência geral de APSR, AJPS, JOP ou IO, entretanto, ainda não está estabelecida.

A bibliografia contém somente cinco referências: quatro ligadas diretamente ao debate brasileiro e uma referência internacional recente. Isso oferece ancoragem temática, mas é insuficiente para demonstrar o que já se sabe internacionalmente sobre mudança metodológica, transparência, difusão de desenhos de pesquisa, profissionalização disciplinar e efeitos de incentivos editoriais. Para interessar a uma audiência mais ampla, o Brasil precisaria funcionar como caso teoricamente informativo, e não apenas como local ainda não mapeado.

### Generalizabilidade [Limitada]

As comparações mais confiáveis restringem-se a quatro periódicos — BPSR, CGPC, *Contexto Internacional* e *Dados* — e apenas três oferecem suporte temporal comum nos três períodos. Embora esses periódicos sejam substantivamente distintos, eles não autorizam inferências sobre os onze periódicos elegíveis, muito menos sobre a Ciência Política brasileira como um todo.

A fronteira do corpus também é reconhecidamente contestável, e quatro periódicos estão sem qualquer classificação. Não há ainda argumento teórico que permita transportar os padrões encontrados para periódicos não SciELO, livros, produção internacional de pesquisadores brasileiros ou outros sistemas acadêmicos. Em sua forma atual, a contribuição é um diagnóstico delimitado de ecologias editoriais específicas.

### Trade-offs [Parcial]

O manuscrito trata adequadamente um trade-off conceitual importante: maior quantificação ou maior frequência de estratégias causais não equivalem automaticamente a maior qualidade científica. A defesa explícita do pluralismo metodológico e a distinção entre rastreabilidade funcional e adesão ao formato IMRaD evitam transformar o artigo em ranking simplista de periódicos ou métodos.

Esse equilíbrio, contudo, ainda é sobretudo normativo. O artigo não mede os benefícios e custos da difusão de estratégias causais, da padronização textual ou do aumento da explicitação metodológica. Também não examina se maior formalização melhora auditabilidade ao custo de estreitar perguntas, evidências ou tradições qualitativas. Portanto, reconhece o trade-off, mas não documenta empiricamente seus dois lados.

### Hipóteses [Presentes mas vagas]

A seção “Contexto e Expectativas” apresenta quatro expectativas: desigualdade entre periódicos e períodos; relação não equivalente entre explicitação e formato; distância entre afirmações e estratégias de identificação; e heterogeneidade editorial e temporal. Elas dão alguma direção ao estudo, mas são amplas, parcialmente redundantes e fáceis de confirmar.

Falta um mecanismo teórico que explique por que determinados periódicos, subcampos ou períodos deveriam apresentar padrões diferentes. “Espera-se heterogeneidade” não constitui hipótese forte sem prever onde, em qual direção e por quais incentivos essa heterogeneidade deveria surgir. Duas expectativas centrais tampouco podem ser testadas porque as variáveis correspondentes ainda não existem. O artigo é coerentemente descritivo, mas isso limita a força de sua contribuição para um periódico generalista de primeira linha.

## Veredicto geral sobre contribution

A contribuição ainda não é suficientemente forte para publicação em um top journal. O projeto contém uma infraestrutura de dados potencialmente valiosa, boa disciplina de denominadores e uma concepção metodologicamente pluralista. Entretanto, a versão atual descreve a construção de uma mensuração incompleta e produz resultados provisórios cuja validade ainda depende de adjudicação humana, congelamento do classificador, conclusão do corpus e criação das duas variáveis mais diretamente ligadas à tese. O principal problema não é apenas que faltam observações: falta transformar o levantamento em um resultado que altere de maneira relevante o entendimento da profissionalização metodológica. Na forma atual, a decisão editorial seria rejeição, com incentivo a uma nova submissão somente após a contribuição substantiva prometida ter sido efetivamente realizada.

## Sugestões construtivas

1. Completar o corpus e realizar validação humana estratificada, reportando acurácia e concordância por variável, periódico e período. Sem validação do instrumento, as contagens raras não podem sustentar a contribuição.

2. Construir `method_explicitness` e `empirical_article_format` antes de apresentar a tese sobre rastreabilidade. Atualmente, o argumento principal está desalinhado com os resultados disponíveis.

3. Escolher um resultado central e potencialmente surpreendente. A estabilidade da quantificação e da inferência, apesar da profissionalização da área, pode produzir uma atualização de crenças mais forte que a simples raridade de desenhos causais, desde que validada.

4. Desenvolver mecanismos e hipóteses direcionais. Incentivos editoriais, internacionalização, composição por subcampo, treinamento metodológico e mudanças nas normas de transparência podem gerar previsões distintas e testáveis.

5. Transformar o Brasil em caso teoricamente informativo. Explicar quais características institucionais tornam o país um teste crítico da difusão internacional de práticas metodológicas evitaria que o artigo fosse percebido como mera extensão geográfica de Torreblanca et al.

6. Auditar uma amostra dos 27 casos positivos para distinguir menção, aplicação e identificação defensável. Essa análise aumentaria substancialmente a importância do resultado sem impor estratégias causais como padrão universal de qualidade.

7. Explicitar consequências práticas. O artigo deveria mostrar quais achados justificariam mudanças em políticas editoriais, formação de pós-graduação, transparência ou infraestrutura de reprodução — e quais não justificariam.

8. Preservar o pluralismo como elemento analítico: avaliar a adequação entre afirmação, evidência e método, e não apenas a presença de técnicas. Essa pode ser a contribuição distintiva do artigo em relação a inventários convencionais de métodos.

## Parecer completo — Execution

# Parecer de Execution (Framework Edmans)

## Score: 5/10

## Tipo de paper: Empírico

## Resumo da estratégia empírica

O manuscrito realiza uma mensuração descritiva de práticas metodológicas em artigos publicados entre 2005 e 2025, usando classificação automatizada por leitura integral. Os resultados nacionais usam 1.798 de 5.249 artigos elegíveis, enquanto as comparações editoriais se concentram em quatro periódicos integralmente classificados; tendências temporais são examinadas em três periódicos com suporte comum.

## Princípio "Dados vs. Evidência"

O manuscrito produz dados organizados e transparentes sobre os rótulos atribuídos pelo classificador, mas esses dados ainda constituem evidência limitada sobre as práticas metodológicas efetivas dos artigos. Sem validação humana, estimativas de acurácia por variável e uma configuração uniforme do classificador, não é possível saber quanto das diferenças entre períodos e periódicos reflete mudança substantiva e quanto reflete erro ou drift de mensuração.

A disciplina inferencial dos autores é um mérito importante: o texto não interpreta a presença nominal de uma estratégia como qualidade da identificação, não generaliza os 1.798 artigos para todo o corpus e não atribui causalmente diferenças aos periódicos. Assim, os dados sustentam conclusões restritas sobre cobertura e resultados do classificador; ainda não sustentam conclusões firmes sobre a difusão real de práticas de identificação causal.

## Avaliação por dimensão

#### Mensuração [Questionável]

A principal fragilidade da execução está aqui. Conceitos como “artigo empírico”, “afirmação causal ou explicativa”, “caso relevante para identificação” e “estratégia explícita” são produzidos por modelos de linguagem, mas os rótulos ainda não foram integralmente adjudicados por humanos. A proporção de casos difíceis varia entre 51,0% e 73,3% nas células periódico-período, o que torna especialmente arriscado interpretar diferenças relativamente pequenas.

Há problemas adicionais:

- “Afirmação causal ou explicativa” é uma categoria tão ampla que aparece em 85,4% dos artigos, incluindo textos não empíricos. Ela não mede pretensão causal de maneira suficientemente discriminante.
- O subconjunto de 463 casos depende de uma regra hierárquica de triagem ainda não validada. Falsos negativos nessa etapa excluem artigos antes da detecção de estratégias, produzindo possível subestimação sistemática.
- “Estratégia explícita” mede menção textual, não necessariamente emprego da estratégia. Pode haver falsos positivos por referências incidentais e falsos negativos quando o desenho é implementado sem a nomenclatura prevista.
- A classificação agrupa métodos substantivamente distintos, como experimento, RDD e pareamento, sob uma única presença nominal. Isso serve para taxonomia preliminar, mas ainda não mede credibilidade.
- As variáveis mais diretamente ligadas à tese de rastreabilidade — `method_explicitness` e `empirical_article_format` — não estão disponíveis. Portanto, a execução atual ainda não testa uma parte central da pergunta formulada.

Também existem discrepâncias que precisam ser reconciliadas. Na Tabela 4, 27 artigos com estratégia explícita e 437 sem estratégia somam 464, embora o subconjunto contenha 463 casos. Na Tabela 2, 341 artigos somente quantitativos mais 493 mistos somam 834, enquanto o número com componente quantitativo é 833. Pode haver diferenças conceituais legítimas entre as variáveis, mas elas precisam ser explicitadas e auditadas.

#### Robustez [Fraca]

A sensibilidade à regra de ponderação temporal é relevante e bem interpretada: o manuscrito mostra que a conclusão sobre crescimento da inferência muda quando se usam pesos iguais por periódico ou artigos agrupados. Isso é uma boa prática.

Contudo, faltam os testes que tratam o principal risco do estudo — erro de classificação. Não há:

- precisão, recall ou matriz de confusão contra um conjunto humano;
- validade por periódico, período e configuração de modelo;
- concordância entre classificadores ou estabilidade em reclassificações;
- sensibilidade a definições alternativas do subconjunto de identificação;
- adjudicação dos 27 positivos raros e de uma amostra de negativos;
- intervalos ou bounds que incorporem incerteza de mensuração;
- padronização temporal das comparações entre periódicos.

Os 28 checks lógicos demonstram integridade estrutural do pipeline, não validade de construto. Eles impedem categorias impossíveis ou arquivos inconsistentes, mas não mostram que os artigos foram classificados corretamente.

#### Seleção amostral [Problemas sérios]

O tamanho absoluto é suficiente para descrição, mas a cobertura não é representativa do universo nacional: 1.798 de 5.249 artigos foram classificados, com quatro periódicos não iniciados e três apenas parcialmente cobertos. Os autores reconhecem corretamente essa limitação.

Os quatro periódicos completos formam censos internos, mas não um estrato representativo da Ciência Política brasileira. Além disso, CGPC aparece somente em 2019–2025, enquanto os demais periódicos cobrem praticamente todo o intervalo. Comparações agregadas entre os quatro podem confundir diferenças editoriais com composição temporal.

Os 27 positivos são poucos para comparações desagregadas. Percentuais como 5,3%, 8,3% ou 12,0% correspondem a contagens pequenas e são altamente sensíveis a um ou dois erros de classificação.

O problema mais grave para as tendências é que a configuração do classificador variou entre lotes e a ordem dos lotes está relacionada ao período de publicação. Isso cria um confundimento direto entre tempo histórico e instrumento de mensuração. O manuscrito reconhece o problema e chama as tendências de exploratórias, mas, enquanto ele persistir, as séries não constituem evidência de mudança temporal.

#### Explicações alternativas [Bem endereçadas]

Como o estudo é explicitamente descritivo, não se exige uma estratégia de identificação causal para explicar diferenças entre periódicos ou períodos. O manuscrito é cuidadoso ao mencionar composição temática, subáreas, tipos de pergunta e políticas editoriais como interpretações concorrentes, e afirma repetidamente que o desenho não separa essas explicações.

Essa contenção evita o problema clássico de transformar correlações editoriais em efeitos causais. A limitação remanescente não é uma variável omitida causal genérica, mas a possibilidade concreta de que composição temporal, composição disciplinar e configuração do classificador produzam parte das diferenças descritivas observadas.

### Questões técnicas específicas

- **Variáveis instrumentais:** não se aplica.
- **Log(1+Y):** não se aplica.
- **Discretização:** os anos são agrupados em três períodos. O manuscrito também apresenta resultados anuais, o que reduz a preocupação, mas deveria justificar substantivamente os pontos de corte e demonstrar que as conclusões não dependem deles.
- **Incerteza de mensuração:** é a questão técnica central. Como os quatro periódicos completos são censos, intervalos amostrais convencionais não resolvem o problema. O relevante é quantificar erro de classificação e propagar essa incerteza para as prevalências.
- **Comparabilidade temporal:** não se deve interpretar tendência antes de reclassificar uma amostra estratificada — idealmente o corpus usado na análise temporal — com configuração congelada.

## Veredicto geral sobre execution

A execução é transparente, reprodutível em intenção e incomumente disciplinada quanto aos denominadores e limites inferenciais. Isso permite ao leitor tirar conclusões precisas sobre quais artigos foram processados e quais rótulos o classificador produziu. Ainda não permite, contudo, conclusões igualmente precisas sobre a prevalência real das práticas metodológicas estudadas. O instrumento de mensuração não está validado, mudou ao longo dos lotes e está associado ao período; além disso, as variáveis mais diretamente vinculadas à tese permanecem ausentes. Como relatório intermediário, o trabalho é sólido e honesto. Como artigo substantivo de top journal, necessita transformar classificação automatizada em mensuração validada antes que os dados se convertam em evidência.

## Sugestões construtivas

1. Construir uma amostra humana estratificada por periódico, período, configuração do classificador e condição de “caso difícil”, reportando precisão, recall e concordância para cada variável central.
2. Adjudicar manualmente todos os 27 positivos e uma amostra informativa de negativos, pois erros mínimos alteram substantivamente as prevalências.
3. Reclassificar uma amostra comum — ou todo o estrato temporal principal — com configuração congelada, separando mudança histórica de mudança do classificador.
4. Formalizar a regra que produz os 463 casos e testar definições mais amplas e restritas, mostrando como cada denominador altera a incidência de estratégias.
5. Corrigir ou explicar as inconsistências numéricas entre as Tabelas 2 e 4 e incorporar esses checks às validações lógicas.
6. Comparar periódicos em uma janela temporal comum ou padronizar as proporções por período, evitando que CGPC seja comparado em composição temporal distinta.
7. Implementar `method_explicitness` e `empirical_article_format` antes de apresentar conclusões sobre rastreabilidade ou padronização da pesquisa publicada.
8. Propagar a incerteza de classificação para as estimativas, mediante correção por matriz de erro, análise de sensibilidade ou bounds plausíveis.
9. Manter a redação atual que distingue menção, implementação e validade: essa separação é essencial para que a versão final não confunda dados taxonômicos com evidência de credibilidade causal.

## Parecer completo — Exposition

# Parecer de Exposition (Framework Edmans)

## Score: 6/10

## Avaliação por dimensão

### Clareza [Adequada]

#### Qualidade da escrita

A prosa é gramaticalmente sólida, os denominadores são expostos com disciplina e tabelas e figuras são numeradas e legendadas. Não identifiquei notas de rodapé nem erros frequentes de revisão. Visualmente, porém, o manuscrito ainda parece um relatório intermediário: termos como “ledger de escopo”, “manifest”, “PID”, “snapshot analítico”, “schema credibility_prompt_v3”, “CSV canônico”, “pipeline”, “hashes dos inputs” e o caminho `data/processed/excluded_journals.csv` transferem mecanismos internos de controle para a narrativa científica.

Exemplo, p. 6:

> “As variáveis foram produzidas pelo schema credibility_prompt_v3 [...] e consolidadas no CSV canônico. O pipeline verifica PID, hash do texto, schema [...]”

Sugestão:

> “Classificamos o texto integral de cada artigo com um protocolo padronizado. Verificações automáticas de consistência asseguraram a integridade estrutural dos dados, mas não substituem a validação humana.”

Os identificadores, hashes, arquivos e nomes internos devem ficar no apêndice de reprodução. Há também um problema bibliográfico objetivo: a referência de Figueiredo et al. (2019) apresenta autores incorretos. O [registro oficial da BPSR](https://brazilianpoliticalsciencereview.org/article/seven-reasons-why-a-users-guide-to-transparency-and-reproducibility/) lista Dalson Figueiredo Filho, Rodrigo Lins, Amanda Domingos, Nicole Janz e Lucas Silva, não os cinco nomes impressos no manuscrito. Esse tipo de erro sinaliza descuido editorial.

Há pequenos custos visuais: a Tabela 3 é dividida entre as páginas 7 e 8; as Figuras 3, 5 e 7 ocupam quase uma página inteira cada; e a escala cromática da Figura 3 sugere comparabilidade imediata entre percentuais construídos com denominadores distintos.

#### Significância econômica

O resumo oferece números substantivos, mas em excesso: 5.249, 1.798, 1.466, 1.446, 833, 308, 463 e 27 competem pela atenção. O resultado memorável — 27 de 463, ou 5,8% — fica enterrado. A comparação entre 49,7% de inferência estatística na BPSR e 7,2% em Contexto Internacional também é substantivamente expressiva, mas não aparece no resumo.

Sugestão para o núcleo do resumo:

> “Entre os 463 artigos nos quais o protocolo torna pertinente examinar identificação, somente 27 (5,8%) mencionam uma estratégia explícita. Entre artigos quantitativos, a presença de inferência estatística varia de 49,7% na BPSR a 7,2% em Contexto Internacional.”

O texto acerta ao não confundir inferência estatística com qualidade causal e ao lembrar que os 27 casos registram menção, não validade. Contudo, a conclusão afirma que “os resultados rejeitam uma descrição simples”, formulação forte para classificações ainda não adjudicadas. Melhor:

> “Nos quatro periódicos integralmente classificados, os resultados preliminares não sustentam uma descrição simples de ausência de empiria ou quantificação.”

#### Precisão da linguagem

A maior dificuldade é a instabilidade do objeto central. O título enfatiza “difusão de estratégias de identificação causal”; a introdução promete um diagnóstico amplo de práticas metodológicas; várias passagens apresentam “rastreabilidade funcional” como tese; mas as variáveis diretamente necessárias para medi-la ainda não existem. O leitor termina sem saber se a contribuição atual é sobre identificação causal ou se é uma versão incompleta de um paper futuro sobre explicitação metodológica.

Uma formulação mais precisa para esta versão seria:

> “Mensuramos empiria, quantificação, inferência estatística e menções a estratégias explícitas de identificação causal em quatro periódicos brasileiros, com comparações temporais em três deles.”

Outros exemplos:

- “Casos relevantes para identificação” soa como categoria substantiva autoevidente. Melhor: “artigos selecionados pelo protocolo para auditoria de identificação”, seguido de uma frase com a regra exata.
- “Outro método moderno”, na Tabela 4, é vago e normativo. Nomear os métodos ou usar “outras estratégias codificadas pelo protocolo”.
- “Ecologias editoriais e disciplinares distintas” é expressivo, mas impreciso. Melhor: “diferenças de composição temática, tradição disciplinar e política editorial que o desenho atual não permite decompor”.
- O título associa os quatro periódicos a 2005–2025, embora CGPC só contribua em 2019–2025 e as tendências temporais usem três periódicos. Isso deve ser qualificado no título ou subtítulo.

### Extensão [Longo]

#### Introdução

A introdução propriamente dita ocupa aproximadamente duas páginas e está abaixo do teto de seis. Ela contém universo, cobertura, medidas, resultado principal e limitações. O problema não é tamanho absoluto, mas duplicação com “Contexto e Expectativas”. Soares, Barberia, Albuquerque e Torreblanca, assim como o argumento sobre pluralismo, aparecem nas duas seções.

A estrutura poderia ser reduzida a:

1. Um parágrafo sobre o diagnóstico brasileiro.
2. Um parágrafo com pergunta, universo e medidas.
3. Um parágrafo com 27/463 e heterogeneidade entre periódicos.
4. Um parágrafo de diferenciação frente a Torreblanca e à literatura brasileira.

A frase “Cada artigo publicado oferece uma observação potencial desse processo” é dispensável. Também é possível suprimir da introdução a descrição detalhada das variáveis futuras `method_explicitness` e `empirical_article_format`; uma menção na seção de limitações é suficiente.

#### Notas de rodapé

Não há notas de rodapé aparentes. Esse é um ponto positivo: o argumento central não é fragmentado por apartes.

#### Extensões desnecessárias

A Figura 7, com variação anual, é a extensão menos defensável. Ela reproduz as dimensões da Figura 6, usa denominadores anuais potencialmente pequenos, não apresenta incerteza e termina com a ressalva de que as oscilações são apenas descritivas. O ganho analítico é inferior ao custo de uma página inteira. Deve ir para o apêndice.

A Figura 2, sobre cobertura, é útil para auditoria, mas pode ser condensada na Tabela 1 ou transferida ao apêndice após uma frase clara sobre os quatro periódicos completos. A Figura 5 também pode ser apresentada como gráfico menor ou tabela compacta, pois contém apenas 29 ocorrências artigo-método.

A principal redundância textual é a repetição de duas ressalvas — ausência de adjudicação humana e indisponibilidade das duas variáveis — no resumo, introdução, protocolo, resultados, discussão e conclusão. Recomendo uma frase no resumo, tratamento completo na seção de validade e uma frase na conclusão.

### Citações [Algumas problemáticas]

#### Extensão da bibliografia

A bibliografia tem apenas cinco referências e não é excessiva. Torreblanca et al. é usado de forma substantivamente pertinente como referência operacional, e Soares é corretamente apresentado como origem do diagnóstico do “calcanhar metodológico”. O problema é precisão, não volume.

#### Problemas específicos

A primeira frase da introdução atribui a Barberia, Godoy e Barboza (2014) e Figueiredo et al. (2019), conjuntamente, que a área “ampliou a formação em métodos, intensificou a circulação internacional e passou a dialogar [...] com transparência, reprodutibilidade e identificação causal”. Essa atribuição é ampla demais. [Barberia et al.](https://bib44.fafich.ufmg.br/index.php/rts/article/download/198/144) examinam a evolução do ensino de métodos nos programas de pós-graduação; Figueiredo et al. é um ensaio normativo em defesa de transparência e reprodutibilidade. Nenhum dos dois, isoladamente, sustenta toda a frase, especialmente “circulação internacional” e “identificação causal”.

Sugestão:

> “Barberia, Godoy e Barboza (2014) documentam expansão, concentração institucional e posterior estagnação na oferta de disciplinas metodológicas. Figueiredo Filho et al. (2019) defendem transparência e reprodutibilidade como condições para a avaliação coletiva da pesquisa.”

A afirmação de que Albuquerque, Mesquita e Brito (2022) “identificaram persistência de obscuridade metodológica” na apresentação pública da pesquisa também deve ser estreitada. O estudo analisa principalmente a formação metodológica em programas de pós-graduação de RI e áreas afins. Melhor:

> “Albuquerque, Mesquita e Brito (2022) analisam a formação metodológica em programas de pós-graduação de RI e discutem suas possíveis implicações para a produção publicada.”

Caso o manuscrito queira afirmar diretamente a persistência de obscuridade nos artigos publicados, deve citar os levantamentos bibliométricos que efetivamente mediram os artigos, não apenas o trabalho que os recapitula.

Além da autoria incorreta de Figueiredo et al., a bibliografia usa capitalização inglesa nos títulos em português (“Um Mapeamento Da Formação Em Métodos...”), o que deve ser uniformizado.

## Veredicto geral sobre exposition

A exposição é suficientemente clara para reconstruir dados, denominadores e limites, mas ainda não transforma a mensuração em uma contribuição editorialmente nítida. A cautela é uma virtude, porém sua repetição, somada à linguagem de pipeline e à promessa recorrente de variáveis ainda ausentes, faz o texto parecer um relatório de progresso. O problema decisivo é a competição entre três papers: um sobre práticas metodológicas em geral, outro sobre identificação causal e um terceiro sobre rastreabilidade. Uma versão de top journal deve escolher uma tese atual, colocar um resultado quantitativo memorável no centro e relegar controles operacionais e extensões descritivas ao material suplementar.

## Top 5 sugestões de melhoria

1. **Fixar uma única contribuição na abertura.** Para esta base, centrar título, resumo e introdução na mensuração de empiria, quantificação, inferência e identificação explícita em quatro periódicos; não organizar a narrativa em torno de rastreabilidade enquanto suas variáveis não existem.
2. **Fazer de 27/463 (5,8%) o resultado memorável**, acompanhado da amplitude entre periódicos, em vez de apresentar oito contagens com igual peso no resumo.
3. **Remover linguagem de infraestrutura do corpo do paper.** Substituir “ledger”, “manifest”, PID, hashes, schema, CSV e caminhos por uma descrição científica curta; preservar detalhes no apêndice reprodutível.
4. **Cortar redundâncias e extensões de baixo rendimento.** Mover a Figura 7 e, idealmente, a Figura 2 ao apêndice; concentrar as limitações de classificação em uma única subseção.
5. **Corrigir e estreitar as citações.** Reparar imediatamente a autoria de Figueiredo et al., separar o que Barberia, Albuquerque e Figueiredo realmente demonstram e uniformizar a capitalização da bibliografia.
