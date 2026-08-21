# Reavaliações independentes — loop sequencial

## Protocolo

Cada trabalho é lido por um subagente novo, sem acesso às notas anteriores, às planilhas de avaliação ou aos resultados de outros alunos. Todos usam a mesma rubrica de oito critérios, totalizando 10 pontos. Este arquivo registra apenas os resultados independentes. A comparação com as notas originais será feita depois que o loop terminar.

## Fellipe Matheus Bernardino Pereira — NUSP 11330361

- **Subnotas:** C1 0,70/0,75; C2 1,50/1,50; C3 1,75/1,75; C4 1,50/1,50; C5 1,75/1,75; C6 0,75/0,75; C7 0,50/0,50; C8 1,35/1,50.
- **Soma e nota normalizada:** 9,80/10; **9,8**.
- **Confiança:** alta.

O relatório identifica a base com 1.038 linhas e 26 variáveis, verifica dados ausentes e códigos anômalos e reproduz corretamente os resultados centrais. Para experiência administrativa, encontra 482 casos entre 524 observações válidas no MAPA e 312 entre 354 no MinC. O primeiro teste produz `p = 0,05716`: não se rejeita a hipótese de igualdade a 5% ou 1%, mas ela é rejeitada a 10%. Para cargos de alto nível, encontra 187 entre 525 no MAPA e 155 entre 365 no MinC, com `p = 0,03889`, decisão correta a 5%. Também explica corretamente que dobrar a amostra reduz o erro-padrão por `1/√2`, cerca de 29,3%. Os pequenos descontos decorrem de não fornecer a referência bibliográfica completa, chamar a unidade de “indicação” em vez de nomeação/ocupação e não mostrar explicitamente o código de importação e carregamento de pacotes.

## Gabriela Yumi Fraga Assano — NUSP 14573451

- **Subnotas:** C1 0,75/0,75; C2 1,40/1,50; C3 1,75/1,75; C4 1,50/1,50; C5 1,75/1,75; C6 0,75/0,75; C7 0,50/0,50; C8 1,40/1,50.
- **Soma e nota normalizada:** 9,80/10; **9,8**.
- **Confiança:** alta.

O relatório identifica corretamente artigo, pastas e unidade de análise, além de registrar as 1.038 linhas e 26 colunas. Informa corretamente os ausentes em `instr`, `exp_adm`, `exp_car`, `nivel` e `indicacao`, mas não menciona os 17 ausentes de `car_pub`. As proporções de experiência administrativa e os intervalos coincidem com as referências: 482/524 no MAPA e 312/354 no MinC. O primeiro teste reporta `p = 0,05716` e toma decisões corretas a 1%, 5% e 10%. A construção de `alto_nivel`, as proporções 187/525 e 155/365 e o segundo teste (`p = 0,03889`) também estão corretos. A explicação sobre dobrar a amostra usa corretamente `1/√2`. Os descontos decorrem da omissão de `car_pub`, numeração duplicada de tabelas e alguns símbolos matemáticos mal renderizados.

## Murilo Rocha Souto Maior — NUSP 13636574

- **Subnotas:** C1 0,75/0,75; C2 1,00/1,50; C3 1,55/1,75; C4 1,50/1,50; C5 1,75/1,75; C6 0,75/0,75; C7 0,50/0,50; C8 1,35/1,50.
- **Soma e nota normalizada:** 9,15/10; **9,2**.
- **Confiança:** alta.

O relatório identifica artigo, pastas e unidade, e recupera 1.038 × 26. O principal desconto está na validação: `is.na()` leva o texto a informar `instr = 0`, `exp_adm = 0` e `exp_car = 1`, embora existam códigos textuais `"NA"`: 95 em `instr`, 75 em `exp_car`, além de um ausente real, e 11 ausentes reais em `exp_adm`; somente `exp_adm` é explicitamente corrigida. As contagens e proporções são corretas: MAPA 482/524 e MinC 312/354. Os intervalos na tabela estão corretos, mas a narrativa apresenta valores diferentes. O teste 1 (`p = 0,05716`), as decisões por nível de significância, a construção de `alto_nivel`, o teste 2 (`p = 0,03889`) e a razão 0,7071 para o erro-padrão estão corretos. Não aparecem os comandos de carregamento dos pacotes.

