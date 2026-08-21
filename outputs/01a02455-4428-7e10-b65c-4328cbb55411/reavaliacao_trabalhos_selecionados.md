# Reavaliação dos trabalhos selecionados — Métodos III

## Como este relatório será construído

Os trabalhos são relidos, um por vez, por um subagente novo, sem acesso às notas anteriores nem às avaliações dos demais trabalhos. A nota independente segue a mesma rubrica de 0 a 10 para todos. Após cada leitura, registram-se a nota original, a nota independente, a discrepância e a justificativa detalhada. A nota adotada ao final será a nota produzida por esse loop independente.

Este arquivo está em atualização. Até o momento, as reavaliações independentes de Fellipe Pereira, Gabriela Assano, Murilo Souto Maior e Beatriz Pessoni foram concluídas. A seção de Carlos Vergara abaixo amplia a justificativa da nota original 6,5; sua reavaliação cega ainda será feita quando chegar a vez dele no loop.

## Fellipe Matheus Bernardino Pereira — NUSP 11330361

- **Nota original:** 9,8
- **Nota independente:** 9,8
- **Discrepância:** 0,0
- **Nota adotada pelo loop:** 9,8

O relatório identifica a base com 1.038 linhas e 26 variáveis, verifica dados ausentes e códigos anômalos e reproduz corretamente os resultados centrais. Para experiência administrativa, encontra 482 casos entre 524 observações válidas no MAPA e 312 entre 354 no MinC. O primeiro teste produz `p = 0,05716`: portanto, não se rejeita a hipótese de igualdade a 5% ou 1%, mas ela é rejeitada a 10%. Para cargos de alto nível, encontra 187 entre 525 no MAPA e 155 entre 365 no MinC, com `p = 0,03889`, decisão correta a 5%. Também explica corretamente que dobrar a amostra reduz o erro-padrão por um fator de `1/√2`, isto é, cerca de 29,3%. Os pequenos descontos decorrem de não fornecer a referência bibliográfica completa do artigo, de chamar a unidade de análise de “indicação” em vez de nomeação/ocupação de cargo e de não mostrar explicitamente o código de importação e carregamento dos pacotes.

## Gabriela Yumi Fraga Assano — NUSP 14573451

- **Nota original:** 9,8
- **Nota independente:** 9,8
- **Discrepância:** 0,0
- **Nota adotada pelo loop:** 9,8

O relatório identifica corretamente o artigo, as duas pastas e a unidade de análise, além de registrar as 1.038 linhas e 26 colunas da base. A validação informa corretamente os ausentes em `instr`, `exp_adm`, `exp_car`, `nivel` e `indicacao`, embora deixe de mencionar os 17 ausentes em `car_pub`. As proporções de experiência administrativa e os respectivos intervalos de confiança coincidem com as referências: 482/524 no MAPA e 312/354 no MinC. O primeiro teste reporta `p = 0,05716` e toma decisões corretas a 1%, 5% e 10%. A construção da variável de cargo de alto nível, as proporções 187/525 e 155/365 e o segundo teste (`p = 0,03889`) também estão corretos. A explicação sobre o efeito de dobrar a amostra usa corretamente `1/√2`. Os descontos são pequenos: omissão dos ausentes de `car_pub`, numeração duplicada de tabelas e alguns símbolos matemáticos mal renderizados.

## Murilo Rocha Souto Maior — NUSP 13636574

- **Nota original:** 9,8
- **Nota independente:** 9,2
- **Discrepância:** −0,6, classificada como moderada
- **Nota adotada pelo loop:** 9,2

O relatório identifica Albrecht e Ribeiro (2025), MAPA e MinC e explica adequadamente que cada linha representa uma nomeação ou ocupação de cargo, podendo haver repetição de pessoas. Recupera corretamente as 1.038 linhas, 26 colunas, nomes de variáveis e contagens por órgão. O principal desconto está na validação dos dados: o uso isolado de `is.na()` leva o texto a informar `instr = 0`, `exp_adm = 0` e `exp_car = 1` ausentes, embora as tabelas revelem códigos textuais `"NA"`. Há 95 desses códigos em `instr`, 75 em `exp_car`, além de um ausente real, e 11 ausentes reais em `exp_adm`; apenas esta última variável é explicitamente corrigida.

