import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP";
const sourceCsv = path.join(projectRoot, "tmp/grading_work/notas_frequencias_inputs.csv");
const outputDir = path.join(
  projectRoot,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411",
);
const previewDir = path.join(projectRoot, "tmp/grading_work/notas_frequencias_previews");
const outputPath = path.join(outputDir, "notas_e_frequencias_metodos_III_2026.xlsx");

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
  blueLight: "#E6F2FA",
};

const csvText = await fs.readFile(sourceCsv, "utf8");
const csvWorkbook = await Workbook.fromCSV(csvText, { sheetName: "Dados" });
const csvValues = csvWorkbook.worksheets.getItem("Dados").getUsedRange().values;
const header = csvValues[0];
const records = csvValues.slice(1);
const ix = Object.fromEntries(header.map((value, index) => [String(value), index]));

const asNumber = (value) => {
  if (typeof value === "number") return value;
  const parsed = Number(String(value ?? "").replace(",", "."));
  return Number.isFinite(parsed) ? parsed : null;
};

const asBoolean = (value) => String(value).toUpperCase() === "TRUE";

if (records.length !== 74) {
  throw new Error(`Esperados 74 estudantes; encontrados ${records.length}.`);
}

const auditRows = records.map((row) => [
  String(row[ix.Nome] ?? ""),
  String(row[ix.NUSP] ?? ""),
  String(row[ix.Email] ?? ""),
  String(row[ix.Fonte_entrega] ?? ""),
  asNumber(row[ix.Lista_1]),
  asNumber(row[ix.Lista_2]),
  asNumber(row[ix.Nota_trabalho_adotada]),
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  String(row[ix.Justificativa] ?? ""),
  null,
  null,
  asNumber(row[ix.Penalidade_IA]) ?? 0,
]);

const workbook = Workbook.create();
const lancamento = workbook.worksheets.add("Lançamento");
const auditoria = workbook.worksheets.add("Auditoria");
const regras = workbook.worksheets.add("Regras");
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
  subtitleRange.format.rowHeight = 34;
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
  range.format.rowHeight = 32;
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

function addCard(sheet, labelAddress, valueAddress, label, formula, numberFormat = null) {
  const labelRange = sheet.getRange(labelAddress);
  labelRange.merge();
  labelRange.values = [[label]];
  labelRange.format = {
    fill: palette.soft,
    font: { bold: true, color: palette.muted, size: 9 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: palette.line },
  };
  const valueRange = sheet.getRange(valueAddress);
  valueRange.merge();
  valueRange.formulas = [[formula]];
  valueRange.format = {
    fill: palette.white,
    font: { bold: true, color: palette.navy, size: 16 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: palette.line },
  };
  if (numberFormat) valueRange.format.numberFormat = numberFormat;
}

// Auditoria: insumos, regras e cálculos completos --------------------------
styleTitle(
  auditoria,
  "Métodos III — auditoria de notas e frequências (2026)",
  "A nota do trabalho já incorpora as releituras e decisões docentes anteriores. As colunas derivadas usam fórmulas; nenhuma nota ou frequência foi lançada no Moodle.",
  "S",
);

auditoria.getRange("A7:S7").values = [[
  "Nome",
  "NUSP",
  "E-mail",
  "Fonte do trabalho",
  "Lista 1",
  "Lista 2",
  "Nota do trabalho adotada",
  "Todas as listas?",
  "Alguma lista?",
  "Ajuste das listas",
  "Nota final",
  "Frequência base",
  "Desconto por lista (p.p.)",
  "Frequência final",
  "Resultado",
  "Avaliação do trabalho",
  "Trabalho entregue?",
  "Entregou tudo?",
  "Penalidade de IA já incorporada",
]];
styleHeader(auditoria.getRange("A7:S7"));
auditoria.getRange("A8:S81").values = auditRows;

