Há bloqueadores. Não recomendo executar o benchmark real antes de corrigi-los.

## Bloqueadores

- **Checkpoint aceita outputs inválidos apenas porque os arquivos existem.** `is_complete()` não valida PID, `input_text_hash`, status ou schema; o runner-base repete a mesma lógica. Além disso, `combine-only` retorna sucesso mesmo com casos ausentes. Assim, um resume pode reutilizar classificação de outro texto, omitir um caso e ainda encerrar com código 0. Referências: [38_run...py:143](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:143), [38_run...py:201](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:201), [25_run...py:501](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:501), [25_run...py:582](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:582), [25_run...py:731](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:731).

- **Resume pode produzir benchmark completo sem timing completo.** A linha de timing só é gravada depois que o subprocesso termina. Se o runner salvar os JSONs e o wrapper for interrompido antes de registrar o tempo, o resume detectará os arquivos, fará `SKIP` e nunca reconstruirá o timing. Não existe gate exigindo 30 combinações configuração–PID com timing bem-sucedido. Referências: [38_run...py:201](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:201), [38_run...py:216](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:216), [38_run...py:236](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:236).

## Severidade alta

- **A velocidade declarada não é fixada.** Modelo e esforço são passados corretamente nos três braços, mas o comando não fixa `service_tier`; ele herda a configuração global enquanto os metadados afirmam “standard/default”. Hoje o ambiente local está em `service_tier = "default"`, porém isso não é reproduzível em outra máquina ou após mudança de configuração. Referências: [38_run...py:117](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:117), [38_run...py:178](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:178), [25_run...py:586](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:586).

- **Metadados podem descrever incorretamente uma execução retomada.** `benchmark_metadata.json` é sobrescrito em todo `--run`, sem conferir manifesto/configuração preexistentes e sem hashes do manifesto, scripts, prompt/schema ou versão do Codex. Outputs antigos podem ser misturados com novos e atribuídos integralmente à configuração atual. Referências: [38_run...py:173](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:173), [38_run...py:294](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:294).

## Severidade média

- **A combinação final usa `all()` com curto-circuito.** Se o primeiro braço falhar ao combinar, os braços seguintes nem sequer são combinados. Referência: [38_run...py:314](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/38_run_credibility_model_benchmark.py:314).

- **Testes insuficientes para os riscos principais.** Os quatro testes cobrem rotação, montagem de um único braço e caminho de output, mas não cobrem resume, hashes divergentes, JSON corrompido, interrupção entre output e timing, metadados incompatíveis, subprocesso falho ou combinação incompleta. Referência: [test_credibility...py:8](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/test_credibility_model_benchmark.py:8). Os três arquivos do benchmark também estão ainda não rastreados pelo Git.

## Verificações positivas

- As três configurações geram os comandos declarados de modelo/esforço.
- O diretório `full_corpus_ab` e os stems específicos protegem o combinado canônico no fluxo normal.
- O shim de importação funciona.
- Sintaxe, importação e dry-run passaram; as quatro funções de teste existentes passaram por invocação direta. O `pytest` completo não pôde iniciar porque o ambiente read-only não oferece diretório temporário gravável.
- Nenhum arquivo foi editado e nenhum benchmark real foi executado.