Na análise descritiva, os números estão corretos: MAPA 482/524 = 0,91985 e MinC 312/354 = 0,88136. Os intervalos de confiança calculados na tabela também estão corretos, mas os valores escritos na narrativa não coincidem com os da própria tabela. O primeiro teste preserva o estimando solicitado e produz `p = 0,05716`, com decisões corretas a 10%, 5% e 1%. A variável `alto_nivel` usa corretamente os níveis 5 e 6; os resultados 187/525 e 155/365, o `p = 0,03889` e a interpretação direcional também estão corretos. Ao dobrar a amostra, o relatório obtém corretamente a razão 0,7071 para o erro-padrão. O código e os resultados são legíveis, embora não apareçam os comandos de carregamento dos pacotes.

A discrepância de 0,6 em relação à nota original decorre, portanto, de a releitura independente penalizar de maneira explícita a auditoria incompleta dos códigos textuais de ausência e a inconsistência entre os intervalos de confiança da tabela e da narrativa. Como essa releitura usa a rubrica comum do loop, a nota adotada passa a ser 9,2.

## Beatriz Pessoni — NUSP 15442662

- **Nota original:** 8,8
- **Nota independente:** 8,3
- **Discrepância:** −0,5, classificada como consistente, no limite da faixa
- **Nota adotada pelo loop:** 8,3

O trabalho identifica corretamente a comparação entre MAPA e MinC e a unidade como nomeação ou relação ocupante–cargo observada. Informa 1.038 linhas, 26 colunas, lista as variáveis e inspeciona categorias inválidas. A validação inicial, entretanto, declara `exp_adm = 0`, `instr = 0` e `exp_car = 1` ausentes porque considera o texto `"NA"` uma categoria comum; depois corrige `exp_adm` e `exp_car`, mas não os 95 códigos de `instr` nem verifica os 17 ausentes de `car_pub`.

A tabela descritiva recupera corretamente MAPA 482/524 = 91,98% e MinC 312/354 = 88,14%, com intervalos de Wilson. A narrativa, porém, informa 88,03% e limites ligeiramente diferentes. O primeiro teste usa 309/351 para o MinC, contradizendo a própria tabela, e obtém `p = 0,0519`. A decisão de não rejeitar a 5% permanece igual à referência, mas resulta de dados diferentes dos solicitados. A construção de `alto_nivel` e o segundo teste estão corretos: 187/525, 155/365, `p = 0,0389` e rejeição a 5%. As decisões a 10% e 1% também estão corretas.

Na questão sobre tamanho da amostra, o texto acerta a direção da mudança, mas não explicita o fator `1/√2` e chama 1.025 de dobro de 525, quando o dobro é 1.050. A reprodutibilidade também perde crédito: os objetos `dados2` e `exp_admin` não são definidos no código exibido e a importação depende de caminho local absoluto. A diferença de 0,5 decorre de a releitura independente explicitar essas inconsistências internas e limitações de reprodução. Pela regra do loop, a nota adotada é 8,3.

## Carlos Alberto Vergara — NUSP 3464981

### Nota original: 6,5

A frase curta anterior — “primeiro teste com `p = 0,0014` e contradição entre p-valor e decisão; segundo teste e análise de tamanho amostral corretos” — condensava problemas diferentes. A explicação completa é a seguinte.

### O que o trabalho fez corretamente

