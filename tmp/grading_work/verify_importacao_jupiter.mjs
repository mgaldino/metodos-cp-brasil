import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP";
const workDir = path.join(projectRoot, "tmp/grading_work");
const verifyDir = "/private/tmp/codex-jupiter-verify-01a02455";

const configs = [
  {
    csv: "jupiter_2026101_noturno.csv",
    xlsx: "FLP0406_2026101_noturno.xlsx",
    expectedRows: 41,
  },
  {
    csv: "jupiter_2026102_diurno.csv",
    xlsx: "FLP0406_2026102_diurno.xlsx",
    expectedRows: 21,
  },
];

const results = [];
for (const config of configs) {
  const workbook = await SpreadsheetFile.importXlsx(
    await FileBlob.load(path.join(verifyDir, config.xlsx)),
  );
  const sheet = workbook.worksheets.getItemAt(0);
  const values = sheet.getUsedRange().values;
  const expectedWorkbook = await Workbook.fromCSV(
    await fs.readFile(path.join(workDir, config.csv), "utf8"),
    { sheetName: "Esperado" },
  );
  const expected = expectedWorkbook.worksheets.getItem("Esperado").getUsedRange().values;

  const normalizedActual = values.map((row, index) =>
    index === 0 ? row.map(String) : row.map(Number),
  );
  const normalizedExpected = expected.map((row, index) =>
    index === 0 ? row.map(String) : row.map(Number),
  );
  const exactMatch = JSON.stringify(normalizedActual) === JSON.stringify(normalizedExpected);
  const numericBody = normalizedActual.slice(1).every((row) =>
    row.every((value) => Number.isFinite(value)),
  );

  results.push({
    file: config.xlsx,
    rows: values.length - 1,
    headers: values[0],
    exactMatch,
    numericBody,
    passed:
      values.length === config.expectedRows + 1 &&
      JSON.stringify(values[0].map(String)) ===
        JSON.stringify(["Numero USP", "Frequencia", "Nota"]) &&
      exactMatch &&
      numericBody,
  });
}

const validation = {
  verifiedAfterRoundTripXlsToXlsx: true,
  results,
  allChecksPassed: results.every((result) => result.passed),
};

console.log(JSON.stringify(validation, null, 2));
if (!validation.allChecksPassed) process.exitCode = 1;