## Beatriz Pessoni — NUSP 15442662

- **Subnotas:** C1 0,75/0,75; C2 1,10/1,50; C3 1,65/1,75; C4 1,00/1,50; C5 1,75/1,75; C6 0,75/0,75; C7 0,35/0,50; C8 0,90/1,50.
- **Soma e nota normalizada:** 8,25/10; **8,3**.
- **Confiança:** alta.

O trabalho identifica corretamente comparação e unidade, informa 1.038 × 26 e inspeciona categorias inválidas. A validação trata `"NA"` como categoria; depois corrige `exp_adm` e `exp_car`, mas não os 95 códigos de `instr` nem verifica os 17 ausentes de `car_pub`. A tabela recupera MAPA 482/524 e MinC 312/354, com intervalos de Wilson, mas a narrativa informa 88,03% e limites diferentes. O primeiro teste usa incorretamente 309/351 no MinC, contradizendo a tabela; `p = 0,0519` ainda leva à não rejeição a 5%. A recodificação de `alto_nivel` e o teste 2 estão corretos: 187/525, 155/365 e `p = 0,0389`. As decisões a 10% e 1% também estão corretas. A questão amostral acerta a direção, mas não mostra `1/√2` e chama 1.025 de dobro de 525. O código não é autocontido: `dados2` e `exp_admin` não são definidos e o caminho é local absoluto.

## Lara Nunes de Lacerda — NUSP 14586921

- **Subnotas:** C1 0,75/0,75; C2 1,30/1,50; C3 1,65/1,75; C4 1,50/1,50; C5 1,65/1,75; C6 0,65/0,75; C7 0,50/0,50; C8 1,40/1,50.
- **Soma e nota normalizada:** 9,40/10; **9,4**.
- **Confiança:** alta.

A identificação do artigo, das pastas e da unidade de análise está correta. A leitura informa 1.038 linhas, 26 colunas, variáveis e os principais ausentes, incluindo `exp_adm = 11`, `exp_car = 76`, `instr = 95` e `car_pub = 17`. Há tratamento de códigos problemáticos, mas não se registram expressamente `nivel = 0` e `indicacao = 0`, e converter `exp_car = 5` para 3 é parcialmente conjectural. Para `exp_adm`, os resultados estão corretos: MAPA 482/524 e MinC 312/354. Os intervalos de Wald são coerentes, mas a descrição como “95% de certeza” e “5% de erro” é imprecisa. O primeiro teste preserva o estimando, obtém diferença −0,03849 e `p = 0,0573`. `alto_nivel`, as proporções 35,62% e 42,47%, a diferença 0,06847 e `p = 0,0389` também estão corretos, embora “comprovar” seja excessivo e a segunda tabela não apareça. As decisões a 10% e 1% são corretas, mas não rejeitar não permite afirmar igualdade. A redução do erro-padrão por `1/√2`, de 0,02022 para 0,01429, está correta.

## Luiz Antonio Eleutério de Lima — NUSP 14759962

- **Subnotas:** C1 0,75/0,75; C2 0,90/1,50; C3 1,40/1,75; C4 1,30/1,50; C5 1,10/1,75; C6 0,75/0,75; C7 0,40/0,50; C8 1,10/1,50.
- **Soma e nota normalizada:** 7,70/10; **7,7**.
- **Confiança:** alta; avaliação restrita ao conteúdo do PDF, sem executar os arquivos-fonte mencionados.

O relatório acerta a identificação do artigo, das pastas e da nomeação como unidade de análise. Informa corretamente 1.038 linhas, 26 colunas e frequências por órgão. A validação, porém, é internamente inconsistente: a Tabela 3 registra zero ausentes em `instr` e `exp_adm` e somente um em `exp_car`, enquanto o texto posterior encontra corretamente 95, 11 e 76. A limpeza exclui códigos tipográficos de `exp_adm` que deveriam ser normalizados, reduzindo indevidamente o MinC a 351 observações e 309 sucessos, em vez de 354 e 312. Isso afeta a descritiva e o primeiro teste, embora proporções, intervalos e `p = 0,05187` permaneçam próximos e a decisão a 5% seja correta. Para `alto_nivel`, construção, contagens, proporções e `p = 0,03889` estão corretos; contudo, o texto primeiro rejeita H0 e logo depois afirma o oposto, uma contradição decisória importante, e não julga claramente a magnitude substantiva. As decisões a 10% e 1% estão corretas. Ao dobrar a amostra, demonstra uma redução aproximadamente compatível com `1/√2`, mas não explicita esse fator. O PDF documenta scripts, fonte e execução, embora contenha repetições e contradições.