Carlos identifica o artigo e a unidade analisada, importa a base e registra corretamente que ela contém 1.038 observações e 26 variáveis. Também examina valores incomuns nas variáveis, constrói uma variável para cargos de alto nível e apresenta tabelas, intervalos de confiança, testes e interpretações substantivas. A segunda parte da análise é, em essência, correta: para cargos de alto nível, encontra 187/525 no MAPA e 155/365 no MinC, obtém `p = 0,0395` — muito próximo da referência `0,03889` — e conclui corretamente que a diferença é significativa a 5% e 10%, mas não a 1%. A análise do tamanho amostral também está correta: ao dobrar `n`, o erro-padrão é multiplicado por `1/√2`, caindo aproximadamente 29,3%.

### Onde surge o erro no primeiro teste

O enunciado pedia comparar, entre MAPA e MinC, a proporção de nomeações com experiência administrativa prévia. Essa comparação exige primeiro definir quais registros são válidos para `exp_adm` e usar somente esses registros no denominador. A referência correta é:

- MAPA: 482 casos com experiência entre 524 observações válidas, ou 91,98%;
- MinC: 312 casos entre 354 observações válidas, ou 88,14%.

No trabalho, porém, o denominador é calculado com `n()`, que inclui observações ausentes ou inválidas, enquanto o numerador usa `sum(..., na.rm = TRUE)`. Além disso, a recodificação não recupera adequadamente todos os códigos válidos. O resultado é 482/525 para o MAPA e apenas 309/365 para o MinC, ou 84,66%. O problema é especialmente grande no MinC: em vez de comparar 312 casos válidos entre 354, o trabalho trata registros não válidos como se contribuíssem para o denominador e perde três respostas positivas na recodificação. Assim, a diferença entre as pastas é artificialmente ampliada de aproximadamente 3,84 para 7,15 pontos percentuais.

Como consequência, o teste produz `p = 0,0014`, quando o teste correspondente ao estimando pedido produz aproximadamente `p = 0,0572`. Isso muda a leitura inferencial: com os dados tratados corretamente, a diferença não é estatisticamente significativa a 5%, embora seja a 10%.

### Por que a conclusão é contraditória

Mesmo tomando `p = 0,0014` como dado, o texto afirma que esse valor é “maior que 0,05” e, por isso, não rejeita a hipótese nula. A comparação numérica está invertida: `0,0014 < 0,05` e também `0,0014 < 0,01`. Portanto, se o p-valor calculado pelo próprio trabalho fosse válido, a hipótese nula deveria ser rejeitada a 10%, 5% e 1%. O relatório, porém, registra simultaneamente:

- não rejeição a 5%;
- rejeição a 10%;
- rejeição a 1%.

Essas decisões não podem coexistir para o mesmo `p = 0,0014`: se um resultado é significativo a 1%, ele necessariamente também é significativo a 5% e 10%. A conclusão final repete a contradição ao dizer que “não há evidência estatística” e, na mesma frase, informar `p = 0,0014`.

### Por que a nota não foi mais baixa — nem mais alta

A nota 6,5 reconhece que o trabalho percorre praticamente todas as etapas solicitadas: apresenta a base e o artigo, faz análise descritiva, formula testes, produz intervalos de confiança, executa corretamente o segundo teste, discute níveis de significância e responde corretamente à questão sobre tamanho amostral. Não é, portanto, um trabalho incompleto.

Ao mesmo tempo, o primeiro teste era uma parte central da tarefa. Nele, o trabalho altera o denominador e, portanto, o próprio estimando que deveria ser analisado; obtém um p-valor muito distante do resultado correto; compara esse p-valor incorretamente com os níveis de significância; e apresenta decisões internamente incompatíveis. Esses não são apenas deslizes de redação: afetam os dados utilizados, o resultado do teste e sua interpretação. Por isso, o desempenho correto na segunda metade e na discussão do erro-padrão sustenta uma nota acima de 5, mas os erros encadeados no primeiro teste impedem uma nota na faixa de 8 ou mais.

**Situação:** esta é a explicação ampliada da nota original. A nota independente e a eventual discrepância serão acrescentadas aqui após a leitura cega de Carlos no loop sequencial.

## Iterações ainda pendentes

As demais reavaliações serão incluídas neste mesmo arquivo, uma por vez, na ordem do loop.
