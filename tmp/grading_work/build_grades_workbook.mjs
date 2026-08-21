import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP";
const sourceCsv = path.join(projectRoot, "tmp/grading_work/final_grade_records.csv");
const loopCsv = path.join(projectRoot, "tmp/grading_work/independent_review_results.csv");
const reviewsMd = path.join(
  projectRoot,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411/reavaliacoes_independentes_loop.md",
);
const outputDir = path.join(
  projectRoot,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411",
);
const previewDir = path.join(projectRoot, "tmp/grading_work/workbook_previews");
const outputPath = path.join(outputDir, "notas_metodos_III_2026.xlsx");

const palette = {
  navy: "#17324D",
  teal: "#0F766E",
  tealLight: "#DDF3EF",
  gold: "#D6A84B",
  goldLight: "#FFF3D6",
  ink: "#17212B",
  muted: "#5B6773",
  line: "#D8E0E8",
  soft: "#F5F8FA",
  white: "#FFFFFF",
  green: "#DCFCE7",
  greenInk: "#166534",
  red: "#FEE2E2",
  redInk: "#991B1B",
};

const csvText = await fs.readFile(sourceCsv, "utf8");
const loopText = await fs.readFile(loopCsv, "utf8");
const reviewsText = await fs.readFile(reviewsMd, "utf8");
const csvWorkbook = await Workbook.fromCSV(csvText, { sheetName: "Dados" });
const loopWorkbook = await Workbook.fromCSV(loopText, { sheetName: "Loop" });
const csvValues = csvWorkbook.worksheets.getItem("Dados").getUsedRange().values;
const loopValues = loopWorkbook.worksheets.getItem("Loop").getUsedRange().values;
const header = csvValues[0];
const records = csvValues.slice(1);
const ix = Object.fromEntries(header.map((value, index) => [String(value), index]));
const loopHeader = loopValues[0];
const loopIx = Object.fromEntries(loopHeader.map((value, index) => [String(value), index]));

const asNumber = (value) => {
  if (typeof value === "number") return value;
  const parsed = Number(String(value).replace(",", "."));
  return Number.isFinite(parsed) ? parsed : null;
};

