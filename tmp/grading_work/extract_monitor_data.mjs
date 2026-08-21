import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/trabalhos_graduacao_metodos_III_2026/planilha_monitoria/Notas MTPCP.xlsx";
const outputPath = "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/grading_work/monitor_rows.json";

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const sheet = workbook.worksheets.getItem("Notas listas");
const values = sheet.getRange("A1:E75").values;
await fs.writeFile(outputPath, JSON.stringify(values, null, 2), "utf8");
console.log(JSON.stringify({ outputPath, rows: values.length, columns: values[0]?.length ?? 0 }));
