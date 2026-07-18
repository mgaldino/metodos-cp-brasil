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
