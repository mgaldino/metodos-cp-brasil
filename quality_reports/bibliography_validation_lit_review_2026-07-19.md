# Validação bibliográfica da revisão de literatura

**Data da validação:** 19 de julho de 2026

**Texto validado:** `notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md`

**Bibliografia validada:** `references.bib`

**Escopo:** consistência local entre citações, entradas BibTeX e a lista manual da seção 11. Não foi realizado *fact-check* externo dos metadados.

## Resumo

- Resultado geral: **PASS com ressalvas de completude bibliográfica**.
- Total de citações no texto: **73 menções**, correspondentes a **23 chaves distintas**.
- Total de entradas no `.bib`: **26**.
- Citações órfãs: **0**.
- Entradas não citadas neste relatório: **3**.
- Chaves suspeitas: **0**.
- Possíveis duplicatas: **0**.
- Entradas com problemas de qualidade confirmados localmente: **4**.
- Entradas sem problemas confirmados localmente: **22**.
- Lista manual de referências-chave: **23 itens**; todos correspondem às 23 chaves citadas e a entradas existentes no `.bib`.
- Validação de renderização: `pandoc 3.7.0.2` processou o Markdown com `--citeproc` e terminou com código 0, sem avisos em `stderr`.

Não há falha que impeça o processamento das citações. As ressalvas dizem respeito a localizadores bibliográficos ausentes (`pages` ou número eletrônico), inclusive duas divergências internas entre a lista manual e o `.bib`.

## Citações órfãs (no texto, ausentes do `.bib`) 🔴

Nenhuma. Todas as 23 chaves distintas citadas no texto existem em `references.bib`.

| Chave | Arquivo | Linha |
|---|---|---:|
| — | — | — |

## Entradas não citadas (no `.bib`, ausentes do texto) 🟡

As três entradas abaixo não são usadas nesta revisão de literatura. Como `references.bib` é compartilhado pelo projeto, isso não demonstra que sejam inúteis no repositório e não justifica removê-las.

| Chave | Referência abreviada | Linha no `.bib` |
|---|---|---:|
| `gelman2008prior` | Gelman et al. (2008), “A weakly informative default prior distribution for logistic and other regression models” | 58 |
| `buerkner2017brms` | Bürkner (2017), “brms: An R Package for Bayesian Multilevel Models Using Stan” | 69 |
| `fuks_fialho_2009` | Fuks e Fialho (2009), “Mudança institucional e atitudes políticas” | 80 |

## Possíveis duplicatas 🟡

Nenhuma. Não foram encontradas colisões de DOI normalizado nem de título normalizado combinado com ano. As 26 chaves BibTeX são únicas.

| Chave 1 | Chave 2 | Provável duplicata de |
|---|---|---|
| — | — | — |

Também não foram encontrados pares de chaves com diferença apenas de maiúsculas/minúsculas nem variantes suspeitas do tipo `autor2020`/`autor2020a` sem correspondência no texto.

## Problemas de qualidade no `.bib` 🟡

Todos os registros satisfazem os campos estruturais mínimos adotados nesta auditoria: `@article` contém `author`, `title`, `journal` e `year`; `@book` contém `author` ou `editor`, `title`, `publisher` e `year`; e `@misc` contém `author`, `title` e `year`. Os quatro problemas abaixo são de completude do localizador bibliográfico.

| Chave | Problema | Evidência local | Sugestão |
|---|---|---|---|
| `barberia2014` | Campo `pages` ausente. | A entrada começa na linha 10 do `.bib`; a lista manual, na linha 186 do relatório, informa `156--184`. | Confirmar o intervalo na fonte editorial e, se correto, adicionar `pages = {156--184}` ao `.bib`. |
| `albuquerque2022` | `pages` ou número eletrônico ausente. | A entrada começa na linha 19; a lista manual da linha 180 também termina no número 39, sem localizador. | Confirmar na fonte editorial o número eletrônico/paginação e registrá-lo no campo apropriado. |
| `figueiredo2019` | Campo de localizador ausente. | A entrada começa na linha 28; a lista manual, na linha 194, informa `e0001`. | Confirmar na fonte editorial e, se correto, adicionar `pages = {e0001}` ou campo equivalente ao `.bib`. |
| `brodeur2024` | `pages` ou número de artigo ausente. | A entrada começa na linha 164; a lista manual da linha 190 também não informa localizador. | Confirmar na fonte editorial a paginação ou o número do artigo e registrá-lo. |

### Observações de qualidade não classificadas como erro

