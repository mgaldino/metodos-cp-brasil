APROVADO

# Parecer independente — cobertura da classificação de credibilidade

## Escopo

Revisão somente leitura de `scripts/42_report_credibility_classification_coverage.R`, `data/processed/excluded_articles.csv` e dos outputs `quality_reports/credibility_classification_coverage_by_journal.csv` e `.md`, com foco em denominadores, joins, duplicatas, aplicação exclusiva da nova exclusão e coerência dos totais.

## Verificações realizadas

- **Denominador:** o universo é corretamente definido pelo manifesto integral. O manifesto contém 5.250 linhas, 5.250 PIDs distintos, nenhum PID ausente e nenhum periódico ausente.
- **Joins:** o script parte do manifesto e usa `left_join()` por `pid`, preservando o universo. As classificações são reduzidas a PIDs distintos antes do join. O ledger tem PIDs únicos entre as exclusões ativas. Portanto, nas entradas atuais, nenhum dos joins multiplica linhas.
- **Duplicatas e PIDs órfãos:** o arquivo combinado contém 1.598 linhas e 1.598 PIDs distintos; nenhum PID classificado está fora do manifesto. O ledger contém sete exclusões ativas, todas com PIDs distintos.
- **Aplicação exclusiva da nova exclusão:** das sete exclusões ativas do ledger, seis não pertencem ao manifesto integral examinado e, por isso, não afetam este relatório. Somente `S0101-33002006000200005`, a nova linha do ledger, está presente no manifesto. Esse PID aparece uma única vez em `Novos estudos CEBRAP` e não aparece nas classificações.
- **Contrafactual da nova exclusão:** sem essa nova linha, os totais seriam 5.250 elegíveis, 1.598 classificados e 3.652 faltantes. Com ela, passam corretamente a 5.249 elegíveis, 1.598 classificados e 3.651 faltantes. Logo, a alteração reduz apenas o denominador elegível e os faltantes em uma unidade; não altera classificados nem qualquer outro periódico.
- **Coerência por periódico:** em `Novos estudos CEBRAP`, 582 registros do manifesto menos uma exclusão resultam em 581 elegíveis; 132 estão classificados e 449 faltam. Para todos os 11 periódicos, vale `elegíveis = classificados + faltantes`.
- **Coerência global:** `5.250 = 1 + 5.249` e `5.249 = 1.598 + 3.651`. As somas do CSV por periódico reproduzem esses totais, e o Markdown reproduz corretamente o CSV. Percentuais e status também estão coerentes com a regra declarada.

## Conclusão

Não foram identificados erros que afetem os resultados. A nova exclusão foi aplicada exclusivamente ao PID pretendido e os outputs são coerentes com os dados de entrada e com a lógica implementada.

## Observação não bloqueante

O join com o ledger pressupõe unicidade futura de `pid`; essa condição é satisfeita no arquivo atual. Uma validação explícita de unicidade no script poderia transformar o pressuposto em falha antecipada, mas sua ausência não compromete os outputs revisados.
