# Revisão de Literatura: Credibilidade, Gênero e Escrita Acadêmica

Data: 2026-06-03

Status: mapa inicial de literatura para orientar o paper. Não é ainda uma revisão sistemática exaustiva.

## 1. Visão Geral

O paper deve ser posicionado na interseção de três literaturas. A primeira é a literatura internacional sobre a "revolução da credibilidade", que descreve a passagem de modelos associacionais para desenhos de pesquisa com identificação causal explícita, transparência e práticas de reprodutibilidade. A segunda é a literatura brasileira e latino-americana sobre formação metodológica, "calcanhar metodológico", "obscuridade metodológica" e desigualdades internas da Ciência Política. A terceira é a literatura sobre gênero, autoria, coautoria, citações e formas de escrita acadêmica.

A contribuição potencial do paper é tratar método e escrita como dimensões sociologicamente distribuídas da produção científica. A pergunta não deve ser apenas se a Ciência Política brasileira ficou "mais causal" ou "mais quantitativa", mas quem publica quais tipos de trabalho, em quais periódicos, com quais formatos textuais, e se a sofisticação metodológica opera também como mecanismo de distinção no campo.

## 2. Trabalhos Seminais

| Autor(es) | Ano | Foco | Argumento/Achado Relevante | Uso no Paper |
|---|---:|---|---|---|
| Angrist & Pischke | 2010 | Credibility revolution em Economia | A credibilidade empírica passa a depender de desenho de pesquisa e identificação causal, não só de especificação estatística. | Base conceitual internacional para definir "revolução da credibilidade". |
| Torreblanca, Dinneen, Grossman & Xu | 2026 | Ciência Política internacional | Classificam dezenas de milhares de artigos com LLMs e mostram crescimento seletivo de desenhos design-based, práticas de transparência ainda raras e concentração em top journals/instituições. | Principal benchmark comparativo do projeto. |
| Soares | 2005 | Ciência Política brasileira | Diagnóstico do "calcanhar metodológico": fragilidade na formação e uso de métodos na CP brasileira. | Ponto de partida nacional. |
| Barberia, Godoy & Barboza | 2014 | Ensino de métodos no Brasil | Mostram avanço na oferta de disciplinas de métodos em PPGs, mas com concentração institucional e estagnação relativa na média de disciplinas. | Mecanismo institucional: difusão metodológica desigual. |
| Albuquerque, Mesquita & Brito | 2022 | RI e áreas afins no Brasil | "Obscuridade metodológica": poucos artigos explicitam técnicas de pesquisa; métodos aparecem nos currículos, mas isso não elimina a opacidade metodológica. | Ponte entre RI e CP; útil para `method_status`. |
| Figueiredo et al. | 2019 | Transparência e reprodutibilidade | Defendem abertura de dados, scripts e materiais de replicação como bens públicos científicos. | Justifica o pipeline reprodutível do repo. |
| Teele & Thelen | 2017 | Gênero em periódicos de CP | Mulheres são sub-representadas em top journals, não se beneficiam igualmente da coautoria e estão mais presentes em trabalhos qualitativos. | Base internacional para cruzar gênero, método e tipo de publicação. |
| Djupe, Smith & Sokhey | 2019 | Submissão/publicação por gênero | Diferenças de submissão, especialização metodológica e retornos desiguais da coautoria ajudam a explicar o gap. | Impede interpretar publicação apenas como "preferência" temática. |
| Maliniak, Powers & Walter | 2013 | Citações em RI | Artigos de mulheres são menos centrais e menos citados, mesmo controlando diferenças observáveis. | Conecta gênero a reconhecimento e impacto. |
| Candido, Feres Jr. & Campos | 2019 | Elite da CP brasileira | A CP brasileira apresenta assimetrias de gênero e severa desigualdade racial entre docentes de PPGs; é mais desigual que Sociologia e Antropologia nas dimensões analisadas. | Fundamenta a análise nacional de gênero/posição. |
| Candido | 2021/2023 | História disciplinar e gênero | A narrativa dominante da institucionalização da CP brasileira subestima mulheres e invisibiliza desigualdades de gênero. | Ajuda a enquadrar gênero como problema de construção do campo. |
| Hyland | 2015 | Gênero textual e disciplina | Gêneros acadêmicos codificam expectativas comunitárias, identidade disciplinar e formas de posicionamento. | Base para tratar formato de escrita como objeto sociológico. |
| Plavén-Sigray et al. | 2017 | Readability científica | A legibilidade de textos científicos diminui ao longo do tempo, associada ao aumento de jargão científico. | Justifica medir legibilidade/estilo, com cautela. |
| Gartenberg et al. | 2026 | IA, escrita e revisão por pares | Em `Organization Science`, submissões cresceram após ChatGPT e a qualidade de escrita medida por readability caiu; autores alertam contra usar detecção automática como gatekeeper. | Referência recente para seção sobre escrita acadêmica e IA. |

