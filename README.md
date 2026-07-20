# Depois do calcanhar metodológico

Materiais do artigo **“Depois do calcanhar metodológico: inferência e identificação causal na Ciência Política brasileira”**, de Manoel Galdino e Rodrigo Martins.

- Manoel Galdino — professor do Departamento de Ciência Política da Universidade de São Paulo (DCP-USP)
- Rodrigo Martins — pesquisador de pós-doutorado no Departamento de Ciência Política da Universidade de São Paulo (DCP-USP)

O projeto investiga quanto a profissionalização metodológica das últimas duas décadas alterou as práticas observáveis nos artigos publicados pela Ciência Política e pelas Relações Internacionais brasileiras. O foco não é apenas saber se um artigo usa números ou modelos, mas distinguir pesquisa empírica, análise quantitativa, inferência estatística, pretensão causal e estratégia explícita de identificação.

O manuscrito atual está disponível em [paper/paper.pdf](paper/paper.pdf), e seu código-fonte está em [paper/paper.Rmd](paper/paper.Rmd).

## Corpus

O corpus analítico reúne **4.144 artigos** publicados entre 2005 e 2025 em nove periódicos indexados no SciELO:

- *Brazilian Political Science Review*;
- *Cadernos Gestão Pública e Cidadania*;
- *Contexto Internacional*;
- *Dados*;
- *Opinião Pública*;
- *Revista Brasileira de Ciência Política*;
- *Revista Brasileira de Ciências Sociais*;
- *Revista Brasileira de Política Internacional*;
- *Revista de Sociologia e Política*.

Os nove periódicos estão integralmente classificados nesta versão. *Brazilian Journal of Political Economy*, *Civitas — Revista de Ciências Sociais*, *Revista de Administração Pública*, *Sur — Revista Internacional de Direitos Humanos*, *Lua Nova* e *Novos Estudos CEBRAP* não entram nos denominadores do paper. As 19 unidades editoriais da série *Tendências*, de *Opinião Pública*, também foram consideradas inelegíveis por não se apresentarem como artigos acadêmicos assinados.

## Principais resultados

- Dos 4.144 artigos, **3.414 são empíricos** e **1.999** têm componente quantitativo.
- Entre os 1.994 quantitativos com classificação disponível para inferência, **743 (37,3%)** quantificam formalmente a incerteza por testes, erros-padrão, intervalos ou procedimento equivalente.
- Apenas **59 artigos (1,4% do corpus)** mencionam uma estratégia causal explícita.
- **1.885 artigos (45,5%)** combinam análise quantitativa e pretensão causal sem explicitar uma estratégia de identificação.
- A incidência de inferência estatística pouco varia entre 2005 e 2025, apesar do crescimento da pesquisa empírica.
- A análise por área encontra mais inferência estatística em Ciência Política do que em Relações Internacionais, depois de incorporar a variação entre periódicos.
- Artigos cujo primeiro prenome foi classificado como feminino são mais frequentemente empíricos; entre os empíricos, porém, apresentam menos análise quantitativa e, entre os quantitativos, menos inferência estatística. A pretensão causal tem frequência semelhante nas duas categorias.

O argumento central é que a ambição causal se difundiu mais rapidamente que os métodos capazes de sustentá-la. Nos periódicos brasileiros analisados, a inferência estatística ainda divide a produção quantitativa; nos periódicos internacionais de referência estudados por Torreblanca et al., a fronteira já está na identificação causal explícita.

As classificações registram a presença das práticas, não a qualidade de sua execução. A classificação em escala ainda requer validação humana estratificada.

## Protocolo de classificação

Cada artigo foi processado separadamente a partir do texto integral. Antes de atribuir rótulos, o modelo deveria:

1. ler o corpo completo do artigo;
2. registrar as seções examinadas e sua relevância metodológica;
3. resumir o artigo;
4. responder a perguntas de auditoria sobre evidência empírica, análise quantitativa, evidência qualitativa, inferência e identificação causal;
5. somente então produzir a classificação estruturada em JSON.

O protocolo proíbe classificações baseadas apenas em título, resumo, palavras-chave, tabelas isoladas, regras lexicais ou rótulos anteriores. As respostas são validadas quanto à estrutura, aos valores permitidos e às relações lógicas entre os campos.

Os componentes versionados do protocolo são:

- [wrapper de leitura integral](data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md);
- [prompt e codebook do classificador v3](data/processed/credibility_prompt_v3_test/prompts/classifier_prompt_v3.md);
- [esquema JSON de validação](data/processed/credibility_prompt_v3_integral_reading/prompts/integral_reading_output_schema.json).

