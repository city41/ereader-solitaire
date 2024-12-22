import { toAsm } from "./asm";
import { createCanvasFromPath, reduceColors } from "./canvas";
import { SpriteSpec } from "./types";
import { extractPalette } from "./palette";
import { extractTiles } from "./tile";

type ProcessSpriteResult = {
  tilesAsmSrc: string;
  paletteAsmSrc: string;
};

async function processSprite(sprite: SpriteSpec): Promise<ProcessSpriteResult> {
  const canvas = await reduceColors(
    await createCanvasFromPath(sprite.file),
    16
  );

  const palette = extractPalette(canvas);

  const tiles = extractTiles(canvas, palette, sprite.frames).flat(1);

  return {
    tilesAsmSrc: toAsm(tiles, "b", 4),
    paletteAsmSrc: toAsm(palette, "w", 4),
  };
}

export { processSprite };
export type { ProcessSpriteResult };
