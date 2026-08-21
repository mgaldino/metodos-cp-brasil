# Auditoria do uso de intervalos de confiança e indícios de assistência por IA

## Conclusão executiva

O enunciado exigia um intervalo de confiança de 95% para cada proporção, mas não exigia nem mencionava Wilson. O material da disciplina ensina a aproximação normal/Wald: calcular `EP = sqrt(p*(1-p)/n)`, a margem `1,96*EP` e os limites `p ± margem`. A busca nos materiais da disciplina não encontrou “Wilson”, `binom.confint` nem “intervalo score”.

Entre 56 entregas com texto extraído, apenas duas declaram Wilson: Gabriela Assano e Beatriz Pessoni. Quarenta e cinco usam explicitamente a fórmula normal/Wald ensinada; sete extraem o intervalo da saída de `prop.test()`; uma parece usar a aproximação normal, mas o OCR não permite confirmação; e uma não é classificável com segurança.

O uso de Wilson por Gabriela é, portanto, atípico e externo ao repertório documentado do curso. Somado à função encapsulada, à justificativa pronta sobre superioridade em relação a Wald e à rotulagem tecnicamente imprecisa de `prop.test(..., correct = TRUE)` como “Wilson”, isso constitui um indício relevante de assistência externa, plausivelmente IA. Não é prova conclusiva: a aluna poderia ter pesquisado por conta própria ou recebido ajuda humana.

## Registro de suspeitas do docente — não comprovadas

| Estudante | Marcação | Fundamentos da suspeita | Situação probatória |
|---|---|---|---|
| Gabriela Yumi Fraga Assano | **Suspeita elevada de assistência por IA** | Wilson não ensinado; função encapsulada; justificativa metodológica sofisticada sem fonte; rótulo tecnicamente impreciso para `correct = TRUE`; contraste entre linguagem segura e domínio incompleto | **Não comprovada**; requer explicação pela estudante |
| Beatriz Pessoni | **Suspeita elevada de assistência por IA** | Wilson não ensinado; uso avançado de `binom::binom.confint()`, `rowwise()` e coluna-lista sem explicar a escolha; forte descontinuidade entre esse bloco e erros básicos em outras partes; resultados corretos na tabela, mas números errados e fixados manualmente no teste seguinte | **Não comprovada**; requer explicação pela estudante |

Esta marcação registra a suspeita informada pelo docente e os elementos observáveis que a motivam. Ela não afirma como fato que houve uso de IA. A verificação proposta é pedir que cada estudante explique e reproduza o próprio procedimento sem consultar o relatório.

## O que o enunciado pedia

Na tabela de experiência administrativa, o enunciado solicitava:

1. número de observações válidas por pasta;
2. número de nomeações com experiência;
3. proporção com experiência;
4. intervalo de confiança de 95% para a proporção;
5. margem de erro associada.

Para o segundo teste, o enunciado voltava a pedir um intervalo de confiança de 95% para cada proporção. Em nenhum dos dois casos especificava o método do intervalo.

## O que foi ensinado

O material de aula define o erro-padrão aproximado da proporção como:

```text
EP = sqrt(p_chapeu * (1 - p_chapeu) / n)
```

e constrói o IC de 95% por:

```text
margem = 1,96 * EP
limite_inferior = p_chapeu - margem
limite_superior = p_chapeu + margem
```

Esse é o intervalo normal/Wald. Wilson não aparece no material pesquisado.

## Como as 56 entregas fizeram

| Método detectado | Número de entregas |
|---|---:|
| Normal/Wald manual | 45 |
| IC extraído de `prop.test()` | 5 |
| IC exibido na saída de `prop.test()` | 2 |
| Wilson declarado | 2 |
| Provável normal/Wald | 1 |
| Não identificável com segurança | 1 |

Os dois usos declarados de Wilson são:

- Gabriela Assano: cria `calcula_ic_wilson()`, chama `prop.test(x, n, correct = TRUE)` e extrai `$conf.int`;
- Beatriz Pessoni: chama `binom::binom.confint(..., methods = "wilson")`.

As implementações são diferentes, portanto não há evidência, apenas por esses trechos, de cópia direta entre as duas alunas. A coincidência mostra, porém, que Wilson não foi absolutamente único; foi uma escolha muito minoritária, presente em 2 de 56 trabalhos.

## Trabalhos fortes que responderam sem Wilson

Há vários. Exemplos com os resultados centrais corretos:

- Fellipe Pereira: usa diretamente `p ± 1,96*EP` e recebeu 9,8 na avaliação inicial e 9,8 na releitura independente;
- Murilo Souto Maior: usa `sqrt(p*(1-p)/n)` e `p ± 1,96*EP`; recebeu 9,8 inicialmente e 9,2 na releitura independente, com os descontos por outros problemas;
- Lara Lacerda: usa `1,96*sqrt(p*(1-p)/n)`; recebeu 8,8 inicialmente e 9,4 na releitura independente;
- João Pedro Galhianne, Veronica Guibu, Pedro Godoi, Filipe Otuka e outros também obtiveram notas altas usando a aproximação normal/Wald.

