import * as path from "node:path";
import * as fsp from "fs/promises";
import { ImportedJsonSpec, JsonSpec } from "./types";
import { processSprite } from "./sprite";
import { processBackground } from "./background";

/**
 * Loads the json spec from the file path and converts all file paths
 * inside to absolute paths so the rest of the tool doesn't have to think about it
 */
function hydrateJsonSpec(jsonSpecPath: string): JsonSpec {
  const rootDir = path.dirname(jsonSpecPath);
  const initialSpec = require(jsonSpecPath) as ImportedJsonSpec;

  return {
    ...initialSpec,
    outputDir: path.resolve(rootDir, initialSpec.outputDir),
    sprites: (initialSpec.sprites ?? []).map((s) => {
      return {
        ...s,
        file: path.resolve(rootDir, s.file),
      };
    }),
    backgrounds: (initialSpec.backgrounds ?? []).map((bg) => {
      return {
        ...bg,
        file: path.resolve(rootDir, bg.file),
      };
    }),
  };
}

async function main(jsonSpec: JsonSpec) {
  for (const sprite of jsonSpec.sprites) {
    const processResult = await processSprite(sprite);
    const fileRoot = path.basename(sprite.file, path.extname(sprite.file));
    const tilesAsmPath = path.resolve(
      jsonSpec.outputDir,
      `${fileRoot}.tiles.asm`
    );
    const paletteAsmPath = path.resolve(
      jsonSpec.outputDir,
      `${fileRoot}.palette.asm`
    );

    await fsp.writeFile(tilesAsmPath, processResult.tilesAsmSrc);
    console.log("wrote", tilesAsmPath);
    await fsp.writeFile(paletteAsmPath, processResult.paletteAsmSrc);
    console.log("wrote", paletteAsmPath);
  }

  for (const bg of jsonSpec.backgrounds) {
    const processResult = await processBackground(bg);

    const fileRoot = path.basename(bg.file, path.extname(bg.file));
    const tilesAsmPath = path.resolve(
      jsonSpec.outputDir,
      `${fileRoot}.tiles.asm`
    );
    const paletteAsmPath = path.resolve(
      jsonSpec.outputDir,
      `${fileRoot}.palette.asm`
    );
    const mapAsmPath = path.resolve(jsonSpec.outputDir, `${fileRoot}.map.asm`);

    await fsp.writeFile(tilesAsmPath, processResult.tilesAsmSrc);
    console.log("wrote", tilesAsmPath);
    await fsp.writeFile(paletteAsmPath, processResult.paletteAsmSrc);
    console.log("wrote", paletteAsmPath);
    await fsp.writeFile(mapAsmPath, processResult.mapAsmSrc);
    console.log("wrote", mapAsmPath);
  }
}

if (require.main === module) {
  const [_tsNode, _convertpng, jsonSpecPath] = process.argv;

  if (!jsonSpecPath) {
    console.error("usage: ts-node convertpng/main.ts <json-spec-path>");
    process.exit(1);
  }

  const jsonSpec = hydrateJsonSpec(path.resolve(jsonSpecPath));

  main(jsonSpec)
    .then(() => console.log("done"))
    .catch((e) => console.error(e));
}
