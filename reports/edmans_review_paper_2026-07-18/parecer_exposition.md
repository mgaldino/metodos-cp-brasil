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
