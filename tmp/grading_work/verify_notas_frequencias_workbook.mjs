import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP";
const workbookPath = path.join(
  projectRoot,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411/notas_e_frequencias_metodos_III_2026.xlsx",
);
const expectedCsv = path.join(projectRoot, "tmp/grading_work/notas_frequencias_esperadas.csv");
const validationPath = path.join(projectRoot, "tmp/grading_work/validacao_planilha_notas_frequencias.json");

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(workbookPath));
const expectedWorkbook = await Workbook.fromCSV(
  await fs.readFile(expectedCsv, "utf8"),
  { sheetName: "Esperado" },
);

const expectedValues = expectedWorkbook.worksheets.getItem("Esperado").getUsedRange().values;
const expectedHeader = expectedValues[0];
const expectedRows = expectedValues.slice(1);
const ex = Object.fromEntries(expectedHeader.map((value, index) => [String(value), index]));

const auditSheet = workbook.worksheets.getItem("Auditoria");
const auditValues = auditSheet.getRange("A8:S81").values;
const launchValues = workbook.worksheets.getItem("Lançamento").getRange("A8:F81").values;

const asNumber = (value) => {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
};
const nearlyEqual = (left, right, tolerance = 0.000001) =>
  left !== null && right !== null && Math.abs(left - right) <= tolerance;

const discrepancies = [];
for (let i = 0; i < expectedRows.length; i += 1) {
  const expected = expectedRows[i];
  const audit = auditValues[i];
  const launch = launchValues[i];
  const expectedNusp = String(expected[ex.NUSP] ?? "");
  const expectedName = String(expected[ex.Nome] ?? "");
  const expectedGrade = asNumber(expected[ex.Nota_final]);
  const expectedFrequency = asNumber(expected[ex.Frequencia]);
  const expectedResult = String(expected[ex.Resultado] ?? "");

  if (String(audit[1] ?? "") !== expectedNusp) {
    discrepancies.push({ row: i + 8, field: "NUSP Auditoria", expected: expectedNusp, actual: audit[1] });
  }
  if (String(audit[0] ?? "") !== expectedName) {
    discrepancies.push({ row: i + 8, field: "Nome Auditoria", expected: expectedName, actual: audit[0] });
  }
  if (!nearlyEqual(asNumber(audit[10]), expectedGrade)) {
    discrepancies.push({ row: i + 8, field: "Nota final Auditoria", expected: expectedGrade, actual: audit[10] });
  }
  if (!nearlyEqual(asNumber(audit[13]), expectedFrequency)) {
    discrepancies.push({ row: i + 8, field: "Frequência Auditoria", expected: expectedFrequency, actual: audit[13] });
  }
  if (String(audit[14] ?? "") !== expectedResult) {
    discrepancies.push({ row: i + 8, field: "Resultado Auditoria", expected: expectedResult, actual: audit[14] });
  }

  if (
    String(launch[0] ?? "") !== expectedName ||
    String(launch[1] ?? "") !== expectedNusp ||
    !nearlyEqual(asNumber(launch[2]), expectedGrade) ||
    !nearlyEqual(asNumber(launch[3]), expectedFrequency) ||
    String(launch[4] ?? "") !== expectedResult
  ) {
    discrepancies.push({ row: i + 8, field: "Lançamento", expected: [expectedName, expectedNusp, expectedGrade, expectedFrequency, expectedResult], actual: launch.slice(0, 5) });
  }
}

const errorTokens = ["#REF!", "#DIV/0!", "#VALUE!", "#NAME?", "#N/A"];
const formulaErrors = [];
let formulaCells = 0;
for (const sheetName of ["Lançamento", "Auditoria", "Regras", "Proveniência"]) {
  const used = workbook.worksheets.getItem(sheetName).getUsedRange();
  const values = used.values;
  const formulas = used.formulas;
  for (let row = 0; row < values.length; row += 1) {
    for (let column = 0; column < values[row].length; column += 1) {
      const value = String(values[row][column] ?? "");
      if (errorTokens.some((token) => value.includes(token))) {
        formulaErrors.push({ sheetName, row: row + 1, column: column + 1, value });
      }
      if (String(formulas[row]?.[column] ?? "").startsWith("=")) formulaCells += 1;
    }
  }
}

const approvedRows = auditValues.filter((row) => row[14] === "Aprovado");
const failedRows = auditValues.filter((row) => row[14] === "Reprovado");
const noWorkNoLists = auditValues.filter((row) => row[16] === "Não" && row[8] === "Não");
const noWorkSomeList = auditValues.filter((row) => row[16] === "Não" && row[8] === "Sim");
const completeRows = auditValues.filter((row) => row[17] === "Sim");
const workMissingLists = auditValues.filter((row) => row[16] === "Sim" && row[7] === "Não");

const rulesChecks = {
  students: auditValues.length === 74,
  approved: approvedRows.length === 57,
  failed: failedRows.length === 17,
  approvedFloor: approvedRows.every((row) => asNumber(row[13]) >= 75),
  noWorkNoListsZero: noWorkNoLists.length === 11 && noWorkNoLists.every((row) => asNumber(row[13]) === 0),
  noWorkSomeListFifty: noWorkSomeList.length === 6 && noWorkSomeList.every((row) => asNumber(row[13]) === 50),
  completeBonus: completeRows.length === 48 && completeRows.every((row) => asNumber(row[9]) === 0.5),
  incompletePenalty: auditValues.filter((row) => row[17] === "Não").every((row) => asNumber(row[9]) === -0.5),
  workMissingListFrequencyPenalty: workMissingLists.length === 9 && workMissingLists.every((row) => asNumber(row[12]) === 10),
};

const inspect = await workbook.inspect({
  kind: "table,formula",
  sheetId: "Auditoria",
  range: "A7:S14",
  maxChars: 6000,
  tableMaxRows: 8,
  tableMaxCols: 19,
  options: { maxResults: 120 },
});

const validation = {
  workbookPath,
  sheets: workbook.worksheets.items.map((sheet) => sheet.name),
  formulaCells,
  discrepancies,
  formulaErrors,
  rulesChecks,
  inspect: inspect.ndjson,
  allChecksPassed:
    discrepancies.length === 0 &&
    formulaErrors.length === 0 &&
    Object.values(rulesChecks).every(Boolean),
};

await fs.writeFile(validationPath, `${JSON.stringify(validation, null, 2)}\n`, "utf8");
console.log(JSON.stringify(validation, null, 2));

if (!validation.allChecksPassed) process.exitCode = 1;
