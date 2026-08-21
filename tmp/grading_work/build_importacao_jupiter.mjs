import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP";
const workDir = path.join(projectRoot, "tmp/grading_work");
const outputDir = path.join(
  projectRoot,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411/importacao_jupiter",
);

const configs = [
  {
    csv: "jupiter_2026101_noturno.csv",
    xlsx: "FLP0406_2026101_noturno.xlsx",
    preview: "FLP0406_2026101_noturno.png",
    expectedRows: 41,
  },
  {
    csv: "jupiter_2026102_diurno.csv",
    xlsx: "FLP0406_2026102_diurno.xlsx",
    preview: "FLP0406_2026102_diurno.png",
    expectedRows: 21,
  },
];

await fs.mkdir(outputDir, { recursive: true });

for (const config of configs) {
  const csvText = await fs.readFile(path.join(workDir, config.csv), "utf8");
  const workbook = await Workbook.fromCSV(csvText, { sheetName: "Planilha1" });
  const sheet = workbook.worksheets.getItem("Planilha1");
  const used = sheet.getUsedRange();

  if (used.values.length !== config.expectedRows + 1) {
    throw new Error(`${config.csv}: número inesperado de linhas.`);
  }
  const headers = used.values[0].map(String);
  if (JSON.stringify(headers) !== JSON.stringify(["Numero USP", "Frequencia", "Nota"])) {
    throw new Error(`${config.csv}: cabeçalhos incompatíveis com o Júpiter.`);
  }
  const numericRows = used.values.slice(1).map((row) => [
    Number(row[0]),
    Number(row[1]),
    Number(row[2]),
  ]);
  if (numericRows.some((row) => row.some((value) => !Number.isFinite(value)))) {
    throw new Error(`${config.csv}: há valores não numéricos.`);
  }
  sheet.getRange(`A2:C${config.expectedRows + 1}`).values = numericRows;

  sheet.showGridLines = true;
  sheet.getRange(`A1:C${config.expectedRows + 1}`).format = {
    font: { name: "Arial", size: 10, color: "#000000" },
    verticalAlignment: "center",
  };
  sheet.getRange("A1:C1").format = {
    font: { name: "Arial", size: 10, bold: true, color: "#000000" },
    fill: "#E7E6E6",
    horizontalAlignment: "center",
  };
  sheet.getRange(`A2:A${config.expectedRows + 1}`).format.numberFormat = "0";
  sheet.getRange(`B2:B${config.expectedRows + 1}`).format.numberFormat = "0";
  sheet.getRange(`C2:C${config.expectedRows + 1}`).format.numberFormat = "0.0";
  sheet.getRange("A:A").format.columnWidth = 16;
  sheet.getRange("B:B").format.columnWidth = 14;
  sheet.getRange("C:C").format.columnWidth = 10;
  sheet.freezePanes.freezeRows(1);

  const inspect = await workbook.inspect({
    kind: "table",
    sheetId: "Planilha1",
    range: `A1:C${Math.min(config.expectedRows + 1, 8)}`,
    tableMaxRows: 8,
    tableMaxCols: 3,
    maxChars: 4000,
  });
  console.log(inspect.ndjson);

  const preview = await workbook.render({
    sheetName: "Planilha1",
    autoCrop: "all",
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(workDir, config.preview),
    new Uint8Array(await preview.arrayBuffer()),
  );

  const output = await SpreadsheetFile.exportXlsx(workbook);
  await output.save(path.join(outputDir, config.xlsx));
}

console.log(JSON.stringify({ outputDir, files: configs.map((config) => config.xlsx) }, null, 2));
