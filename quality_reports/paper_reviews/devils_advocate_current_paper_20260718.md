# Devil's Advocate da atualização canônica

**Data:** 18 de julho de 2026  
**Veredito final após reparos:** PASS  
**Modo:** somente leitura; nenhum arquivo foi editado pelo parecerista.

## Vulnerabilidades identificadas na primeira rodada

1. O headline misturava o estrato completo com cobertura parcial: 49/1.116 (4,4%), embora os 49 positivos estivessem nos seis periódicos completos, com 49/846 (5,8%).
2. Os 270 casos examinados nos periódicos parciais continham zero positivos, padrão compatível tanto com diferenças substantivas quanto com efeito de lote/classificador.
3. A conclusão de expansão da quantificação dependia da ponderação e era fortemente influenciada pela RBCP.
4. A expressão “suporte temporal comum” era imprecisa para os três períodos agregados, pois o suporte anual comum começa em 2011.
5. A cobertura integral dos artigos não poderia ser confundida com certeza dos rótulos automatizados.
6. A variável de linguagem causal ou explicativa era ampla demais para ser interpretada como pretensão causal estrita.

## Reparos verificados

- O abstract, a introdução e a conclusão usam 49/846 (5,8%) como resultado principal.
- O agregado 49/1.116 (4,4%) aparece apenas como referência da cobertura parcial.
- A discussão explicita a decomposição 49/846 versus 0/270 e o possível efeito de lote/classificador.
- A tabela de sensibilidade passou a comparar ponderações para quantificação e inferência estatística.
- O texto qualifica a quantificação como aproximadamente estável quando os artigos são agrupados e mostra a influência da RBCP na média equiponderada.
- A comparação principal usa “presentes nos três períodos agregados”; a série anual permanece restrita a 2011--2025.
- O texto explicita que CGPC contribui apenas em 2019--2025.
- A cobertura integral é distinguida da validação dos rótulos.
- Os cinco rótulos ausentes de inferência recebem bounds de 37,8% a 38,1%.
- A linguagem causal ou explicativa foi rebaixada a diagnóstico amplo, sem interpretação de desalinhamento causal.

## Limitações remanescentes reconhecidas no paper

- Validação humana ainda incompleta.
- Possível efeito de lote/configuração do classificador.
- Presença nominal de método não mede qualidade da execução nem validade da identificação.

Nenhum bloqueador permaneceu para este snapshot preliminar.
