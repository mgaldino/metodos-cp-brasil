#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
input_file="${repo_dir}/notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.md"
output_file="${repo_dir}/notes/lit_review_metodos_inferencia_credibilidade_cp_brasil.html"

cd "${repo_dir}/notes"

pandoc \
  "$(basename "${input_file}")" \
  --citeproc \
  --standalone \
  --toc \
  --toc-depth=3 \
  --metadata title="Revisão de literatura: métodos, inferência e credibilidade na Ciência Política brasileira" \
  --output "$(basename "${output_file}")"

printf '%s\n' "HTML gerado em ${output_file}"