## 3. Debates Centrais

### Debate 1: Revolução, reforma parcial ou distinção de elite?

A literatura internacional mais otimista vê a credibilidade como avanço metodológico: melhores desenhos, menos dependência de modelos frágeis, mais transparência. A literatura crítica ressalta seletividade: a revolução é concentrada em periódicos e instituições de maior prestígio, pode estreitar agendas substantivas e pode transformar método em marcador de status.

Para este paper, a hipótese mais forte não é "o Brasil aderiu ou não aderiu", mas se a trajetória brasileira combina difusão metodológica, persistência de ensaísmo/opacidade e hierarquização do campo.

### Debate 2: Método como preferência intelectual ou mecanismo de desigualdade?

Teele & Thelen e Djupe et al. sugerem que diferenças de gênero em publicação não podem ser reduzidas a menor produtividade. Elas aparecem em coautoria, especialização metodológica, estratégias de submissão e retorno institucional. No Brasil, Candido, Feres Jr. & Campos mostram desigualdades estruturais na elite da disciplina; Candido mostra que a própria história disciplinar invisibiliza mulheres.

Para o paper, isso implica cruzar gênero inferido dos autores com:

- tipo de evidência: quantitativa, qualitativa, mista, teórico-normativa;
- status do método: explícito vs. ensaístico;
- desenho causal;
- coautoria e composição de equipe;
- periódico, ano e subcampo;
- formato de escrita.

Importante: a análise deve ser descritiva/correlacional. Gênero inferido por nome é proxy imperfeita, não identidade de gênero. O paper deve documentar incerteza, permitir categoria `unknown/ambiguous` e evitar linguagem causal sobre "mulheres preferem X" sem desenho adequado.

### Debate 3: Transparência metodológica versus formato narrativo do artigo

Parte da literatura de transparência assume que artigos devem revelar o caminho analítico com clareza. Yom, no debate sobre DA-RT, alerta que transparência analítica pode conflitar com a forma convencional do artigo, que frequentemente apresenta a pesquisa como sequência limpa de teoria, hipótese, teste e confirmação. Isso é crucial para o projeto: o paper pode mostrar que "status do método" e "formato de escrita" não são apenas atributos técnicos; são convenções retóricas e disciplinares.

### Debate 4: Escrita acadêmica como estilo, gênero e prática institucional

Hyland e Swales tratam gêneros acadêmicos como práticas de comunidades disciplinares. Plavén-Sigray et al. mostram que legibilidade pode ser medida em larga escala, mas readability não captura tudo: textos podem ser difíceis porque são conceitualmente densos, retoricamente opacos ou apenas mal escritos. Gartenberg et al. adicionam uma questão recente: IA pode aumentar volume e padronizar/empobrecer escrita, mas detectores automáticos não devem ser usados como decisão individual.

Para o paper, a seção de escrita deve evitar moralismo ("texto bom" vs. "texto ruim") e trabalhar com variedades:

- artigo empírico quantitativo em formato IMRaD;
- artigo qualitativo com seção metodológica explícita;
- ensaio teórico/normativo;
- revisão de literatura narrativa;
- revisão sistemática/scoping review;
- artigo metodológico/tutorial;
- formal theory/modelo formal;
- comentário, resenha, entrevista, editorial ou texto fora de escopo;
- artigo híbrido, com argumento substantivo e método implícito.

## 4. Evolução Metodológica Esperada

Internacionalmente, a trajetória esperada é: queda relativa de regressões associacionais genéricas, crescimento de experimentos de survey/campo e quasi-experimentos, mais preocupação com identificação, mas transparência e power analysis ainda raras. No Brasil, a hipótese documentada no repo deve ser mais aberta: pode haver crescimento de métodos explícitos, mas convivendo com ensaísmo, qualitativo explícito, pesquisa documental e formatos híbridos.

