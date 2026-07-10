## Veredito: NÃO APROVADO

### Bloqueadores

- **Resume ainda não tem validação forte.** O benchmark valida apenas PID, hash e elementos mínimos do reading log ([runner do benchmark](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:168)). Um probe confirmou que uma classificação sem o schema obrigatório é aceita como completa e pode ser pulada no resume ([skip](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:292)). O benchmark deveria reutilizar a validação integral do runner canônico ([validação canônica](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:577)).

- **“Timing completo” não exige timing real.** Basta `label`, `pid` e `status="complete"` ([função](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:271)); timestamps, duração, retorno, modelo e effort podem estar ausentes. O próprio teste considera essa linha mínima válida ([teste](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/test_credibility_model_benchmark.py:71)).

- **Contrato de metadados incompleto.** Há imutabilidade por comparação e hashes, mas a lista hashada ([metadata](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:242)) omite `classifier_prompt_v3.md`, embora ele componha efetivamente cada prompt ([dependência](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:224)). Os task packets também não são hashados nem confrontados com seu conteúdo efetivo.

- **Testes correspondentes incompletos.** Faltam testes de: schema inválido no resume; `--force` quando output existe sem timing; integridade dos campos de timing; imutabilidade/mismatch dos metadados; hashes de todas as entradas; e execução das três combinações quando a primeira falha.

### Confirmado como resolvido

- `service_tier="default"` está fixado e propagado.
- A combinação não usa curto-circuito: as três arms são avaliadas antes de `all()` ([implementação](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:416)); probe confirmou três chamadas.
- O runner canônico ganhou validação forte para outputs salvos e combinação. Não encontrei regressão material nessa alteração.
- O shim `_38` não apresentou problema.

### Verificação

- Sintaxe AST válida nos cinco arquivos.
- 19 testes compatíveis com o sandbox passaram; 14 foram desmarcados.
- A suíte completa não pôde rodar porque o sandbox somente leitura impede `tmp_path`.
- Nenhum arquivo foi editado.