O apêndice do paper reproduz o prompt integral e descreve as verificações aplicadas.

## Estrutura do repositório

```text
metodos_CP/
├── paper/                 # Manuscrito, preâmbulo e PDF compilado
├── scripts/               # Coleta, classificação, análise e auditoria
├── data/
│   ├── raw/               # Metadados e artefatos brutos de coleta
│   └── processed/         # Bases canônicas e dados derivados
├── output/
│   ├── figures/           # Figuras produzidas pelos scripts
│   ├── tables/            # Tabelas e números intermediários
│   └── models/            # Artefatos de modelos
├── replication_files/     # Pacote público de replicação
├── quality_reports/       # Validações, pareceres e diagnósticos
├── notes/                 # Notas de pesquisa e revisão da literatura
├── references.bib         # Bibliografia do manuscrito
└── scripts/README.md      # Descrição detalhada dos scripts
```

Os principais pontos de entrada analíticos são:

- `scripts/45_build_current_paper_analysis.R`: constrói a base analítica, valida regras lógicas e gera os resultados principais;
- `scripts/48_expand_statistical_inference_analysis.R`: detalha a análise de inferência estatística;
- `scripts/51_analyze_gender_current_canonical.R`: produz a análise descritiva de composição da autoria;
- `scripts/52_analyze_area_current_canonical.R`: compara Ciência Política e Relações Internacionais;
- `scripts/54_bayesian_area_hierarchical_model.R`: estima os modelos bayesianos por área;
- `scripts/54_fit_bayesian_gender_hierarchical.R`: estima os modelos bayesianos de composição da autoria;
- `scripts/57_replicate_paper.R`: orquestra a reconstrução dos artefatos analíticos do paper.

Uma descrição mais extensa está em [scripts/README.md](scripts/README.md).

## Replicação

O [pacote público de replicação](replication_files/README.md) está disponível em `replication_files/`. Ele contém o manifesto do corpus, o CSV canônico de classificações, os ledgers de elegibilidade, os prompts, os scripts analíticos, os arquivos do paper e checksums dos arquivos distribuídos.

Para reproduzir os resultados, execute primeiro o preflight e depois a cadeia completa a partir da raiz do pacote:

```bash
LC_ALL=pt_BR.UTF-8 Rscript scripts/57_replicate_paper.R --preflight
LC_ALL=pt_BR.UTF-8 Rscript scripts/57_replicate_paper.R
```

O pacote não redistribui textos integrais nem refaz a coleta ou a classificação por modelo de linguagem. As dependências, limitações do ambiente e opções de execução estão documentadas no README da pasta de replicação.

## Política de dados e textos integrais

Os metadados e textos foram obtidos de páginas públicas do SciELO. Os textos integrais são insumos externos usados para classificação e permanecem sujeitos às licenças dos respectivos artigos, autores e periódicos. A licença deste repositório não transfere direitos sobre esses conteúdos.

O pacote público de replicação distribui scripts, manifestos, URLs, hashes, decisões de elegibilidade e dados derivados necessários à auditoria. Os corpos integrais devem ser reconstruídos a partir das fontes originais, em vez de redistribuídos como parte do pacote público.

## Reprodutibilidade e convenções

- R é usado para análise estatística, validação, tabelas e figuras.
- Python é usado para coleta, extração de texto e execução dos classificadores.
- Cálculos derivados permanecem em scripts; o RMarkdown organiza a exposição dos resultados.
- Dados brutos não são sobrescritos por etapas de limpeza ou consolidação.
- Seleções de colunas em R usam `dplyr::select()` explicitamente.
- Figuras e tabelas do paper são numeradas e têm legendas.
- As análises bayesianas preservam diagnósticos de amostragem e checagens preditivas.

## Licença

O código e a documentação original deste repositório são disponibilizados sob a [GNU General Public License v3.0](LICENSE). Essa licença não se aplica automaticamente aos artigos, textos integrais e demais materiais de terceiros preservados para fins de pesquisa.

## Citação

Uma referência bibliográfica definitiva será acrescentada após a circulação pública da versão correspondente do artigo. Enquanto isso, cite o manuscrito pelo título e pelos autores:

> Galdino, Manoel; Martins, Rodrigo. *Depois do calcanhar metodológico: inferência e identificação causal na Ciência Política brasileira*. Manuscrito, 2026.