A comparação com Torreblanca et al. deve separar duas camadas:

1. Camada comparável: causal claims, design-based methods, identificação, placebo, power analysis, equações, mecanismos.
2. Camada brasileira expandida: ensaísmo, método qualitativo explícito, pesquisa documental, análise de discurso/conteúdo, subcampo, gênero, região/instituição e formato de escrita.

## 5. Gaps Identificados

### Gaps teóricos

- A literatura sobre credibilidade raramente conecta difusão metodológica a desigualdades de gênero, raça, região e posição institucional.
- A literatura de gênero em CP mostra desigualdades de publicação/citação, mas nem sempre cruza essas desigualdades com tipos finos de desenho de pesquisa e formato textual.
- A literatura sobre escrita acadêmica raramente é incorporada a estudos bibliométricos de Ciência Política como dimensão substantiva do campo.

### Gaps empíricos

- Falta uma base longitudinal ampla sobre artigos brasileiros de CP/RI/Administração Pública que codifique método, causalidade, gênero autoral e formato de escrita no mesmo desenho.
- A literatura brasileira documenta desigualdades na elite e formação metodológica, mas ainda há espaço para mapear artigos publicados em periódicos ao longo do tempo.
- Poucos trabalhos tratam o português acadêmico brasileiro como objeto mensurável de estilo, legibilidade e gênero textual.

### Gaps metodológicos

- Inferência de gênero por nome é sensível a erro, nomes estrangeiros e ambiguidade; precisa de validação e categoria de incerteza.
- Classificação LLM deve ser auditada com gold standard, múltiplos classificadores e adjudicação.
- Readability em português exige cuidado: métricas importadas do inglês podem distorcer resultados; melhor combinar métricas simples, classificação de formato e validação humana.

## 6. Implicações Diretas Para o Paper

### Variáveis de gênero recomendadas

- gênero inferido do primeiro autor;
- gênero inferido de todos os autores;
- composição da equipe: solo homem, solo mulher, equipe só homens, equipe só mulheres, equipe mista, desconhecido;
- proporção de mulheres entre autores;
- incerteza da inferência de gênero;
- país/região institucional se disponível;
- posição de autoria não deve ser superinterpretada, pois CP frequentemente usa ordem alfabética.

### Cruzamentos prioritários

- gênero da autoria x `evidence_type`;
- gênero da autoria x `method_status`;
- gênero da autoria x desenho causal;
- gênero da autoria x artigo solo/coautorado;
- gênero da autoria x subcampo;
- gênero da autoria x periódico/ano;
- gênero da autoria x formato de escrita;
- gênero da autoria x legibilidade/estilo, apenas como análise exploratória.

### Cautelas de interpretação

- Não interpretar diferenças por gênero como preferências individuais sem controlar por subcampo, periódico, coorte, coautoria e posição institucional.
- Não tomar método quantitativo/design-based como qualidade intrínseca; o argumento deve ser sobre credibilidade inferencial em certos tipos de claim causal.
- Não tratar artigo ensaístico como "ruim"; em teoria política, história disciplinar e certos debates normativos, o ensaio pode ser formato adequado.
- Não usar AI-detection como medida individual de autoria por IA. Se entrar, deve ser agregado, exploratório e com muitas ressalvas.

## 7. Sugestões de Seções Para o Manuscrito

1. Do calcanhar metodológico à revolução da credibilidade: o problema de pesquisa.
2. Método, transparência e formato: o que conta como evidência na Ciência Política brasileira?
3. Gênero e produção científica: quem publica quais tipos de artigo?
4. Variedades de escrita acadêmica: ensaio, artigo empírico, revisão, método explícito e retórica de cientificidade.
5. Dados e classificação: LLMs, validação tripla, gold standard e adjudicação.
6. Resultados: trajetória temporal, desigualdades e comparação internacional.

## 8. Referências-Chave e Fontes Consultadas

