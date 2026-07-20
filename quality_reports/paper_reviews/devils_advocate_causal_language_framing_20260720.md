# Devil's Advocate Report: linguagem causal e estratégia de identificação

## Vulnerabilidade principal

O codebook sustenta interpretar `causal_or_explanatory_claim_present` como pretensão causal ou explicativa: o rótulo é verdadeiro quando o artigo busca explicar causas, efeitos, consequências, determinantes, impactos, influência, mecanismos ou por que algo ocorreu, e falso para descrição ou mera associação. A redação atual, portanto, enfraquece indevidamente o achado ao afirmar que a categoria inclui explicações sem pretensão causal estrita.

O risco oposto é tratar a ausência de uma estratégia explícita codificada como prova de que o artigo não oferece qualquer fundamento causal. A variável mede menção a desenhos de identificação previstos no protocolo, não uma auditoria completa da validade de cada argumento.

## Ataques por dimensão

### Lógica interna

1. O texto afirma simultaneamente que a variável identifica explicações de causas e efeitos e que ela pode não representar pretensão causal.
   - **Severidade**: Alta
   - **Como o autor poderia responder**: definir a variável conforme o codebook e interpretar o resultado como difusão de ambição causal, preservando separadamente a limitação sobre adequação metodológica.

### Evidência empírica

1. Os 1.885 artigos sem estratégia explícita documentam um hiato entre linguagem e adoção de desenhos codificados, mas não demonstram que todos os argumentos sejam inválidos.
   - **Severidade**: Alta
   - **Como o autor poderia responder**: usar “não mencionam estratégia explícita de identificação” e “desenhos que explicitam como a variação identifica o efeito”, evitando “não têm metodologia” ou “não apresentam evidência válida”.

2. A prevalência muito alta da linguagem causal ou explicativa exige futura validação humana da sensibilidade e especificidade do rótulo.
   - **Severidade**: Média
   - **Como o autor poderia responder**: manter a limitação geral sobre classificação automatizada, sem neutralizar a interpretação operacional da variável.

### Escopo e generalização

1. O corpus reúne Ciência Política, Relações Internacionais e um periódico de Administração Pública; “produção brasileira analisada” é mais exato que atribuir cada resultado a toda a Ciência Política brasileira.
   - **Severidade**: Média
   - **Como o autor poderia responder**: reservar a formulação mais ampla para a contribuição disciplinar e qualificar as contagens como referentes aos nove periódicos analisados.

## Ranking de vulnerabilidades

1. Confundir ausência de desenho explícito com ausência de qualquer fundamento causal.
2. Manter no texto uma definição da variável incompatível com o codebook.
3. Generalizar os nove periódicos para toda a disciplina sem qualificação.

## O que sobrevive ao escrutínio

O achado descritivo é forte: a linguagem voltada a explicar causas, efeitos e mecanismos aparece muito mais amplamente do que a inferência estatística e a menção a estratégias explícitas de identificação. A formulação defensável é que a ambição causal se difundiu mais rapidamente que os desenhos metodológicos que tornam explícita a identificação; esse é um resultado central e deve aparecer no resumo, na introdução e nos resultados.
