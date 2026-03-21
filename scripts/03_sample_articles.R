## 03_sample_articles.R
## Amostra estratificada de ~240 artigos por período e revista
## Para validação manual da classificação LLM

library(tidyverse)

set.seed(42)

df <- read_csv("data/raw/articles_2005_2025.csv", show_col_types = FALSE)

# Criar períodos de 5 anos (último com 6)
df <- df |>
  mutate(periodo = case_when(
    year >= 2005 & year <= 2009 ~ "2005-2009",
    year >= 2010 & year <= 2014 ~ "2010-2014",
    year >= 2015 & year <= 2019 ~ "2015-2019",
    year >= 2020 & year <= 2025 ~ "2020-2025"
  ))

# 4 artigos por estrato (período × revista), ou menos se o estrato for menor
amostra <- df |>
  group_by(periodo, journal_title) |>
  slice_sample(n = 4) |>
  ungroup()

# Verificar
cat("Total na amostra:", nrow(amostra), "\n\n")

cat("Por período:\n")
amostra |> count(periodo) |> print()

cat("\nPor revista:\n")
amostra |> count(journal_title, sort = TRUE) |> print(n = 20)

cat("\nEstratoscom menos de 4:\n")
amostra |> count(periodo, journal_title) |> filter(n < 4) |> print(n = 30)

# Salvar
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(amostra, "data/processed/sample_validation.csv")
cat("\nSalvo em data/processed/sample_validation.csv\n")
