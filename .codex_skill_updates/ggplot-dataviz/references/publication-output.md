# Publication Output

Final figures must be exported and checked in the intended medium.

## Formats

- Prefer `.pdf` or `.svg` for statistical graphics and line art.
- Use `.png` for slides, web previews, or raster-only workflows.
- Avoid JPEG for scientific/statistical figures.
- Use high DPI only for raster output; vector output does not need DPI for lines and text.

## Dimensions

Use explicit dimensions. Good starting points:

- Paper single-column: 3.25 to 3.5 in wide.
- Paper double-column or report figure: 6.5 to 7.0 in wide.
- Slide 16:9: about 10 x 5.625 in.

Adjust height to the data, not to decoration. Check that labels remain readable at final size.

## ggsave Pattern

```r
ggplot2::ggsave(
  filename = "outputs/figures/figure_1.pdf",
  plot = p,
  width = 6.5,
  height = 4,
  units = "in",
  device = grDevices::pdf
)
```

Use `grDevices::cairo_pdf` only when the local R installation supports Cairo reliably and the project needs that font/rendering behavior.

For PNG:

```r
ggplot2::ggsave(
  filename = "outputs/figures/figure_1.png",
  plot = p,
  width = 6.5,
  height = 4,
  units = "in",
  dpi = 300
)
```

## Text And Captions

- Use sentence case for titles and labels.
- Include units in axis labels.
- Include data source and date/access note in caption or report text when required.
- In reports and papers, the figure caption should explain what the reader sees without restating every axis label.
- Start manuscript captions with `Figure` plus the number unless the target style says otherwise.
- Prefer a declarative first sentence when the figure has a clear takeaway.
- Keep captions self-contained: define acronyms, measures, denominators, sample, period, geography, encodings, panels, intervals, reference lines, and transformations needed for interpretation.
- Explain uncertainty displays: confidence/credible intervals, standard errors, model estimates, smoothing, tests, or sample sizes as applicable.
- Do not use a caption to rescue a misleading figure. Fix scales, comparisons, denominators, encodings, or chart type first.

For dedicated caption work, use the `figure-captions` skill.

## Font Guidance

Use readable sans-serif defaults unless the project has a style guide. Avoid tiny tick labels. If the report is PDF-first, verify the final PDF rather than relying on the RStudio preview.