## Mariana Rodrigues Carneiro Silva — NUSP 14596738

- **Subnotas:** C1 0,70/0,75; C2 0,75/1,50; C3 0,90/1,75; C4 0,50/1,50; C5 1,75/1,75; C6 0,40/0,75; C7 0,30/0,50; C8 1,00/1,50.
- **Soma e nota normalizada:** 6,30/10; **6,3**.
- **Confiança:** alta. O número USP não aparece no PDF; foi associado pelo diretório da entrega.

O relatório identifica adequadamente artigo, ministérios e unidade de análise, informa 1.038 × 26 e lista as variáveis. O problema central é a limpeza: `colSums(is.na())` contabiliza somente ausências lógicas e retorna 0/1/0 para `exp_adm`/`exp_car`/`instr`, embora as tabelas exibam códigos textuais ou inválidos; `car_pub` não é verificada. O texto afirma que recodificaria os valores, mas o código não executa essa etapa. Isso contamina as questões 3 e 4: usa MAPA n = 525, x = 482, p = 0,9181 e MinC n = 365, x = 309, p = 0,8466, em vez de n = 524/354, x = 482/312 e p ≈ 0,9199/0,8814. O teste 1 produz `p = 0,000845`, incompatível com a referência `p ≈ 0,057`, que implica rejeição somente a 10%. Em contraste, `alto_nivel` é construído corretamente; as proporções 0,3562 e 0,4247 e `p = 0,03889` sustentam rejeição a 5%, mas não a 1%. A discussão de alfa é conceitualmente correta, porém não decide explicitamente os dois testes. A questão sobre amostra maior acerta direção e estreitamento do intervalo, mas omite `1/√2` e a redução de 29,3%. Código e saídas são legíveis, embora a limpeza anunciada não seja executada.

## Julia Raphaela de Moura Magalhães — NUSP 14654997

- **Subnotas:** C1 0,75/0,75; C2 1,00/1,50; C3 1,50/1,75; C4 0,90/1,50; C5 0,00/1,75; C6 0,25/0,75; C7 0,30/0,50; C8 0,70/1,50.
- **Soma e nota normalizada:** 5,40/10; **5,4**.
- **Confiança:** alta.

O relatório identifica corretamente artigo, pastas e unidade de análise e explica por que a mesma pessoa pode aparecer mais de uma vez. Registra 1.038 linhas, 26 colunas, variáveis e observações por órgão. Contudo, a estudante declara não ter conseguido calcular os valores ausentes, componente central da validação. Há tratamento parcial de código inválido, convertendo `exp_adm = 3` em ausente. Na descritiva, a tabela apresenta corretamente MAPA n = 524, x = 482, p = 0,920 e MinC n = 354, x = 312, p = 0,881, além de intervalos aproximadamente corretos. A narrativa, porém, troca essas proporções por 91,5% e 85,5%, inconsistentes com a própria tabela. No primeiro teste, `p = 0,05716`, a direção e a rejeição a 10% estão corretos, mas o texto contraditoriamente afirma rejeição a 5%; a decisão a 1% fica incompleta. Não há construção de `alto_nivel` nem segundo teste. Sobre ampliar a amostra, reconhece a redução do erro-padrão, mas não apresenta `1/√2` e afirma proporcionalidade inversa direta a n. O código é fragmentário.

## Mariana Araujo Püschel — NUSP 4725594

- **Subnotas:** C1 0,75/0,75; C2 0,95/1,50; C3 0,55/1,75; C4 0,45/1,50; C5 0,25/1,75; C6 0,15/0,75; C7 0,20/0,50; C8 0,85/1,50.
- **Soma e nota normalizada:** 4,15/10; **4,2**.
- **Confiança:** alta.

