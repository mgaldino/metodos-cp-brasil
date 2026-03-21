# Revolução da Credibilidade na CP Brasileira

## Projeto

Replicação e expansão de Torreblanca et al. (2026) "The Credibility Revolution in Political Science" para periódicos brasileiros. Paper original em `/Users/manoelgaldino/Documents/DCP/Cursos/Causalidade/Causalidade/2601.11542v1.pdf`.

## Stack

- Python: coleta e classificação (API SciELO + LLM)
- R: análise e gráficos
- Dados: `data/raw/`, `data/processed/`

## Corpus

- **Fonte**: SciELO Brasil (coleção `scl`), API ArticleMeta
- **Período**: 2005-2025
- **Filtro**: subject areas "Political Science", "Public Administration", "International Relations" + seed list manual
- **Resultado**: 15 periódicos, ~11.220 artigos estimados (Movimento removido)
- **Decisão**: escopo restrito (opção A) — só periódicos com subject area de CP/RI/Adm. Pública

### Periódicos incluídos (15)

| ISSN | Título | Artigos |
|---|---|---|
| 0101-3157 | Brazilian Journal of Political Economy | 1874 |
| 0102-6445 | Lua Nova | 1267 |
| 0034-7612 | Revista de Administração Pública | 1242 |
| 0102-6909 | RBCS | 1099 |
| 0034-7329 | RBPI | 814 |
| 0104-4478 | Revista de Sociologia e Política | 770 |
| 0101-3300 | Novos Estudos CEBRAP | 728 |
| 0011-5258 | Dados | 686 |
| 0102-8529 | Contexto Internacional | 565 |
| 1519-6089 | Civitas | 550 |
| 0104-6276 | Opinião Pública | 509 |
| 0103-3352 | Rev. Brasileira de Ciência Política | 468 |
| 1981-3821 | BPSR | 404 |
| 2236-5710 | Cadernos Gestão Pública e Cidadania | 138 |
| 1806-6445 | Sur - Rev. Int. Direitos Humanos | 106 |

### Periódicos investigados mas não incluídos

Busca realizada em 2026-03-20. Esses periódicos foram avaliados e podem ser adicionados se o escopo for expandido.

**No SciELO, rejeitados pelo filtro de subject area (SOCIOLOGY/CULTURAL STUDIES):**

| ISSN | Título | Qualis 2017-2020 | Artigos SciELO |
|---|---|---|---|
| 0103-4979 | Caderno CRH | A1 | ~550 |
| 0102-6992 | Sociedade e Estado | A1 | ~400 |
| 1517-4522 | Sociologias | A1 | ~500 |
| 0103-2070 | Tempo Social | A1 | ~450 |
| 0103-4014 | Estudos Avançados | A2 | ~600 |

**Fora do SciELO (não coletáveis pela API ArticleMeta):**

| Título | Instituição | Nota |
|---|---|---|
| Política Hoje | UFPE | Qualis ~B2, OJS próprio |
| Rev. Eletrônica de Ciência Política | UFPR | Não indexada no SciELO |
| Teoria e Sociedade | UFMG | Não indexada no SciELO |
| Análise Social | ICS Lisboa | Periódico **português**, fora do escopo |

**Removido da lista:**
- Movimento (1982-8918) — periódico de Educação Física, subject area "POLITICAL SCIENCE" apenas como classificação secundária

### Nota sobre ISSN da Rev. de Sociologia e Política

A seed list usava ISSN 1678-9873 (eletrônico). No SciELO, o periódico aparece com ISSN 0104-4478 (print). Ambos referem-se ao mesmo periódico.

## Etapas

1. ~~Definir corpus~~ (concluído)
2. Coletar artigos (próximo: testar com 1 ano)
3. Classificar via LLM
4. Validação manual (~50-100 artigos)
5. Análise e visualização

## Esquema de classificação (adaptado de Torreblanca et al.)

Para cada artigo:
- (a) Status do método: explícito vs. ensaístico/implícito
- (b) Natureza das evidências: quantitativa, qualitativa, mista, teórico/normativo
- (c) Objetivo: descritivo, explicativo, preditivo
- (d) Técnica metodológica principal
- (e) Pretensão de causalidade: explícita, implícita, ausente
- (f) Declara suposições de identificação

## Vulnerabilidades conhecidas (Devil's Advocate, 2026-03-20)

Críticas identificadas e aceitas — a serem endereçadas conforme os dados permitirem:

1. **N pequeno para desagregação por método**: ~12k artigos → análises por método específico (RD, DiD, synthetic control) terão células pequenas. Solução: agregar categorias design-based como bloco.
2. **Tensão replicação vs. crítica sociológica**: decidir com dados em mão se o paper foca no diagnóstico metodológico ou na dimensão de desigualdade, ou se separa em dois papers.
3. **Esquema expandido vs. comparabilidade**: manter esquema Torreblanca intacto como módulo base + camada suplementar brasileira.
4. **Viés de seleção SciELO**: exclui periferia. Argumento: viés conservador (se mesmo no SciELO a revolução é limitada, fora é pior).
5. **Análise gênero/região é correlacional**: moderar linguagem para descritiva, não causal.
6. **Falta teoria de difusão**: incluir seção sobre canais de transmissão (formação doutoral, Qualis, cursos de métodos).
7. **Comparabilidade Brasil-internacional**: comparar com substrato de periódicos de menor impacto do original, não com o agregado.

## Problema da API: filtragem temporal

A API ArticleMeta filtra por `processing_date`, não `publication_year`. Artigos re-processados em um ano aparecem na consulta desse ano. Solução: coletar TODOS os artigos sem filtro de data e filtrar por `publication_year` depois. Campo `publication_year` no JSON é confiável.

## Referências

- Torreblanca et al. (2026). "The Credibility Revolution in Political Science."
- Soares (2005). "O calcanhar metodológico da ciência política no Brasil."
- Albuquerque et al. (2022). Sobre "obscuridade metodológica" na CP brasileira.
- Candido et al. (2021). Desigualdades de gênero e concentração regional na CP brasileira.
