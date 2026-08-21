import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbookPath = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/outputs/01a02455-4428-7e10-b65c-4328cbb55411/notas_metodos_III_2026.xlsx";
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(workbookPath));

const ranges = {
  Notas: ["A1:J12", "A76:J81"],
  Rubrica: ["A1:D16"],
  "Referência": ["A1:D16"],
  "Proveniência": ["A1:D16"],
};

const errorTokens = ["#REF!", "#DIV/0!", "#VALUE!", "#NAME?", "#N/A"];
const result = { sheets: {}, formulaErrors: [] };

for (const sheetName of Object.keys(ranges)) {
  const sheet = workbook.worksheets.getItem(sheetName);
  const used = sheet.getUsedRange();
  const values = used.values;
  const formulas = used.formulas;
  const errors = [];

  for (let r = 0; r < values.length; r += 1) {
    for (let c = 0; c < values[r].length; c += 1) {
      const value = String(values[r][c] ?? "");
      if (errorTokens.some((token) => value.includes(token))) {
        errors.push({ row: r + 1, column: c + 1, value });
      }
    }
  }

  result.sheets[sheetName] = {
    usedRows: values.length,
    usedColumns: values[0]?.length ?? 0,
    formulaCells: formulas.flat().filter((value) => String(value ?? "").startsWith("=")).length,
    ranges: Object.fromEntries(
      ranges[sheetName].map((address) => [address, sheet.getRange(address).values]),
    ),
  };
  result.formulaErrors.push(...errors.map((error) => ({ sheet: sheetName, ...error })));
}

console.log(JSON.stringify(result, null, 2));
