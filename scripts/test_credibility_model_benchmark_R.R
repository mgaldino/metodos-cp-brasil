## Teste end-to-end do comparador com braços sintéticos idênticos ao baseline.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
manifest_path <- file.path(
  project_dir, "data", "processed", "credibility_prompt_v3_full_corpus",
  "batch_manifests", "ab_gpt56_models_10.csv"
)
baseline_path <- file.path(
  project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
  "full_corpus", "combined", "classifications_integral_reading.csv"
)
baseline_reading_dir <- file.path(
  project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
  "full_corpus", "reading_logs"
)

test_root <- tempfile("credibility_model_benchmark_test_")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)

manifest <- readr::read_csv(
  manifest_path,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
)
baseline <- readr::read_csv(
  baseline_path,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
) |>
  dplyr::semi_join(manifest |> dplyr::select(pid), by = "pid")

configs <- data.frame(
  label = c("sol_medium", "terra_medium", "terra_xhigh"),
  model = c("gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-terra"),
  effort = c("medium", "medium", "xhigh")
)

for (label in configs$label) {
  combined_dir <- file.path(test_root, label, "combined")
  reading_dir <- file.path(test_root, label, "reading_logs")
  dir.create(combined_dir, recursive = TRUE)
  dir.create(reading_dir, recursive = TRUE)
  readr::write_csv(
    baseline,
    file.path(
      combined_dir,
      paste0("classifications_integral_reading_", label, "_10.csv")
    ),
    na = ""
  )
  for (pid in manifest$pid) {
    copied <- file.copy(
      file.path(baseline_reading_dir, paste0(pid, ".json")),
      file.path(reading_dir, paste0(pid, ".json"))
    )
    if (!copied) {
      stop("Falha ao copiar reading log de teste: ", pid)
    }
  }
}

timings <- tidyr::crossing(
  label = configs$label,
  pid = manifest$pid
) |>
  dplyr::left_join(configs, by = "label") |>
  dplyr::mutate(
    attempt = 1L,
    started_at_utc = "2026-07-10T12:00:00+00:00",
    finished_at_utc = "2026-07-10T12:01:00+00:00",
    elapsed_seconds = dplyr::case_when(
      label == "sol_medium" ~ 60,
      label == "terra_medium" ~ 40,
      TRUE ~ 50
    ),
    return_code = 0L,
    status = "complete"
  ) |>
  dplyr::select(
    label,
    model,
    effort,
    pid,
    attempt,
    started_at_utc,
    finished_at_utc,
    elapsed_seconds,
    return_code,
    status
  )
readr::write_csv(timings, file.path(test_root, "benchmark_timings.csv"))

out_report <- file.path(test_root, "report.md")
out_comparison <- file.path(test_root, "comparison.csv")
command <- c(
  "--vanilla",
  file.path(project_dir, "scripts", "39_compare_credibility_model_benchmark.R"),
  "--benchmark-root", test_root,
  "--manifest", manifest_path,
  "--baseline", baseline_path,
  "--timings", file.path(test_root, "benchmark_timings.csv"),
  "--out-report", out_report,
  "--out-comparison", out_comparison
)
status <- system2("Rscript", command)
if (status != 0 || !file.exists(out_report) || !file.exists(out_comparison)) {
  stop("Comparador R falhou no teste end-to-end.")
}

comparison <- readr::read_csv(out_comparison, show_col_types = FALSE)
new_rows <- comparison |>
  dplyr::filter(label %in% configs$label)
if (nrow(new_rows) != 3 || any(new_rows$n_complete != 10)) {
  stop("Comparador não preservou os três braços completos.")
}
if (any(new_rows$mean_field_agreement != 1)) {
  stop("Braços sintéticos idênticos ao baseline deveriam ter concordância 100%.")
}

cat("Teste end-to-end R: PASS\n")