Portanto, Wilson não era necessário para responder bem. A resposta mais alinhada ao curso era o intervalo normal/Wald.

## Avaliação específica do indício de IA em Gabriela

### Elementos que aumentam a suspeita

1. O método não foi ensinado nem pedido e aparece em somente 2 de 56 entregas.
2. O texto introduz espontaneamente uma comparação metodológica sofisticada — “mais adequado que Wald quando a proporção está próxima de 1” — sem citar fonte.
3. A aluna cria uma função específica e extrai componentes internos de um objeto de teste, operação mais sofisticada do que o padrão ensinado.
4. Apesar dessa sofisticação, o rótulo não é tecnicamente preciso: com `correct = TRUE`, `prop.test()` fornece um intervalo score com correção de continuidade, não o Wilson simples. Esse contraste entre linguagem confiante e compreensão incompleta é compatível com código gerado ou adaptado sem domínio integral.
5. O código não torna explícito `conf.level = 0.95`; depende silenciosamente do padrão da função, embora o texto fale com segurança sobre 95%.

### Elementos que impedem uma conclusão definitiva

1. Wilson é um método real e facilmente encontrável em pesquisa online.
2. A aluna poderia ter consultado documentação, colega, monitor ou outra fonte humana.
3. Não há, nesse trecho, reprodução literal do código de Beatriz; as duas implementações diferem.
4. Detectores estilométricos de IA não fornecem prova confiável de autoria.

### Julgamento calibrado

O trecho tem, sim, **cara de assistência por IA** e merece verificação. A evidência atual sustenta “suspeita elevada”, não “uso comprovado”. O teste mais informativo seria uma breve verificação oral ou escrita, pedindo à aluna que, sem consultar o relatório:

1. explique o que são `x`, `n` e `$conf.int`;
2. diga por que escolheu Wilson e qual fonte consultou;
3. explique o efeito de `correct = TRUE` e refaça com `correct = FALSE`;
4. reconstrua o IC pelo método ensinado, `p ± 1,96*EP`, e compare os resultados;
5. explique por que o método de IC não é o mesmo que o teste de diferença entre as duas pastas.

Se ela dominar essas respostas, o uso de um método externo pode ser tratado como pesquisa autônoma. Se não conseguir explicar o próprio código e não apresentar uma fonte, a hipótese de assistência não declarada ganha força substancial.

## Avaliação específica do indício de IA em Beatriz

### Elementos que aumentam a suspeita

1. O uso explícito de `binom::binom.confint(..., methods = "wilson")` não deriva do material da disciplina e não é acompanhado de fonte ou justificativa metodológica.
2. O bloco combina recursos relativamente avançados — `rowwise()`, uma coluna-lista contendo o objeto retornado por `binom.confint()` e extração de `IC$lower` e `IC$upper` — para uma conta que o curso ensinou diretamente como `p ± 1,96*EP`.
3. Há uma descontinuidade de domínio dentro do próprio arquivo: o bloco Wilson é sofisticado e produz uma tabela correta, mas logo depois o teste usa números fixados manualmente (`309/351`) que contradizem a tabela correta (`312/354`).
4. A questão de tamanho amostral afirma que o dobro de 525 é 1.025, em vez de 1.050, e não demonstra `1/sqrt(2)`. Essa aritmética elementar contrasta com a manipulação de objetos complexos no bloco Wilson.
5. A interpretação não explica o que é Wilson nem por que esse método foi escolhido. O código executa uma decisão metodológica que o texto não demonstra compreender.

### Elementos que impedem uma conclusão definitiva

1. `binom.confint()` é uma função documentada e pode ter sido encontrada por pesquisa independente.
2. O arquivo carrega explicitamente o pacote `binom`, de modo que o trecho é executável e não é uma chamada inventada.
3. A implementação difere da de Gabriela; não há evidência textual de cópia direta entre as duas.

### Perguntas de verificação para Beatriz

1. Por que escolheu `methods = "wilson"` em vez da fórmula ensinada em aula?
2. O que `rowwise()` faz nesse código e por que `IC` precisa ser uma lista?
3. O que contêm `IC$lower` e `IC$upper`?
4. Por que a tabela usa 312/354, mas o teste seguinte fixa 309/351?
5. Refaça o intervalo com `p ± 1,96*EP` e compare os limites.

Se a estudante não conseguir explicar a construção da coluna-lista e a divergência entre tabela e teste, a hipótese de código obtido externamente sem domínio ganha força substancial.

## Arquivos da auditoria

- Classificação reproduzível: `tmp/grading_work/audit_ic_methods.py`.
- Resultado por aluno: `tmp/grading_work/ic_methods_audit.csv`.
