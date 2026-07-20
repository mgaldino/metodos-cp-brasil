# Arquivos de replicação

## Objetivo

Esta pasta contém os scripts e as entradas necessárias para reproduzir as análises, tabelas, figuras e o PDF do paper **Depois do calcanhar metodológico: inferência e identificação causal na Ciência Política brasileira**.

O pacote parte do CSV canônico já classificado. Ele não realiza coleta de artigos, recuperação de texto integral, chamadas a modelos de linguagem ou consolidação de batches.

## Universo e entradas

O arquivo `full_corpus_manifest.csv`, preservado na árvore `data/processed/`, é o manifesto do corpus. Ele contém uma linha por artigo candidato, com PID, título, autoria, periódico, ano, DOI, idioma, origem do texto integral, hashes e controles de validação. O manifesto define o universo anterior à aplicação dos ledgers analíticos e permite detectar classificações duplicadas, ausentes ou externas ao corpus.

O arquivo `classifications_integral_reading.csv`, preservado na árvore `data/processed/`, é o CSV canônico de classificações por leitura integral.

Na versão empacotada em 20 de julho de 2026:

- o manifesto contém 5.249 artigos;
- o CSV canônico contém 4.389 classificações preservadas;
- os ledgers excluem artigos individualmente inelegíveis e periódicos fora do escopo corrente;
- o universo analítico do paper contém 4.144 artigos de nove periódicos;
- todos os 4.144 artigos do universo analítico estão classificados.

Lua Nova: Revista de Cultura e Política e Novos Estudos CEBRAP permanecem preservados no manifesto e no CSV canônico, mas são temporariamente inelegíveis nesta versão porque sua classificação está incompleta.

## Conteúdo

### Scripts analíticos

- Análise principal e benchmark: scripts 45 e 48.
- Comparação por área: scripts 52 e 54 de área.
- Análise de gênero: scripts 51, 56 e 54 de gênero.
- Execução integral: script 57.
- Reconstrução desta pasta: script 58.

### Entradas preservadas

- manifesto do corpus;
- CSV canônico de classificações;
- ledgers de exclusão por artigo e por periódico;
- fonte em TeX do benchmark de Torreblanca et al.;
- prompts reproduzidos no apêndice do paper;
- `paper/paper.Rmd` e `paper/preamble.tex`;
- `references.bib`;
- `MD5SUMS`, com checksums dos arquivos do pacote.

O utilitário `scripts/58_build_replication_files.R` reconstrói esta pasta a partir do repositório de desenvolvimento.

## Requisitos

- R com suporte UTF-8;
- XeLaTeX;
- CmdStan 2.37.0;
- pacotes R: `brms`, `cmdstanr`, `dplyr`, `genderBR` 1.4.0, `ggplot2`, `jsonlite`, `knitr`, `patchwork`, `posterior`, `readr`, `rmarkdown`, `stringr`, `tibble` e `tidyr`.

O preflight informa quais pacotes estão ausentes e interrompe a execução quando a versão ativa de `genderBR` difere da versão 1.4.0 registrada nos artefatos de gênero. Depois de instalar `cmdstanr`, instale a versão testada do CmdStan com `cmdstanr::install_cmdstan(version = "2.37.0")`.

## Execução

Execute os comandos a partir da raiz desta pasta.

### 1. Preflight

O preflight não altera outputs analíticos. Ele verifica arquivos, pacotes e respectivas versões críticas, XeLaTeX, CmdStan, duplicação de PIDs e compatibilidade entre o CSV canônico e o manifesto. Um log datado é gravado em `quality_reports/replication/`.

```bash
LC_ALL=pt_BR.UTF-8 Rscript scripts/57_replicate_paper.R --preflight
```

### 2. Replicação integral

```bash
LC_ALL=pt_BR.UTF-8 Rscript scripts/57_replicate_paper.R
```

O script interrompe a execução quando uma etapa falha ou quando um output obrigatório não é atualizado. O PDF final é gravado em `paper/paper.pdf`. Logs timestampados são gravados em `quality_reports/replication/`.

Para recalcular todos os resultados sem renderizar o PDF:

```bash
LC_ALL=pt_BR.UTF-8 Rscript scripts/57_replicate_paper.R --skip-render
```

## Ordem computacional

- Cadeia principal: script 45, seguido pelo script 48.
- Comparação por área: script 45, seguido pelos scripts 52 e 54 de área.
- Análise de gênero: scripts 51, 56 e 54 de gênero, nessa ordem.
- Renderização: ocorre somente depois que as três cadeias produzem e validam seus outputs.

## Verificação dos arquivos

Para conferir os checksums no macOS:

```bash
md5 -r $(awk '{print $2}' MD5SUMS)
```

O arquivo `MD5SUMS` usa caminhos relativos à raiz desta pasta. A comparação deve ser feita antes de executar a replicação, pois os scripts atualizam arquivos derivados e criam novos diretórios de output.

## Limitações do ambiente

Este pacote registra explicitamente as dependências, mas ainda não contém um `renv.lock`. Portanto, versões futuras dos pacotes R podem produzir pequenas diferenças numéricas ou de formatação. Os modelos bayesianos usam sementes fixas e CmdStan 2.37.0, mas diferenças de compilador, sistema operacional e paralelização ainda podem afetar os draws individuais.

Em 20 de julho de 2026, a nova checagem confirmou que `genderBR` está instalado e que sua API aceita os argumentos usados pelo script. A biblioteca R ativa, porém, contém a versão 1.2.0, enquanto os CSVs e o relatório de gênero existentes registram a versão 1.4.0. O preflight, portanto, interrompe corretamente a replicação até que a versão 1.4.0 esteja ativa. A integridade estrutural das entradas foi confirmada separadamente: 5.249 registros no manifesto, 4.389 classificações canônicas, sem PIDs duplicados e sem classificações fora do manifesto. O CmdStan ativo é o 2.37.0.

A cadeia completa não foi reexecutada nesta checagem, pois isso misturaria outputs produzidos por versões diferentes do classificador de gênero. Os outputs correntes do paper permanecem preservados e documentam explicitamente a versão 1.4.0 usada em sua geração.