auditoria.getRange("H8").formulas = [["=IF(AND(E8=10,F8=10),\"Sim\",\"Não\")"]];
auditoria.getRange("H8:H81").fillDown();
auditoria.getRange("I8").formulas = [["=IF(OR(E8=10,F8=10),\"Sim\",\"Não\")"]];
auditoria.getRange("I8:I81").fillDown();
auditoria.getRange("Q8").formulas = [["=IF(D8=\"Sem envio\",\"Não\",\"Sim\")"]];
auditoria.getRange("Q8:Q81").fillDown();
auditoria.getRange("R8").formulas = [["=IF(AND(Q8=\"Sim\",H8=\"Sim\"),\"Sim\",\"Não\")"]];
auditoria.getRange("R8:R81").fillDown();
auditoria.getRange("J8").formulas = [["=IF(R8=\"Sim\",0.5,-0.5)"]];
auditoria.getRange("J8:J81").fillDown();
auditoria.getRange("K8").formulas = [["=MAX(0,MIN(10,G8+J8))"]];
auditoria.getRange("K8:K81").fillDown();
auditoria.getRange("L8").formulas = [["=IF(Q8=\"Sim\",85+0.5*K8,\"\")"]];
auditoria.getRange("L8:L81").fillDown();
auditoria.getRange("M8").formulas = [["=IF(AND(Q8=\"Sim\",H8=\"Não\"),10,0)"]];
auditoria.getRange("M8:M81").fillDown();
auditoria.getRange("N8").formulas = [["=ROUND(ROUND(IF(Q8=\"Não\",IF(I8=\"Não\",0,50),MAX(IF(K8>=5,75,0),L8-M8)),1),0)"]];
auditoria.getRange("N8:N81").fillDown();
auditoria.getRange("O8").formulas = [["=IF(AND(K8>=5,N8>=75),\"Aprovado\",\"Reprovado\")"]];
auditoria.getRange("O8:O81").fillDown();

styleBody(auditoria.getRange("A8:S81"));
auditoria.getRange("A8:A81").format.font = { bold: true, color: palette.navy, size: 10 };
auditoria.getRange("B8:B81").format.numberFormat = "@";
auditoria.getRange("E8:G81").format.numberFormat = "0.0";
auditoria.getRange("J8:M81").format.numberFormat = "0.0";
auditoria.getRange("N8:N81").format.numberFormat = "0";
auditoria.getRange("S8:S81").format.numberFormat = "0.0";
auditoria.getRange("E8:N81").format.horizontalAlignment = "right";
auditoria.getRange("D8:D81").format.horizontalAlignment = "center";
auditoria.getRange("H8:I81").format.horizontalAlignment = "center";
auditoria.getRange("O8:O81").format.horizontalAlignment = "center";
auditoria.getRange("Q8:R81").format.horizontalAlignment = "center";
auditoria.getRange("P8:P81").format.wrapText = true;
for (let index = 0; index < auditRows.length; index += 1) {
  const justificationLength = String(auditRows[index][15] ?? "").length;
  const rowHeight = Math.max(40, Math.min(240, Math.ceil(justificationLength / 95) * 14 + 10));
  auditoria.getRange(`A${index + 8}:S${index + 8}`).format.rowHeight = rowHeight;
}

auditoria.getRange("K8:K81").conditionalFormats.add("colorScale", {
  criteria: [
    { type: "lowestValue", color: "#FCA5A5" },
    { type: "percentile", value: 60, color: "#FEF3C7" },
    { type: "highestValue", color: "#86EFAC" },
  ],
});
auditoria.getRange("N8:N81").conditionalFormats.add("colorScale", {
  criteria: [
    { type: "lowestValue", color: "#FCA5A5" },
    { type: "percentile", value: 60, color: "#FEF3C7" },
    { type: "highestValue", color: "#86EFAC" },
  ],
});
auditoria.getRange("O8:O81").conditionalFormats.add("containsText", {
  text: "Aprovado",
  format: { fill: palette.green, font: { color: palette.greenInk, bold: true } },
});
auditoria.getRange("O8:O81").conditionalFormats.add("containsText", {
  text: "Reprovado",
  format: { fill: palette.red, font: { color: palette.redInk, bold: true } },
});

const auditTable = auditoria.tables.add("A7:S81", true, "AuditoriaNotasFrequencias");
auditTable.style = "TableStyleMedium2";
auditTable.showBandedColumns = false;
auditTable.showFilterButton = true;
auditoria.freezePanes.freezeRows(7);
auditoria.freezePanes.freezeColumns(2);

const auditWidths = {
  A: 31, B: 13, C: 29, D: 19, E: 9, F: 9, G: 15, H: 13, I: 12,
  J: 13, K: 11, L: 14, M: 15, N: 14, O: 13, P: 66, Q: 14, R: 13, S: 16,
};
for (const [column, width] of Object.entries(auditWidths)) {
  auditoria.getRange(`${column}:${column}`).format.columnWidth = width;
}

// Lançamento: tabela compacta para uso administrativo ----------------------
styleTitle(
  lancamento,
  "Métodos III — notas e frequências finais (2026)",
  "Tabela compacta para conferência e lançamento. A memória de cálculo completa está na aba Auditoria.",
  "F",
);

addCard(lancamento, "A4:B4", "A5:B5", "Estudantes", "=COUNTA(A8:A81)");
addCard(lancamento, "C4:D4", "C5:D5", "Aprovados", '=COUNTIF(E8:E81,"Aprovado")');
addCard(lancamento, "E4:F4", "E5:F5", "Menor frequência aprovada", '=MINIFS(D8:D81,E8:E81,"Aprovado")', "0");