const reviewNarratives = new Map();
for (const section of reviewsText.split(/^## /m).slice(1)) {
  const nuspMatch = section.match(/NUSP\s+(\d+)/);
  if (!nuspMatch) continue;
  const narrative = section
    .split(/\n\n+/)
    .map((paragraph) => paragraph.trim())
    .find((paragraph) => paragraph && !paragraph.startsWith("-") && !paragraph.includes("NUSP "));
  if (narrative) reviewNarratives.set(nuspMatch[1], narrative.replace(/`/g, ""));
}

const adoptedOverrides = new Map();
for (const row of loopValues.slice(1)) {
  const nusp = String(row[loopIx.NUSP] ?? "");
  const independentGrade = asNumber(row[loopIx.nota_independente]);
  if (!nusp || independentGrade === null) continue;
  const adoptedGrade = nusp === "4725594" ? 5.0 : independentGrade;
  const prefix = nusp === "4725594"
    ? "Nota final ajustada pelo docente para 5,0 (releitura independente: 4,2)."
    : `Nota adotada após releitura independente cega: ${adoptedGrade.toFixed(1).replace(".", ",")}.`;
  adoptedOverrides.set(nusp, {
    grade: adoptedGrade,
    justification: `${prefix} ${reviewNarratives.get(nusp) ?? ""}`.trim(),
  });
}

if (adoptedOverrides.size !== 14) {
  throw new Error(`Esperadas 14 notas adotadas do loop; encontradas ${adoptedOverrides.size}.`);
}

const gradeRows = records.map((row) => {
  const nusp = String(row[ix.NUSP] ?? "");
  const override = adoptedOverrides.get(nusp);
  const displayName = nusp === "4725594"
    ? "Mariana Araujo Püschel"
    : String(row[ix.Nome] ?? "");
  return [
    displayName,
    nusp,
    String(row[ix.Email] ?? ""),
    asNumber(row[ix.Lista_1]),
    asNumber(row[ix.Lista_2]),
    null,
    override?.grade ?? asNumber(row[ix.Trabalho_final]),
    String(row[ix.Situacao] ?? ""),
    String(row[ix.Fonte_entrega] ?? ""),
    override?.justification ?? String(row[ix.Justificativa] ?? ""),
  ];
});

if (gradeRows.length !== 74) {
  throw new Error(`Esperados 74 estudantes; encontrados ${gradeRows.length}.`);
}

const workbook = Workbook.create();
const notas = workbook.worksheets.add("Notas");
const rubrica = workbook.worksheets.add("Rubrica");
const referencia = workbook.worksheets.add("Referência");
const proveniencia = workbook.worksheets.add("Proveniência");

function styleTitle(sheet, title, subtitle, lastColumn) {
  const titleRange = sheet.getRange(`A1:${lastColumn}1`);
  titleRange.merge();
  titleRange.values = [[title]];
  titleRange.format = {
    fill: palette.navy,
    font: { bold: true, color: palette.white, size: 18 },
    verticalAlignment: "center",
  };
  titleRange.format.rowHeight = 34;

  const subtitleRange = sheet.getRange(`A2:${lastColumn}2`);
  subtitleRange.merge();
  subtitleRange.values = [[subtitle]];
  subtitleRange.format = {
    fill: palette.tealLight,
    font: { color: palette.ink, italic: true, size: 10 },
    wrapText: true,
    verticalAlignment: "center",
  };
  subtitleRange.format.rowHeight = 32;
  sheet.showGridLines = false;
}

function styleHeader(range) {
  range.format = {
    fill: palette.teal,
    font: { bold: true, color: palette.white },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
    borders: { preset: "outside", style: "medium", color: palette.teal },
  };
  range.format.rowHeight = 31;
}

function styleBody(range) {
  range.format = {
    font: { color: palette.ink, size: 10 },
    verticalAlignment: "top",
    borders: {
      insideHorizontal: { style: "thin", color: palette.line },
      bottom: { style: "thin", color: palette.line },
    },
  };
}

// Planilha principal ---------------------------------------------------------
styleTitle(
  notas,
  "Métodos III — correção do trabalho final (2026)",
  "Notas adotadas após releitura independente dos 14 trabalhos selecionados; Mariana Araujo Püschel ajustada para 5,0 por decisão docente. Nenhuma nota foi lançada no Moodle.",
  "J",
);

const cards = [
  ["A4:B4", "A5:B5", "Estudantes", "=COUNTA(A8:A81)"],
  ["C4:D4", "C5:D5", "Entregas", '=COUNTIF(H8:H81,"<>Sem envio localizado")'],
  ["E4:F4", "E5:F5", "Sem entrega", '=COUNTIF(H8:H81,"Sem envio localizado")'],
  ["G4:H4", "G5:H5", "Média dos entregues", '=AVERAGEIF(H8:H81,"<>Sem envio localizado",G8:G81)'],
  ["I4:J4", "I5:J5", "Escala", null],
];

for (const [labelAddress, valueAddress, label, formula] of cards) {
  const labelRange = notas.getRange(labelAddress);
  labelRange.merge();
  labelRange.values = [[label]];
  labelRange.format = {
    fill: palette.soft,
    font: { bold: true, color: palette.muted, size: 9 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: palette.line },
  };
  const valueRange = notas.getRange(valueAddress);
  valueRange.merge();
  if (formula) valueRange.formulas = [[formula]];
  else valueRange.values = [["0–10"]];
  valueRange.format = {
    fill: palette.white,
    font: { bold: true, color: palette.navy, size: 16 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: palette.line },
  };
}
notas.getRange("G5:H5").format.numberFormat = "0.00";
notas.getRange("A4:J5").format.rowHeight = 24;

const notasHeaders = [[
  "Nome",
  "NUSP",
  "E-mail",
  "Lista 1",
  "Lista 2",
  "Nota listas",
  "Trabalho final",
  "Situação",
  "Fonte",
  "Justificativa da correção",
]];
notas.getRange("A7:J7").values = notasHeaders;
styleHeader(notas.getRange("A7:J7"));
notas.getRange("A8:J81").values = gradeRows;
notas.getRange("F8").formulasR1C1 = [["=AVERAGE(RC[-2]:RC[-1])"]];
notas.getRange("F8:F81").fillDown();
styleBody(notas.getRange("A8:J81"));
notas.getRange("A8:A81").format.font = { bold: true, color: palette.navy, size: 10 };
notas.getRange("B8:B81").format.numberFormat = "@";
notas.getRange("D8:G81").format.numberFormat = "0.0";
notas.getRange("D8:G81").format.horizontalAlignment = "right";
notas.getRange("H8:I81").format.horizontalAlignment = "center";
notas.getRange("J8:J81").format.wrapText = true;
notas.getRange("A8:J81").format.rowHeight = 40;

notas.getRange("G8:G81").conditionalFormats.add("colorScale", {
  criteria: [
    { type: "lowestValue", color: "#FCA5A5" },
    { type: "percentile", value: 60, color: "#FEF3C7" },
    { type: "highestValue", color: "#86EFAC" },
  ],
});
notas.getRange("H8:H81").conditionalFormats.add("containsText", {
  text: "Sem envio",
  format: { fill: palette.red, font: { color: palette.redInk, bold: true } },
});
notas.getRange("H8:H81").conditionalFormats.add("containsText", {
  text: "Entregue",
  format: { fill: palette.green, font: { color: palette.greenInk, bold: true } },
});

const notasTable = notas.tables.add("A7:J81", true, "NotasTrabalhoFinal");
notasTable.style = "TableStyleMedium2";
notasTable.showBandedColumns = false;
notasTable.showFilterButton = true;
notas.freezePanes.freezeRows(7);
notas.freezePanes.freezeColumns(2);

const notasWidths = {
  A: 31,
  B: 13,
  C: 29,
  D: 10,
  E: 10,
  F: 12,
  G: 15,
  H: 22,
  I: 14,
  J: 72,
};
for (const [column, width] of Object.entries(notasWidths)) {
  notas.getRange(`${column}:${column}`).format.columnWidth = width;
}

// Rubrica -------------------------------------------------------------------
styleTitle(
  rubrica,
  "Rubrica do trabalho final",
  "Tabela 1. Critérios comuns aplicados a todos os trabalhos; total de 10,0 pontos.",
  "D",
);
rubrica.getRange("A4:D4").values = [[
  "Critério",
  "Valor máximo",
  "Crédito integral",
  "Descontos mais comuns",
]];
styleHeader(rubrica.getRange("A4:D4"));
const rubricRows = [
  ["1. Artigo e unidade de análise", 0.75, "Identifica corretamente artigo, casos e unidade de análise.", "Identificação vaga ou unidade incorreta."],
  ["2. Leitura e validação da base", 1.5, "Informa dimensões, variáveis e ausências; trata códigos inválidos.", "Ausências não verificadas ou limpeza inadequada."],
  ["3. Descritiva de exp_adm", 1.75, "Calcula n, x, proporção e intervalo de confiança por órgão.", "Denominadores incorretos, mistura com exp_car ou ausência de IC."],
  ["4. Teste de proporções 1", 1.5, "Testa a diferença MAPA–MinC em exp_adm e interpreta o p-valor.", "Estimando alterado, p-valor/decisão contraditórios ou teste ausente."],
  ["5. alto_nivel e teste 2", 1.75, "Constrói alto_nivel de forma coerente, estima por órgão e testa a diferença.", "Recodificação incorreta ou conclusão incompatível com o teste."],
  ["6. Níveis de significância", 0.75, "Distingue corretamente as decisões a 10% e a 1%.", "Confunde limiares ou não relaciona alfa e p-valor."],
  ["7. Amostra maior", 0.5, "Explica que dobrar n reduz o erro-padrão por 1/√2.", "Afirma apenas que melhora, sem direção/mecanismo, ou conclui o oposto."],
  ["8. Reprodutibilidade e apresentação", 1.5, "Código/dados, resultados legíveis e narrativa coerente.", "Só respostas sem cálculo, base impressa integralmente ou inconsistências graves."],
];
rubrica.getRange("A5:D12").values = rubricRows;
styleBody(rubrica.getRange("A5:D12"));
rubrica.getRange("B5:B12").format.numberFormat = "0.00";
rubrica.getRange("A5:A12").format.font = { bold: true, color: palette.navy };
rubrica.getRange("C5:D12").format.wrapText = true;
rubrica.getRange("A5:D12").format.rowHeight = 52;
rubrica.getRange("A13").values = [["Total"]];
rubrica.getRange("B13").formulas = [["=SUM(B5:B12)"]];
rubrica.getRange("A13:D13").format = {
  fill: palette.goldLight,
  font: { bold: true, color: palette.navy },
  borders: { preset: "doubleBottom", style: "medium", color: palette.gold },
};
rubrica.getRange("B13").format.numberFormat = "0.00";
rubrica.getRange("A15:D16").merge(true);
rubrica.getRange("A15:D16").values = [
  ["Nota metodológica: variantes defensáveis do teste (sem pooling, com correção de continuidade ou aproximação equivalente) receberam crédito quando preservaram o mesmo estimando e produziram a decisão substantiva correta."],
  ["Escopo: a nota refere-se exclusivamente ao trabalho final. As notas das listas aparecem na planilha principal apenas como informação auxiliar."],
];
rubrica.getRange("A15:D16").format = {
  fill: palette.soft,
  font: { color: palette.muted, italic: true },
  wrapText: true,
  borders: { preset: "outside", style: "thin", color: palette.line },
};
rubrica.getRange("A15:D16").format.rowHeight = 42;
rubrica.getRange("A:A").format.columnWidth = 34;
rubrica.getRange("B:B").format.columnWidth = 14;
rubrica.getRange("C:C").format.columnWidth = 52;
rubrica.getRange("D:D").format.columnWidth = 58;
rubrica.freezePanes.freezeRows(4);

// Valores de referência -----------------------------------------------------
styleTitle(
  referencia,
  "Valores de referência do gabarito",
  "Tabela 2. Âncoras numéricas e decisões usadas na correção; pequenas diferenças podem decorrer de implementações estatísticas defensáveis.",
  "D",
);
referencia.getRange("A4:D4").values = [["Seção", "Quantidade/comparação", "Valor de referência", "Interpretação esperada"]];
styleHeader(referencia.getRange("A4:D4"));
const referenceRows = [
  ["Base", "Dimensão", "1.038 linhas × 26 colunas", "Uma linha por ocupante/cargo observado na base."],
  ["Base", "Ausentes", "instr: 95; exp_adm: 11; exp_car: 76; nivel: 0; indicacao: 0; car_pub: 17", "Relatar e tratar ausências antes das proporções."],
  ["exp_adm", "MAPA", "n=524; x=482; p=0,91985; IC95%≈[0,892; 0,941]", "Alta proporção de experiência administrativa."],
  ["exp_adm", "MinC", "n=354; x=312; p=0,88136; IC95%≈[0,842; 0,912]", "Proporção menor do que no MAPA."],
  ["Teste 1", "MinC − MAPA", "dif.≈−0,03849; z≈−1,902; p≈0,05716", "Rejeitar H0 a 10%; não rejeitar a 5% nem a 1%."],
  ["alto_nivel", "MAPA", "n=525; x=187; p=0,35619", "Indicador construído conforme a definição pedida."],
  ["alto_nivel", "MinC", "n=365; x=155; p=0,42466", "Proporção maior do que no MAPA."],
  ["Teste 2", "MinC − MAPA", "dif.≈0,06847; z≈2,065; p≈0,03889", "Rejeitar H0 a 5%; não rejeitar a 1%."],
  ["Significância", "α=10%", "Teste 1: rejeitar H0", "Há evidência fraca/moderada de diferença."],
  ["Significância", "α=1%", "Testes 1 e 2: não rejeitar H0", "P-valores excedem 0,01."],
  ["Amostra", "Dobrar n", "EP novo = EP antigo/√2 ≈ 0,707·EP", "Maior precisão; o erro-padrão cai cerca de 29,3%."],
  ["Variantes", "Testes defensáveis", "p do teste 1 ≈ 0,052–0,074; p do teste 2 ≈ 0,039–0,046", "Aceitar quando o estimando e a decisão substantiva são preservados."],
];
referencia.getRange("A5:D16").values = referenceRows;
styleBody(referencia.getRange("A5:D16"));
referencia.getRange("A5:A16").format.font = { bold: true, color: palette.navy };
referencia.getRange("C5:D16").format.wrapText = true;
referencia.getRange("A5:D16").format.rowHeight = 48;
referencia.getRange("A:A").format.columnWidth = 19;
referencia.getRange("B:B").format.columnWidth = 25;
referencia.getRange("C:C").format.columnWidth = 48;
referencia.getRange("D:D").format.columnWidth = 55;
referencia.freezePanes.freezeRows(4);

// Proveniência --------------------------------------------------------------
styleTitle(
  proveniencia,
  "Proveniência e validações",
  "Tabela 3. Fontes, cobertura e controles de integridade usados para produzir as notas em 21/08/2026.",
  "D",
);
proveniencia.getRange("A4:D4").values = [["Item", "Fonte ou artefato", "Verificação", "Data ou SHA-256"]];
styleHeader(proveniencia.getRange("A4:D4"));
const provenanceRows = [
  ["Atividade Moodle", "https://edisciplinas.usp.br/mod/assign/view.php?id=6364861&action=grading", "FLP0406 — Trabalho Final; 74 participantes.", "Acesso: 2026-08-21"],
  ["Planilha da monitoria", "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/trabalhos_graduacao_metodos_III_2026/planilha_monitoria/Notas MTPCP.xlsx", "74 NUSPs únicos; Lista 1 e Lista 2 conciliadas com a turma.", "165f0741843c4a13121f72777859d9a9b48a99e87ae2d298f8fc9af245e3f0f6"],
  ["Inventário Moodle", "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/moodle_roster_and_submissions.json", "56 envios no Moodle e 18 sem envio no Moodle.", "aa200453c3401d2dfbf47d7a19cb4e54227db73b0b0f03eb7846600e07ee5617"],
  ["Exceção por e-mail", "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/trabalhos_graduacao_metodos_III_2026/entregas_email/Carmen Maria Serrano dos Santos/avaliacao_Carmen_Maria_Serrano_dos_Santos.pdf", "1 entrega válida por e-mail; total final de 57 trabalhos.", "646f0a938cc97f3a86ff81aba012802f00248216af93cb4bef01fee1d84d2721"],
  ["Base consolidada de notas", "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/final_grade_records.csv", "74 linhas; 57 entregas; 17 sem entrega; notas dentro de 0–10.", "c084d2905a34218aa60278c21ee6f62b1a3c64d84ff7052f70074e3a13515b2b"],
  ["Loop independente", "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/independent_review_results.csv", "14 releituras cegas; notas do loop adotadas nos casos selecionados.", "Resultados brutos preservados"],
  ["Ajuste docente", "Mariana Araujo Püschel — NUSP 4725594", "Nota do loop: 4,2; nota final adotada: 5,0 por decisão do docente.", "2026-08-21"],
  ["OCR das submissões", "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/moodle_ocr/manifest.json", "1.818 capturas processadas; 56 estudantes; 0 falhas de OCR.", "0d2f582d0d530d2df8d573009d5e93a549e260ccd551a016e4b90d78e5842379"],
  ["Enunciado", "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/book-stat-basica/avaliacao_aulas_06_09_inferencia_basica.Rmd", "Instruções exatas do trabalho final recuperadas no repositório da disciplina.", "838c72cc19a6e6beef81954e5109291d285fd570c2cbeb5e211720520836f616"],
  ["Gabarito", "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/book-stat-basica/avaliacao_aulas_06_09_gabarito.Rmd", "Âncoras substantivas e decisões estatísticas usadas na rubrica.", "a02f205062dcc2684456209232785b37a243c91959cc25b1a1f018bc37177b81"],
  ["Cálculos do gabarito", "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/book-stat-basica/scripts/avaliacao_aulas_06_09_gabarito_calculos.R", "Script reprodutível dos valores de referência.", "a9f3ff20c646087ae38c62594c5c16600ed22995d93005825c0eea41f39fb9db"],
  ["Estado externo", "Moodle", "Nenhuma nota ou devolutiva foi lançada; acesso apenas para leitura/coleta.", "2026-08-21"],
  ["Escopo da nota", "Trabalho final", "A planilha não calcula média final da disciplina; notas de listas são auxiliares.", "Escala 0–10"],
  ["Caso de leitura longa", "Agnes Francisca Carraro Kunsch — NUSP 14554690", "PDF de 206 páginas: capa/análise e páginas finais foram verificadas; miolo era impressão da base.", "Amostra: p. 1 e 197–206"],
];
proveniencia.getRange("A5:D18").values = provenanceRows;
styleBody(proveniencia.getRange("A5:D18"));
proveniencia.getRange("A5:A18").format.font = { bold: true, color: palette.navy };
proveniencia.getRange("B5:D18").format.wrapText = true;
proveniencia.getRange("A5:D18").format.rowHeight = 65;
proveniencia.getRange("A:A").format.columnWidth = 24;
proveniencia.getRange("B:B").format.columnWidth = 76;
proveniencia.getRange("C:C").format.columnWidth = 58;
proveniencia.getRange("D:D").format.columnWidth = 49;
proveniencia.freezePanes.freezeRows(4);

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

for (const sheetName of ["Notas", "Rubrica", "Referência", "Proveniência"]) {
  const preview = await workbook.render({
    sheetName,
    autoCrop: "all",
    scale: sheetName === "Notas" ? 0.65 : 0.9,
    format: "png",
  });
  await fs.writeFile(
    path.join(previewDir, `${sheetName.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()}.png`),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(JSON.stringify({ outputPath, previewDir, students: gradeRows.length }, null, 2));
