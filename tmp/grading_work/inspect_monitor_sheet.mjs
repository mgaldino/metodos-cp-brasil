import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/trabalhos_graduacao_metodos_III_2026/planilha_monitoria/Notas MTPCP.xlsx";
const outputDir = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/monitor_previews";

await fs.mkdir(outputDir, { recursive: true });
const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const overview = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 16000,
  tableMaxRows: 100,
  tableMaxCols: 30,
  tableMaxCellChars: 200,
});
console.log(overview.ndjson);

const sheets = workbook.worksheets.items;
for (const sheet of sheets) {
  const used = sheet.getUsedRange();
  if (used) {
    const details = await workbook.inspect({
      kind: "table,formula,computedStyle",
      sheetId: sheet.name,
      range: used.address,
      maxChars: 24000,
      tableMaxRows: 150,
      tableMaxCols: 40,
      tableMaxCellChars: 240,
      options: { maxResults: 300 },
    });
    console.log(details.ndjson);
  }

  const preview = await workbook.render({
    sheetName: sheet.name,
    autoCrop: "all",
    scale: 1.5,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^A-Za-z0-9_-]+/g, "_");
  await fs.writeFile(`${outputDir}/${safeName}.png`, new Uint8Array(await preview.arrayBuffer()));
}