- **DOI:** 21 das 26 entradas possuem DOI. Entre artigos, `soares2005` e `barberia2014` não o possuem no arquivo. Como a disponibilidade de DOI não foi verificada externamente, essas ausências não foram contadas como erro confirmado. Livros e o preprint `torreblanca2026` possuem, respectivamente, metadados editoriais e identificador/URL alternativo adequados ao tipo.
- **Anos:** todos estão no intervalo plausível de 1994 a 2026, compatível com o escopo declarado e com obras seminais anteriores a 2005.
- **Páginas:** todos os intervalos existentes usam `--`; localizadores eletrônicos (`e...`) estão sintaticamente consistentes.
- **Autores e títulos:** não foram detectadas divergências de autor principal, ano ou título entre a lista manual e o `.bib`. A proteção de capitalização de acrônimos relevantes (`R`, `Bayesian`, `Stan`, `Codebook LLMs`, `LLMs`) está presente onde necessária.

## Consistência da lista manual “Referências-chave”

A seção 11 contém 23 referências manuais. O pareamento por primeiro autor e ano encontrou correspondência para **23/23** itens no `.bib`. Esse conjunto é exatamente igual ao conjunto das 23 chaves distintas citadas no corpo: não há referência manual sem citação nem citação ausente da lista manual.

Duas diferenças internas devem ser corrigidas em etapa de implementação posterior, após confirmação na fonte:

1. `barberia2014`: a lista manual inclui `156--184`, mas o `.bib` omite `pages`.
2. `figueiredo2019`: a lista manual inclui `e0001`, mas o `.bib` omite o localizador.

As entradas `albuquerque2022` e `brodeur2024` estão internamente consistentes entre lista manual e `.bib`, porém ambos os formatos omitem o localizador bibliográfico, razão pela qual permanecem na tabela de problemas de qualidade.

## Entradas OK ✅

**22 entradas sem problemas confirmados localmente:**

`soares2005`, `torreblanca2026`, `angrist2010`, `gelman2008prior`, `buerkner2017brms`, `fuks_fialho_2009`, `neiva2015`, `nicolau2017`, `medeiros2016`, `lenine2020`, `leiteferes2021`, `avelino2021`, `domingos2024`, `gill1999`, `rainey2014`, `grimmer2013`, `halterman2026`, `king1994`, `bradycollier2010`, `adcockcollier2001`, `lal2024` e `williams2026`.

“OK” significa apenas que a entrada passou nas verificações locais de estrutura, consistência cruzada, plausibilidade do ano, formato de páginas e ausência de duplicata. Não significa que todos os metadados foram confirmados em fonte externa.

## Método e comandos reproduzíveis

### Imutabilidade dos insumos

Os arquivos foram lidos em UTF-8 e não foram alterados. Identificadores SHA-256 no momento da validação:

```text
bf8610c9187353cba29b31ccfe398b5b39fb67e8a0eb71c85a7a81e08685ddc6  notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md
1d6b773c887e2be994b320b538a339c6b78933a8da5648623dd384b1bc463bf8  references.bib
```

Comandos de inventário e renderização:

```bash
shasum -a 256 notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md references.bib
wc -l notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md references.bib
rg -n '^@' references.bib
pandoc notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md \
  --citeproc --bibliography=references.bib -t plain \
  -o /tmp/lit_review_metodos_inferencia_credibilidade_cp_brasil.txt
```

### Regras de extração e cruzamento

1. As citações Markdown foram extraídas pelo padrão `(?<![\\w.])@([A-Za-z0-9_:.+/-]+)`, que captura citações narrativas, parentéticas e múltiplas no formato Pandoc.
2. As entradas BibTeX foram identificadas pelos cabeçalhos `@tipo{chave,` e analisadas por balanceamento de chaves, evitando interromper títulos com chaves internas.
3. Citações órfãs foram calculadas como `chaves_citadas - chaves_bib`; entradas não citadas, como `chaves_bib - chaves_citadas`.
4. Duplicatas foram procuradas por DOI em minúsculas e por `título normalizado + ano`; a normalização removeu diacríticos, pontuação e diferenças de caixa.
5. A qualidade estrutural foi checada por tipo de entrada e, para artigos, também pela presença de `pages` ou localizador equivalente, plausibilidade do ano e formato de intervalos.
6. A lista manual foi separada em parágrafos a partir de `## 11. Referências-chave` e pareada ao `.bib` por primeiro autor normalizado e ano; em seguida, os campos visíveis foram comparados com os registros correspondentes.

## Conclusão da revisão independente

O relatório está bibliograficamente processável: não há citações órfãs, chaves suspeitas ou duplicatas, e todas as referências-chave manuais correspondem às citações usadas. Antes de considerar a bibliografia plenamente limpa, uma implementação separada deve confirmar e completar os quatro localizadores apontados, dando prioridade às duas divergências já demonstráveis internamente (`barberia2014` e `figueiredo2019`). Nenhum arquivo de origem foi modificado nesta revisão.