lancamento.getRange("A7:F7").values = [[
  "Nome",
  "NUSP",
  "Nota final",
  "Frequência (%)",
  "Resultado",
  "Regra de ajuste da nota",
]];
styleHeader(lancamento.getRange("A7:F7"));

for (let row = 8; row <= 81; row += 1) {
  lancamento.getRange(`A${row}:E${row}`).formulas = [[
    `='Auditoria'!A${row}`,
    `='Auditoria'!B${row}`,
    `='Auditoria'!K${row}`,
    `='Auditoria'!N${row}`,
    `='Auditoria'!O${row}`,
  ]];
  lancamento.getRange(`F${row}`).formulas = [[
    `=IF('Auditoria'!R${row}=\"Sim\",\"+0,5: trabalho e todas as listas\",\"−0,5: entrega incompleta\")`,
  ]];
}

styleBody(lancamento.getRange("A8:F81"));
lancamento.getRange("A8:A81").format.font = { bold: true, color: palette.navy, size: 10 };
lancamento.getRange("B8:B81").format.numberFormat = "@";
lancamento.getRange("C8:C81").format.numberFormat = "0.0";
lancamento.getRange("D8:D81").format.numberFormat = "0";
lancamento.getRange("C8:D81").format.horizontalAlignment = "right";
lancamento.getRange("E8:E81").format.horizontalAlignment = "center";
lancamento.getRange("F8:F81").format.wrapText = true;
lancamento.getRange("A8:F81").format.rowHeight = 29;
lancamento.getRange("C8:C81").conditionalFormats.add("colorScale", {
  criteria: [
    { type: "lowestValue", color: "#FCA5A5" },
    { type: "percentile", value: 60, color: "#FEF3C7" },
    { type: "highestValue", color: "#86EFAC" },
  ],
});
lancamento.getRange("D8:D81").conditionalFormats.add("colorScale", {
  criteria: [
    { type: "lowestValue", color: "#FCA5A5" },
    { type: "percentile", value: 60, color: "#FEF3C7" },
    { type: "highestValue", color: "#86EFAC" },
  ],
});
lancamento.getRange("E8:E81").conditionalFormats.add("containsText", {
  text: "Aprovado",
  format: { fill: palette.green, font: { color: palette.greenInk, bold: true } },
});
lancamento.getRange("E8:E81").conditionalFormats.add("containsText", {
  text: "Reprovado",
  format: { fill: palette.red, font: { color: palette.redInk, bold: true } },
});

const launchTable = lancamento.tables.add("A7:F81", true, "LancamentoNotasFrequencias");
launchTable.style = "TableStyleMedium2";
launchTable.showBandedColumns = false;
launchTable.showFilterButton = true;
lancamento.freezePanes.freezeRows(7);
lancamento.freezePanes.freezeColumns(2);

const launchWidths = { A: 34, B: 14, C: 13, D: 15, E: 14, F: 34 };
for (const [column, width] of Object.entries(launchWidths)) {
  lancamento.getRange(`${column}:${column}`).format.columnWidth = width;
}

// Regras -------------------------------------------------------------------
styleTitle(
  regras,
  "Regras de cálculo",
  "Critérios solicitados pelo docente e operacionalização usada nesta planilha.",
  "D",
);
regras.getRange("A4:D4").values = [["Etapa", "Regra", "Fórmula aplicada", "Observação"]];
styleHeader(regras.getRange("A4:D4"));
regras.getRange("A5:D13").values = [
  [1, "Nota do trabalho", "Nota já adotada na correção anterior", "Inclui releituras independentes, ajuste de Mariana para 5,0 e os dois descontos docentes por suspeita não comprovada de IA."],
  [2, "Bônus por entrega completa", "+0,5", "Aplica-se a quem entregou trabalho, Lista 1 e Lista 2."],
  [3, "Desconto por entrega incompleta", "−0,5", "Aplica-se a qualquer estudante que não tenha entregue os três componentes; a nota é limitada a 0–10."],
  [4, "Frequência base com trabalho", "85 + 0,5 × nota final", "Gera pouca variação por nota: 0,5 ponto percentual para cada ponto de nota."],
  [5, "Desconto por lista faltante", "−10 p.p.", "Se faltar ao menos uma das duas listas, o desconto incide sobre a frequência base."],
  [6, "Piso dos aprovados", "máximo entre 75% e o valor calculado", "Passar exige nota final ≥ 5,0 e frequência ≥ 75%."],
  [7, "Sem trabalho, mas com alguma lista", "50%", "Regra especial prevalece sobre a fórmula da frequência base."],
  [8, "Sem trabalho e sem nenhuma lista", "0%", "Regra especial prevalece sobre a fórmula da frequência base."],
  [9, "Precisão", "Notas: 1 casa; frequências: inteiros", "As frequências finais são arredondadas para o percentual inteiro mais próximo."],
];
styleBody(regras.getRange("A5:D13"));
regras.getRange("A5:A13").format.horizontalAlignment = "center";
regras.getRange("A5:D13").format.wrapText = true;
regras.getRange("A5:D13").format.rowHeight = 47;
regras.getRange("A5:D5").format.fill = palette.goldLight;
const rulesTable = regras.tables.add("A4:D13", true, "RegrasCalculo");
rulesTable.style = "TableStyleMedium2";
rulesTable.showFilterButton = false;
regras.freezePanes.freezeRows(4);
regras.getRange("A:A").format.columnWidth = 9;
regras.getRange("B:B").format.columnWidth = 31;
regras.getRange("C:C").format.columnWidth = 35;
regras.getRange("D:D").format.columnWidth = 69;

