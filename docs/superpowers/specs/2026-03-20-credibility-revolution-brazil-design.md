# Design: Revolução da Credibilidade na CP Brasileira — Etapas 1-2

## Objetivo

Replicar e expandir Torreblanca et al. (2026) para periódicos brasileiros de Ciência Política e Relações Internacionais. Este documento cobre as etapas 1 (definição do corpus) e 2 (coleta de dados).

## Decisões de design

| Decisão | Escolha |
|---|---|
| Fonte de periódicos | SciELO — subject areas de CP, RI, Administração Pública |
| Período | 2005-2025 |
| Texto para classificação | Texto completo (coleta posterior à validação do volume) |
| Gênero dos autores | Coletar nomes agora, inferir gênero em etapa futura |
| Abordagem de teste | Testar pipeline com 1 ano antes de rodar completo |

## Arquitetura

Dois scripts Python sequenciais:

### Script 1: `01_discover_journals.py`
- Consulta API SciELO para listar periódicos da coleção Brasil
- Filtra por subject areas relevantes (Political Science, Public Administration, International Relations, áreas adjacentes)
- Para cada periódico, obtém contagem de artigos no período 2005-2025
- Saída: `data/raw/journals_list.csv` com ISSN, título, subject area, contagem de artigos

### Script 2: `02_collect_articles.py`
- Recebe lista validada de periódicos
- Coleta metadados e texto completo de todos os artigos
- Filtra por tipo (exclui resenhas, editoriais, notas)
- Saída: `data/raw/articles_metadata.csv` e `data/raw/articles_fulltext/` (um arquivo por artigo)

## Campos coletados por artigo

- PID (identificador SciELO)
- Título (PT e EN quando disponível)
- Autores (nomes completos + afiliações institucionais)
- Ano de publicação
- Periódico (ISSN, título)
- Abstract (PT e EN)
- Texto completo (XML/HTML)
- DOI
- Idioma

## Estrutura de diretórios

```
metodos_CP/
├── scripts/
│   ├── 01_discover_journals.py
│   └── 02_collect_articles.py
├── data/
│   ├── raw/
│   └── processed/
├── output/
├── figures/
├── docs/superpowers/specs/
└── README.md
```

## Fonte de dados

SciELO ArticleMeta API e/ou OAI-PMH. A ArticleMeta API permite consultar periódicos por coleção (`scl` = Brasil) e obter metadados incluindo texto completo em XML (formato JATS/SciELO PS).

**Nota**: O usuário reportou dificuldade prévia com a API SciELO. Será necessário investigar endpoints disponíveis e testar alternativas (OAI-PMH, scraping direto do site) caso a API não funcione adequadamente.

## Fluxo de trabalho

1. Rodar `01_discover_journals.py` → gerar lista de periódicos + volume estimado
2. Usuário valida a lista
3. Testar `02_collect_articles.py` com 1 ano (ex: 2020)
4. Usuário valida resultado do teste
5. Rodar coleta completa 2005-2025

## Referências do projeto

- Torreblanca et al. (2026). "The Credibility Revolution in Political Science."
- Soares (2005). "O calcanhar metodológico da ciência política no Brasil."
- Albuquerque et al. (2022). Sobre "obscuridade metodológica" na CP brasileira.
- Candido et al. (2021). Desigualdades de gênero e concentração regional na CP brasileira.
