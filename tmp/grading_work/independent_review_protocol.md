# Protocolo cego de reavaliação — trabalho final FLP0406-2026

## Independência

- Leia apenas este protocolo e o PDF indicado na tarefa.
- Não abra planilhas de notas, CSVs de correção, avaliações anteriores, OCRs anteriores, relatórios heurísticos ou trabalhos de outros estudantes.
- Não procure nem infira a nota já atribuída.
- Produza uma avaliação própria, baseada exclusivamente no que está demonstrado no PDF.
- Não altere arquivos. Entregue o parecer somente na resposta ao agente principal.

## Escala comum

A nota total vai de 0 a 10 e é a soma dos oito critérios abaixo. Atribua crédito parcial proporcional. Informe cada subnota, a soma exata e a nota final arredondada para uma casa decimal.

| Critério | Máximo | Crédito integral | Descontos principais |
|---|---:|---|---|
| 1. Artigo e unidade de análise | 0,75 | Identifica corretamente artigo, casos e unidade de análise. | Identificação vaga ou unidade incorreta. |
| 2. Leitura e validação da base | 1,50 | Informa dimensões, variáveis e ausências; trata códigos inválidos. | Ausências não verificadas ou limpeza inadequada. |
| 3. Descritiva de `exp_adm` | 1,75 | Calcula n, x, proporção e intervalo de confiança por órgão. | Denominadores incorretos, mistura com `exp_car` ou ausência de intervalo. |
| 4. Teste de proporções 1 | 1,50 | Testa a diferença MAPA-MINC em `exp_adm` e interpreta o p-valor. | Estimando alterado, p-valor/decisão contraditórios ou teste ausente. |
| 5. `alto_nivel` e teste 2 | 1,75 | Constrói `alto_nivel` coerentemente, estima por órgão e testa a diferença. | Recodificação incorreta ou conclusão incompatível com o teste. |
| 6. Níveis de significância | 0,75 | Distingue corretamente as decisões a 10% e 1%. | Confunde limiares ou não relaciona alfa e p-valor. |
| 7. Amostra maior | 0,50 | Explica que dobrar n reduz o erro-padrão por `1/sqrt(2)`. | Só afirma que melhora, sem direção/mecanismo, ou conclui o oposto. |
| 8. Reprodutibilidade e apresentação | 1,50 | Código/dados, resultados legíveis e narrativa coerente. | Só respostas sem cálculo, inconsistências graves ou ausência de evidência reprodutível no relatório. |

Variantes defensáveis dos testes — sem pooling, com correção de continuidade ou aproximações equivalentes — recebem crédito quando preservam o estimando e a decisão substantiva correta.

## Âncoras numéricas do gabarito

- Base: 1.038 linhas e 26 colunas; uma linha por ocupante/cargo observado.
- Ausentes: `instr=95`; `exp_adm=11`; `exp_car=76`; `nivel=0`; `indicacao=0`; `car_pub=17`.
- `exp_adm`, MAPA: `n=524`, `x=482`, `p=0,91985`, IC95% aproximadamente `[0,892; 0,941]`.
- `exp_adm`, MINC: `n=354`, `x=312`, `p=0,88136`, IC95% aproximadamente `[0,842; 0,912]`.
- Teste 1, MINC-MAPA: diferença aproximadamente `-0,03849`, `z=-1,902`, `p=0,05716`. Rejeitar H0 a 10%; não rejeitar a 5% nem a 1%.
- `alto_nivel`, MAPA: `n=525`, `x=187`, `p=0,35619`.
- `alto_nivel`, MINC: `n=365`, `x=155`, `p=0,42466`.
- Teste 2, MINC-MAPA: diferença aproximadamente `0,06847`, `z=2,065`, `p=0,03889`. Rejeitar H0 a 5%; não rejeitar a 1%.
- Dobrar n: `EP_novo = EP_antigo/sqrt(2)`, redução de aproximadamente 29,3%.
- Faixas aceitáveis para variantes defensáveis: teste 1, p aproximadamente 0,052-0,074; teste 2, p aproximadamente 0,039-0,046.

## Formato obrigatório da resposta

1. Identifique nome, NUSP e PDF.
2. Apresente as oito subnotas no formato `C1=x/0,75`, ..., `C8=x/1,50`.
3. Informe `soma exata` e `nota normalizada` — a soma limitada ao intervalo 0-10 e arredondada para uma casa decimal.
4. Dê uma justificativa de 120 a 220 palavras, citando evidências concretas do relatório: números, procedimentos, decisões e omissões.
5. Liste até três pontos decisivos para a nota.
6. Indique confiança `alta`, `média` ou `baixa` e explique qualquer limitação de leitura.