Há acertos na identificação do estudo e da unidade: nomeações em MAPA e MinC, com possível repetição do indivíduo. A leitura registra 1.038 linhas, 26 colunas, variáveis e vários totais de ausências, além de códigos inesperados em `exp_adm`. Contudo, não trata esses códigos adequadamente e confunde as escalas de `exp_car` e `nivel`. Na descritiva, combina `exp_adm` e `exp_car` e converte ausências ou erros em ausência de experiência, produzindo MinC 309/365 = 0,8466, em vez de 312/354 = 0,8814, e MAPA 483/525 com denominador incorreto. O teste 1 retorna `p = 0,000569` e rejeita a 5%, quando o teste correto tem `p ≈ 0,057` e não rejeita a 5%. No segundo bloco, `alto_nivel` é derivada de `exp_car`, não de `nivel = 5/6`, alterando proporções, direção e p-valor: 0,3987, em vez de aproximadamente 0,0389. As decisões a 10% e 1% ficam erradas e a discussão inverte a exigência dos limiares. A apresentação é organizada, mas falta código reprodutível das recodificações-chave. Ao dobrar n, mantém os sucessos fixos e não demonstra a redução por `1/√2`.

## Francisco Zardo de Melo — NUSP 15452656

- **Subnotas:** C1 0,75/0,75; C2 1,25/1,50; C3 0,90/1,75; C4 0,30/1,50; C5 1,60/1,75; C6 0,40/0,75; C7 0,30/0,50; C8 0,95/1,50.
- **Soma e nota normalizada:** 6,45/10; **6,5**.
- **Confiança:** alta.

O relatório identifica corretamente artigo, MAPA/MinC e a nomeação observada como unidade, registra 1.038 × 26 e lista as variáveis. A inspeção de ausências é parcialmente adequada: aparecem `instr = 95`, `exp_adm = 11`, `nivel = 0`, `indicacao = 0` e `car_pub = 17`; `exp_car` surge fragmentada em 75 textos `"NA"` e um `<NA>`, sem consolidar 76. Após detectar códigos inválidos de `exp_adm`, não os retira dos denominadores. A tabela usa n = 525/365, em vez de 524/354. Embora x = 482/312 esteja correto, proporções e intervalos ficam errados, sobretudo no MinC. O teste 1 passa a ter diferença de 6,33 pontos percentuais e `p = 0,00275`, em vez de aproximadamente 3,85 e `p = 0,057`; a rejeição a 5% é incorreta. Também faltam H0/H1, comando do teste e interpretação probabilística do p-valor. O segundo teste está essencialmente correto: 187/525, 155/365 e `p = 0,0389`. A discussão de 1% mistura 1% com 0,1% e apresenta desigualdade incoerente. Ao dobrar n, acerta a direção, mas não fornece `EP/√2` nem a redução de 29,3%. O relatório é legível e indica a fonte, porém não exibe código suficiente para reprodução plena.

## Gustavo Lopes Rangel Madureira — NUSP 15457821

- **Subnotas:** C1 0,75/0,75; C2 0,65/1,50; C3 0,60/1,75; C4 0,35/1,50; C5 1,75/1,75; C6 0,45/0,75; C7 0,30/0,50; C8 1,05/1,50.
- **Soma e nota normalizada:** 5,90/10; **5,9**.
- **Confiança:** alta.

O relatório identifica adequadamente artigo, MAPA, MinC e a unidade de análise e informa corretamente 1.038 linhas e 26 colunas. A validação, porém, confunde textos `"NA"` com ausências reais: declara `exp_adm = 0`, `instr = 0` e `exp_car = 1`, quando os totais são 11, 95 e 76, e não verifica `car_pub`. A recodificação deixa de reconhecer três ocorrências de `` `1 ``. A descritiva usa `n()` como denominador bruto e apresenta MAPA n = 525, x = 482 e MinC n = 365, x = 309, em vez de 524/482 e 354/312. Também faltam os intervalos de confiança. No primeiro teste, a tabela mostra 0,8803 para o MinC, mas `prop.test` usa 309/365 = 0,8466, produzindo `p = 0,001241` em vez de aproximadamente 0,057; as rejeições a 5% e 1% ficam erradas. Em contraste, `alto_nivel` é construído corretamente, com 187/525 e 155/365, e o segundo teste (`p = 0,04601`) é bem interpretado. A discussão de amostra maior acerta a direção do erro-padrão, mas omite `1/√2` e a redução de 29,3%.
