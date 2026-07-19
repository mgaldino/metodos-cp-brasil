# Notas editoriais da revisão de redação

**Data:** 19 de julho de 2026

## Diagnóstico

A versão anterior apresentava as cautelas, os denominadores e a literatura antes de explicitar o resultado substantivo. Isso atrasava o argumento e fazia o texto soar como uma descrição do pipeline de classificação. Havia também parágrafos com mais de uma função e contrastes formulados de modo abstrato.

## Alterações realizadas

1. A introdução agora abre com o achado sobre inferência estatística e o contrasta imediatamente com o benchmark de Torreblanca et al.
2. O argumento distingue explicitamente descrição, quantificação da incerteza e identificação causal.
3. Dados, estratégia empírica, resultados, discussão e conclusão foram reescritos em parágrafos mais curtos, com sujeito e verbo explícitos.
4. As seções por área e sobre inferência apresentam primeiro o resultado, depois a interpretação e por fim os limites da medida.
5. As ressalvas foram concentradas onde são necessárias: denominadores, qualidade da execução e validação humana da classificação.
6. Foi removida uma função de formatação de valores de *p* que não era mais usada após a retirada dos testes frequentistas.

## Controle de consistência

- Os números continuam sendo lidos dos artefatos canônicos pelo `paper.Rmd`; a revisão não alterou a análise.
- O PDF foi recompilado com `rmarkdown::render` e o texto extraído com `pdftotext`.
- `git diff --check` passou.
- A pontuação duplicada produzida pelo sufixo “p.p.” foi corrigida.