- Albuquerque, Rodrigo Barros de; Mesquita, Rafael; Brito, Renato Victor Lira. 2022. "Obscuridade metodológica: um mapeamento da formação em métodos na pós-graduação em Relações Internacionais e áreas afins no Brasil." Revista Brasileira de Ciência Política, n. 39. DOI: 10.1590/0103-3352.2022.39.258379. Fonte: ResearchGate/SciELO.
- Angrist, Joshua D.; Pischke, Jörn-Steffen. 2010. "The Credibility Revolution in Empirical Economics: How Better Research Design Is Taking the Con out of Econometrics." Journal of Economic Perspectives/CEP Discussion Paper. Fonte: LSE Research Online.
- Barberia, Lorena Guadalupe; Godoy, Samuel Ralize de; Barboza, Danilo Praxedes. 2014. "Novas perspectivas sobre o 'calcanhar metodológico': o ensino de métodos de pesquisa em Ciência Política no Brasil." Teoria & Sociedade, 22(2). Fonte: Teoria & Sociedade.
- Candido, Marcia Rangel; Feres Júnior, João; Campos, Luiz Augusto. 2019. "Desigualdades na elite da Ciência Política brasileira." Civitas, 19(3): 564-582. DOI: 10.15448/1984-7289.2019.3.33488. Fonte: PUCRS/Redalyc.
- Candido, Marcia Rangel. 2021. "Dois gêneros, duas histórias? A institucionalização da ciência política no Brasil." Tese de doutorado, IESP-UERJ. Fonte: BDTD/Ibict.
- Candido, Marcia Rangel. 2023. "A ciência política é um mundo de homens? Uma crítica às narrativas da história da disciplina no Brasil." Revista Brasileira de Ciência Política. Fonte: Ciência-IUL.
- Djupe, Paul A.; Smith, Amy Erica; Sokhey, Anand Edward. 2019. "Explaining Gender in the Journals: How Submission Practices Affect Publication Patterns in Political Science." PS: Political Science & Politics, 52(1): 71-77. DOI: 10.1017/S104909651800104X. Fonte: Cambridge Core.
- Figueiredo, Dalson et al. 2019. "Seven Reasons Why: A User's Guide to Transparency and Reproducibility." Brazilian Political Science Review, 13(2). DOI: 10.1590/1981-3821201900020001. Fonte: Redalyc/SciELO.
- Gartenberg, Claudine; Hasan, Sharique; Murray, Alex; Pierce, Lamar. 2026. "More Versus Better: Artificial Intelligence, Incentives, and the Emerging Crisis in Peer Review." Organization Science, 37(3): 795-812. DOI: 10.1287/orsc.2026.ed.v37.n3. Fonte: INFORMS.
- Goldfrank, Benjamin; Welp, Yanina. 2023. "Researching the Gap: Women in Latin American Political Science." Journal of Politics in Latin America, 15(3): 337-350. DOI: 10.1177/1866802X231213384. Fonte: Sage.
- Hyland, Ken. 2015. "Genre, Discipline and Identity." Journal of English for Academic Purposes, 19: 32-43. DOI: 10.1016/j.jeap.2015.02.005. Fonte: University of East Anglia.
- Maliniak, Daniel; Powers, Ryan; Walter, Barbara F. 2013. "The Gender Citation Gap in International Relations." International Organization, 67(4): 889-922. DOI: 10.1017/S0020818313000209. Fonte: Cambridge Core.
- Plavén-Sigray, Pontus et al. 2017. "The Readability of Scientific Texts Is Decreasing over Time." eLife, 6:e27725. DOI: 10.7554/eLife.27725. Fonte: eLife.
- Soares, Gláucio Ary Dillon. 2005. "O calcanhar metodológico da ciência política no Brasil." Sociologia, Problemas e Práticas, 48: 27-52. Fonte: SciELO Portugal/ISCTE.
- Teele, Dawn Langan; Thelen, Kathleen. 2017. "Gender in the Journals: Publication Patterns in Political Science." PS: Political Science & Politics, 50(2): 433-447. DOI: 10.1017/S1049096516002985. Fonte: Cambridge Core.
- Torreblanca, Carolina; Dinneen, William; Grossman, Guy; Xu, Yiqing. 2026. "The Credibility Revolution in Political Science." arXiv:2601.11542. Fonte: arXiv.
- Yom, Sean. 2018. "Analytic Transparency, Radical Honesty, and Strategic Incentives." PS: Political Science & Politics, 51(2): 416-421. DOI: 10.1017/S1049096517002554. Fonte: Cambridge Core.

