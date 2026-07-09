# Parecer Devil's Advocate Delta

Data: 2026-07-08  
Escopo: checagem delta de `paper/paper.Rmd`, `paper/paper.pdf`, `output/tables/paper/denominator_summary.csv`, `quality_reports/paper_variable_audit/gate0_corpus_completeness_audit.md` e `quality_reports/paper_reviews/integrated_paper_devils_advocate.md`.

## Parecer curto

O bloqueio substantivo principal do relatório anterior foi resolvido para circulação como **artefato preliminar reprodutível**: o título e o resumo agora rebaixam explicitamente o manuscrito para "protocolo de mensuração e evidência preliminar", os denominadores foram atualizados para 799 classificados de 5.250 PIDs, e o texto declara que não entrega diagnóstico final do corpus completo.

Permanece, porém, um bloqueio de circulação do **PDF como documento legível**: a Figura 1 tem rótulos sobrepostos e a Tabela 3 está visualmente quebrada, com cabeçalhos e colunas sobrepostos. Esse problema não derruba a lógica metodológica, mas impede circular o PDF como artefato preliminar polido sem ressalva forte ou correção de layout.

## Delta observado

- Denominador atual: 799 classificados de 5.250 PIDs, 15,2% do manifest; 4.451 pendentes.
- Gate 0 continua correto em classificar o manuscrito como preliminar: `classification_covers_full_manifest` ainda falha.
- Números substantivos atuais: 647 empíricos, 349 com componente quantitativo, 682 com claim causal ou explicativo, 150 no screen de credibilidade, 16 com desenho estrito.
- `paper/paper.Rmd` rebaixa a pergunta na introdução para uma versão circunscrita: mensuração reprodutível e o que a fração classificada permite observar sem generalizar.
- O texto agora trata a comparação entre claims e desenhos estritos como "dissociação preliminar entre dimensões que não são perfeitamente equivalentes", reduzindo o overclaiming apontado no relatório anterior.
- A figura de cobertura por periódico/período foi antecipada em relação à figura de período, reduzindo o risco de leitura temporal causal.

## Bloqueio remanescente

### PDF não deve circular como artefato legível sem correção de layout

**Severidade**: Alta para circulação do PDF; baixa para validade metodológica.

Na inspeção visual das páginas renderizadas:

- Página 5: a Figura 1 apresenta rótulos de eixo sobrepostos nos painéis, dificultando a leitura do "mapa de denominadores".
- Página 9: a Tabela 3 tem cabeçalhos e células sobrepostos, especialmente em `Dimensão`, `Categoria`, `Denominador`, `N denominador`, `Percentual` e `Nota`.
- Página 10: a continuação da Tabela 3 mantém sobreposição de cabeçalhos/células.

Esse problema importa porque o manuscrito depende precisamente de denominadores e distinções entre linhas da Tabela 3 para se defender contra overclaiming. Se a tabela que comunica esses denominadores está ilegível, o PDF enfraquece a própria estratégia de transparência.

## Ressalvas metodológicas que permanecem, mas não bloqueiam a circulação preliminar

- A cobertura segue parcial e concentrada: vários periódicos centrais permanecem com 0% de classificação.
- `method_explicitness` e `empirical_article_format` continuam ausentes; portanto, a tese sobre baixa explicitação/padronização segue como hipótese e tarefa de medição, não resultado.
- A classificação por leitura integral ainda exige validação substantiva adicional de acurácia, especialmente em `causal_or_explanatory_claim_present`, `credibility_revolution_screen_applicable` e `credibility_revolution_method_type`.
- A comparação entre 682 claims, 150 no screen e 16 desenhos estritos está bem mais cautelosa, mas ainda deve ser desdobrada em matriz por tipo de evidência/claim para a versão substantiva.

## Conclusão delta

Eu não bloquearia a circulação **interna** do manuscrito como artefato preliminar reprodutível de mensuração, desde que seja claro que ainda não é diagnóstico substantivo do corpus completo. Eu bloquearia a circulação do **PDF atual** como documento legível ou compartilhável externamente até corrigir a Figura 1 e a Tabela 3, porque a apresentação visual compromete a comunicação dos próprios denominadores que tornam o paper defensável.