// Proveniência --------------------------------------------------------------
styleTitle(
  proveniencia,
  "Proveniência e controles",
  "Fontes locais preservadas e verificações de consistência usadas na consolidação.",
  "D",
);
proveniencia.getRange("A4:D4").values = [["Item", "Valor", "Status", "Nota de auditoria"]];
styleHeader(proveniencia.getRange("A4:D4"));
proveniencia.getRange("A5:D15").values = [
  ["Turma", "FLP0406 — Métodos e Técnicas de Pesquisa em Ciência Política (2026)", "Confirmado", "Turma de graduação; não confundir com a oferta conjunta da pós-graduação."],
  ["Planilha anterior", "outputs/01a02455-4428-7e10-b65c-4328cbb55411/notas_metodos_III_2026.xlsx", "Preservada", "Fonte das notas e justificativas já adotadas."],
  ["Registros consolidados", "tmp/grading_work/final_grade_records.csv", "Preservado", "74 estudantes; listas, fonte da entrega e justificativa."],
  ["Releituras independentes", "tmp/grading_work/independent_review_results.csv", "Preservado", "14 releituras incorporadas conforme decisão docente anterior."],
  ["Trabalhos entregues", 57, "Verificado", "56 via Moodle e 1 por e-mail."],
  ["Sem trabalho", 17, "Verificado", "Recebem 50% se houver alguma lista e 0% se não houver nenhuma."],
  ["Entrega completa", 48, "Verificado", "Trabalho e as duas listas; recebem +0,5 na nota."],
  ["Trabalho com lista faltante", 9, "Verificado", "Recebem −0,5 na nota e −10 p.p. na frequência."],
  ["Aprovados", null, "Fórmula", "Todos devem ter frequência mínima de 75%."],
  ["Menor frequência aprovada", null, "Fórmula", "Controle do piso de frequência."],
  ["Ação externa", "Nenhuma", "Confirmado", "Nada foi lançado no Moodle e nenhuma mensagem foi enviada."],
];
proveniencia.getRange("B13").formulas = [["=COUNTIF('Auditoria'!O8:O81,\"Aprovado\")"]];
proveniencia.getRange("B14").formulas = [["=MINIFS('Auditoria'!N8:N81,'Auditoria'!O8:O81,\"Aprovado\")"]];
styleBody(proveniencia.getRange("A5:D15"));
proveniencia.getRange("A5:A15").format.font = { bold: true, color: palette.navy, size: 10 };
proveniencia.getRange("B13:B14").format.numberFormat = "0";
proveniencia.getRange("A5:D15").format.wrapText = true;
proveniencia.getRange("A5:D15").format.rowHeight = 43;
proveniencia.getRange("C5:C15").format.horizontalAlignment = "center";
const provenanceTable = proveniencia.tables.add("A4:D15", true, "ProvenienciaControles");
provenanceTable.style = "TableStyleMedium2";
provenanceTable.showFilterButton = false;
proveniencia.freezePanes.freezeRows(4);
proveniencia.getRange("A:A").format.columnWidth = 28;
proveniencia.getRange("B:B").format.columnWidth = 72;
proveniencia.getRange("C:C").format.columnWidth = 16;
proveniencia.getRange("D:D").format.columnWidth = 58;

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

for (const [sheetName, fileName] of [
  ["Lançamento", "lancamento.png"],
  ["Auditoria", "auditoria.png"],
  ["Regras", "regras.png"],
  ["Proveniência", "proveniencia.png"],
]) {
  const preview = await workbook.render({
    sheetName,
    autoCrop: "all",
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(previewDir, fileName),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(JSON.stringify({ outputPath, previewDir, rows: records.length }, null, 2));
