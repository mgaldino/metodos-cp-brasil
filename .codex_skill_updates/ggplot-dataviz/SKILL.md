---
name: ggplot-dataviz
description: Create, audit, and improve publication-ready data visualizations in R with ggplot2. Use when Codex needs to design a chart, choose a visualization type, write or revise ggplot2 code, export figures for papers/reports/slides, audit an existing plot for graphical integrity, or run exploratory visual checks. Triggers include requests for ggplot2, plots, charts, graphs, figures, visualizacao de dados, graficos, chart choice, data visualization, publication figures, figure audit, captions, axis labels, color palettes, confidence intervals, small multiples, or Tufte-style critique.
---

# ggplot2 Dataviz

Use this skill to produce or review academic data visualizations that are honest, legible, reproducible, and ready for PDF reports, papers, presentations, or appendices.

Default to R and `ggplot2`. Keep substantive data transformations in versioned R scripts when working inside a repo. Do not treat a plot as finished until it has been exported and checked in its target format.

If the user asks specifically to write, revise, audit, or standardize figure captions/legends without changing the figure, use the `figure-captions` skill. If the user asks to create or revise the figure itself, use this skill and apply the `figure-captions` rules at finalization.

## Mode Selection

Choose one mode first:

1. **Exploratory mode**: inspect distributions, missingness, outliers, relationships, time patterns, or model assumptions. Read `references/exploratory-checks.md`.
2. **Production mode**: create a final figure for a report, paper, PDF, slide, or appendix. Read `references/chart-choice.md`, `references/publication-output.md`, and any relevant quality reference.
3. **Audit mode**: critique or fix an existing plot, image, or ggplot2 script. Read `references/quality-gates.md` and `references/graphical-integrity.md`.

If the user asks for a figure without specifying the mode, use production mode after a brief data inspection.

## Workflow

1. Clarify the analytical job from available context:
   - What comparison, trend, distribution, relationship, composition, map, or uncertainty must the figure show?
   - What is the unit of analysis and what is the denominator?
   - Who is the audience and where will the figure appear?
2. Inspect the data before plotting:
   - Check variable types, ranges, missingness, duplicates where relevant, impossible dates, impossible signs/counts, and outliers.
   - Preserve raw data and put nontrivial transformations in a script, not in an interactive one-off command.
3. Select the chart type:
   - Use `references/chart-choice.md` when the plot type is not obvious.
   - Prefer direct comparisons, small multiples, and uncertainty-aware designs over decorative or over-aggregated charts.
4. Write reproducible ggplot2 code:
   - Use explicit `ggplot2::`, `dplyr::select()`, and clear object names.
   - Include labels, units, caption/source notes, and interpretable scales.
   - Use accessible palettes and redundant encodings when color carries meaning.
5. Export the figure:
   - Prefer vector output (`.pdf` or `.svg`) for line art and statistical graphics.
   - Use explicit `width`, `height`, `units`, and `dpi` when raster output is required.
   - Consider sourcing `scripts/ggplot_academic_theme.R` for common theme, palette, and export helpers.
6. Validate before delivery:
   - Apply the relevant checks in `references/quality-gates.md`.
   - Use `scripts/check_plot_artifact.R` for basic file-format and size checks when a file was exported.
   - Apply the caption checks in `references/publication-output.md` or the `figure-captions` skill when the figure will appear in a manuscript, report, or slide deck.
   - Report what was checked and what remains untested.

## R Conventions

- Use `ggplot2` as the plotting system unless the user explicitly requests another library.
- Use `dplyr::select()` when selecting columns.
- Put reusable or substantive plotting code in `scripts/R/` or the local project convention.
- Save generated figures in the project's figure/output directory, not only in the R graphics device.
- Number and caption tables/figures in reports when the figure is part of a manuscript or PDF deliverable.
- Do not add significance stars by default. Show uncertainty directly and explain the estimand, interval, sample size, or statistic.

## Resource Guide

- `references/chart-choice.md`: choose a chart type from the analytical task.
- `references/exploratory-checks.md`: quick diagnostic plots and data sanity checks.
- `references/accessibility.md`: colorblind-safe palettes, grayscale robustness, and redundant encodings.
- `references/statistical-rigor.md`: uncertainty, denominators, aggregation, and inference display.
- `references/graphical-integrity.md`: Tufte-inspired eraser, collision, lie-factor, and data-density checks.
- `references/publication-output.md`: file formats, dimensions, captions, fonts, and `ggsave()`.
- `references/quality-gates.md`: final checklist for create and audit workflows.
- `figure-captions` skill: standalone caption/legend writing, source notes, figure numbering, and caption audits.
- `scripts/ggplot_academic_theme.R`: optional ggplot2 helpers for theme, palettes, and export.
- `scripts/check_plot_artifact.R`: command-line file check for exported figures.
