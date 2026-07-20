# Validação bibliográfica do paper

**Data da validação:** 19 de julho de 2026

**Texto validado:** `paper/paper.Rmd`

**Bibliografia validada:** `references.bib`

**Escopo:** consistência entre as citações remanescentes no paper e o arquivo BibTeX após a retirada da seção “Visão geral do campo”, com conferência dos metadados das oito referências citadas.

## Resumo

- Resultado geral: **PASS**.
- Total de citações no texto: **10 menções**, correspondentes a **8 chaves distintas**.
- Citações órfãs: **0**.
- Entradas citadas com campos estruturais ausentes: **0**.
- Chaves suspeitas ou duplicadas entre as referências citadas: **0**.
- Entradas do `.bib` não citadas no paper: **18**. Elas foram preservadas porque `references.bib` é compartilhado com outros artefatos do projeto e não aparecem na lista de referências do paper.

## Referências que permanecem no paper

| Chave | Uso no paper | Resultado |
|---|---|---|
| `soares2005` | Diagnóstico do “calcanhar metodológico” | OK |
| `barberia2014` | Evolução e heterogeneidade do ensino de métodos | OK; páginas confirmadas e adicionadas ao `.bib` |
| `neiva2015` | Uso de métodos nas ciências sociais brasileiras | OK |
| `nicolau2017` | Evolução metodológica dos artigos de Ciência Política | OK |
| `albuquerque2022` | Formação em métodos em RI e áreas afins | OK; páginas confirmadas e adicionadas ao `.bib` |
| `torreblanca2026` | Benchmark internacional da revolução da credibilidade | OK; versão 2 do arXiv confirmada |
| `buerkner2017brms` | Implementação do modelo Bayesiano hierárquico | OK |
| `fuks_fialho_2009` | Exemplo qualitativo sobre uso de margem de erro e nível de confiança | OK |

## Correções efetuadas

1. `barberia2014`: inclusão de `pages = {156--184}`, confirmada no PDF da revista *Teoria & Sociedade*.
2. `albuquerque2022`: inclusão de `pages = {1--25}`, confirmada no PDF da *Revista Brasileira de Ciência Política*.

Os demais registros citados já continham os campos bibliográficos necessários. A ausência de DOI em `soares2005` e `barberia2014` não foi tratada como erro: a existência de DOI não foi confirmada nas páginas editoriais consultadas.

## Entradas não citadas

As 18 entradas abaixo deixaram de ser usadas pelo paper, principalmente porque sustentavam os parágrafos removidos da antiga seção “Visão geral do campo”:

`adcockcollier2001`, `angrist2010`, `avelino2021`, `bradycollier2010`, `brodeur2024`, `domingos2024`, `figueiredo2019`, `gelman2008prior`, `gill1999`, `grimmer2013`, `halterman2026`, `king1994`, `lal2024`, `leiteferes2021`, `lenine2020`, `medeiros2016`, `rainey2014` e `williams2026`.

Elas não foram excluídas do arquivo compartilhado. O processador de citações do R Markdown inclui na bibliografia final apenas as oito entradas citadas.

## Fontes de conferência

- Barberia, Godoy e Barboza: página editorial e PDF da *Teoria & Sociedade*, v. 22, n. 2, p. 156--184.
- Albuquerque, Mesquita e Brito: PDF da *Revista Brasileira de Ciência Política*, n. 39, p. 1--25, DOI `10.1590/0103-3352.2022.39.258379`.
- Torreblanca et al.: registro arXiv `2601.11542`, versão 2, revisada em 26 de fevereiro de 2026.
- Bürkner: página editorial do *Journal of Statistical Software*, v. 80, n. 1, p. 1--28, DOI `10.18637/jss.v080.i01`.

## Critérios de validação

1. Extração de todas as chaves Pandoc no formato `@chave`.
2. Cruzamento das chaves citadas com os cabeçalhos das entradas em `references.bib`.
3. Conferência de autor, título, ano, periódico ou repositório, volume/número, páginas e DOI/URL quando aplicável.
4. Busca de colisões de chave, DOI e título entre as referências citadas.
5. Renderização do paper com `rmarkdown::render()` e inspeção da bibliografia produzida.

## Conclusão

As oito referências remanescentes são pertinentes aos argumentos aos quais estão associadas, possuem entradas BibTeX processáveis e devem permanecer no paper. Não há citação órfã nem referência citada com metadados estruturais incompletos.
