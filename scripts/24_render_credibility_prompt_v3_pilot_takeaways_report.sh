#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=pt_BR.UTF-8
export LANG=pt_BR.UTF-8

Rscript --vanilla scripts/24_make_credibility_prompt_v3_pilot_takeaways_report.R
