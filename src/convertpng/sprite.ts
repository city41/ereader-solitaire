import { toAsm } from "./asm";
import { createCanvasFromPath, reduceColors } from "./canvas";
import { BasicSpriteSpec, SharedPaletteSpriteSpec, SpriteSpec } from "./types";
import { extractPalette, reducePalettes } from "./palette";
import { extractTiles } from "./tile";
import { Canvas } from "canvas";

type ProcessSpriteResult = {
  tilesAsmSrc: string[];
  paletteAsmSrc: string;
};

function isBasicSpriteSpec(sprite: SpriteSpec): sprite is BasicSpriteSpec {
  return "file" in sprite;
}

async function processBasicSprite(
  sprite: BasicSpriteSpec
): Promise<ProcessSpriteResult> {
  const canvas = await reduceColors(
    await createCanvasFromPath(sprite.file),
    16
  );

  const palette = extractPalette(canvas, !sprite.trimPalette);

  const tiles = extractTiles(canvas, palette, sprite.frames).flat(1);

  return {
    tilesAsmSrc: [toAsm(tiles, "b", 4)],
    paletteAsmSrc: toAsm(palette, "w", 4),
  };
}

async function processSharedPaletteSprites(
  sharedPaletteSprite: SharedPaletteSpriteSpec
): Promise<ProcessSpriteResult> {
  const canvases: Canvas[] = [];
  const palettes: number[][] = [];

  for (let i = 0; i < sharedPaletteSprite.sharedPalette.length; ++i) {
    const c = await reduceColors(
      await createCanvasFromPath(sharedPaletteSprite.sharedPalette[i].file),
      16
    );
    canvases.push(c);
    palettes.push(extractPalette(c, !sharedPaletteSprite.trimPalette));
  }

  const commonPalette = reducePalettes(palettes);

  const tiles: number[][] = [];
  for (let i = 0; i < sharedPaletteSprite.sharedPalette.length; ++i) {
    const t = extractTiles(
      canvases[i],
      commonPalette,
      sharedPaletteSprite.sharedPalette[i].frames
    ).flat(1);
    tiles.push(t);
  }

  return {
    tilesAsmSrc: tiles.map((t) => toAsm(t, "b", 4)),
    paletteAsmSrc: toAsm(commonPalette, "w", 4),
  };
}

async function processSprite(sprite: SpriteSpec): Promise<ProcessSpriteResult> {
  if (isBasicSpriteSpec(sprite)) {
    return processBasicSprite(sprite);
  } else {
    return processSharedPaletteSprites(sprite);
  }
}

export { isBasicSpriteSpec, processSprite };
export type { ProcessSpriteResult };
