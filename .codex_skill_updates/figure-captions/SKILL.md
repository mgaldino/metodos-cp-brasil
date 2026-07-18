---
name: figure-captions
description: Create, revise, and audit academic figure captions and legends for papers, reports, slides, and appendices. Use when Codex needs to write standalone captions, improve captions for existing figures, standardize figure numbering and source notes, check whether a caption supports fair interpretation of a visualization, or generate caption templates for ggplot2/RMarkdown/Quarto/LaTeX outputs. Triggers include figure caption, legenda de figura, caption, figure legend, source note, alt text, numbered figures, manuscript figures, graphical abstract notes, and captions for tables/figures.
---

# Figure Captions

Use this skill to write or audit figure captions that let a reader understand the figure's message, evidence, and limits without hunting through the main text.

Default language follows the user's document. For Portuguese reports, use fully accented Portuguese. For academic manuscripts, prefer concise, publication-ready prose over promotional language.

## Source Basis

This skill follows four practical principles from the user's preferred references:

- International Science Editing: captions should stand alone and normally include a declarative title, enough methods/context to understand the figure, and statistical information where relevant.
- Celia M. Elliott, University of Illinois: start with `Figure` plus the figure number, make figures and captions tell the story, define acronyms, identify visual elements, include scales/units, and describe all elements needed to interpret the figure.
- Gelman and Unwin, "Tradeoffs in Information Graphics": prioritize fair and effective display of relevant data, appropriate scaling, and informative comparisons; design can attract attention but must not outrun the statistical task.
- Gelman's data-visualization discussion: design graphs with specific substantive questions in mind; provide enough context for accurate interpretation; use basic, comparable displays when they answer the question better than novelty.

## When To Use

Use this skill when the user asks to:

- write captions/legends for figures already generated;
- revise weak captions such as "Scatterplot of X and Y";
- produce RMarkdown/Quarto/LaTeX `fig.cap` text;
- audit whether a figure caption is self-contained and statistically honest;
- create caption templates for a paper, appendix, report, or slide deck;
- align figure captions with axis labels, sample definitions, uncertainty intervals, source notes, and figure numbering.

If the user asks to create or modify the figure itself in R/ggplot2, use `ggplot-dataviz` as the primary skill and apply this skill's caption rules during finalization.

## Caption Workflow

1. Identify the figure's job:
   - What substantive question does the figure answer?
   - What comparison, trend, distribution, relationship, map, mechanism, or uncertainty is shown?
   - Who is the audience and where will the caption appear?
2. Inspect the figure or plotting code when available:
   - Verify plotted variables, units, denominators, scales, transformations, filters, groups, time window, sample size, and uncertainty intervals.
   - Do not infer methods, sample restrictions, or statistical tests from the image alone if they are not visible or documented.
3. Draft the caption in this order:
   - Number and declarative title: `Figure N. Main takeaway.`
   - Visual description: what is plotted and how to read encodings, panels, groups, scales, and uncertainty.
   - Data/method context: sample, period, unit, denominator, smoothing/model/interval/test where needed.
   - Source/note: data source, access date for public data, important exclusions, definitions, and cautionary limits.
4. Audit for self-containment:
   - Define acronyms and nonstandard measures.
   - State units and denominators.
   - Explain intervals, bands, fitted lines, point sizes, colors, panels, and reference lines.
   - Mention log/indexed/standardized scales when used.
   - Make sure the caption does not claim causality unless the design supports it.
5. Produce deliverable:
   - For manuscripts/reports: polished caption plus optional source note.
   - For RMarkdown/Quarto: `fig.cap = "..."` text and, if needed, `fig.scap`/short caption.
   - For audit tasks: list problems first, then a revised caption.

## Caption Template

Use this structure unless the target journal/report has stricter rules:

```text
Figure N. [Declarative takeaway in sentence case]. [What is plotted: outcome, groups, time/place, unit and denominator]. [How to read encodings/panels/intervals/reference lines]. [Data/method details required for interpretation]. Note: [source, access date, exclusions, definitions, uncertainty/statistical test, or limits].
```

For a caption-only output, keep it tight: usually 2-5 sentences. For complex multi-panel figures, use one overarching takeaway plus panel-specific clauses: "Panel A shows... Panel B shows..."

## Good Caption Tests

A caption is ready when a reader can answer:

- What is the main takeaway?
- What data, sample, period, geography, and unit are shown?
- What do colors, lines, points, panels, bands, intervals, and reference marks mean?
- What scale, transformation, baseline, denominator, or normalization was used?
- What statistical uncertainty or model estimate is being displayed?
- What source produced the data and when was it accessed, if relevant?
- What limitation prevents overinterpretation?

## Common Fixes

- Replace descriptive-only titles with declarative titles when the figure has a clear message.
- Move symbol/color explanations into the plot legend when that reduces caption clutter.
- Add source and access date for public data in reports.
- Add sample size or denominator when percentages, rates, shares, or model estimates are shown.
- Avoid phrases like "clearly shows" unless the evidence is actually visually unambiguous.
- Use "associação" / "relationship" rather than causal verbs when the figure is descriptive or observational.
- Do not repeat every axis label; explain what the plotted quantities mean.
- For slides, shorten the caption and put source/method notes in small text below the figure.

## Output Formats

For new captions:

```markdown
**Figure N. Title.** Caption text. Note: source/method/limits.
```

For audits:

```markdown
## Problems
- [Issue with current caption.]

## Revised Caption
**Figure N. Title.** Caption text. Note: source/method/limits.
```

For RMarkdown/Quarto:

```r
fig.cap = "Figure N. Title. Caption text. Note: source/method/limits."
```

## Quality Bar

Captions must be accurate, self-contained, numerically and statistically precise, and consistent with the figure and the surrounding text. If the figure itself is misleading, say so and recommend a figure change rather than hiding the problem in the caption.
