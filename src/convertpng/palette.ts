import { Canvas } from "canvas";
import { rgbToGBA16 } from "./colors";

const MAGENTA = rgbToGBA16(255, 0, 255);

function extractPalette(c: Canvas, pad = true): number[] {
  const gbaColors = new Set<number>();

  const imageData = c.getContext("2d")!.getImageData(0, 0, c.width, c.height);

  for (let p = 0; p < imageData.data.length; p += 4) {
    // skip anything not fully opaque
    if (imageData.data[p + 3] !== 255) {
      continue;
    }

    const r = imageData.data[p];
    const g = imageData.data[p + 1];
    const b = imageData.data[p + 2];
    const gbaColor = rgbToGBA16(r, g, b);
    gbaColors.add(gbaColor);
  }

  const rawPalette = Array.from(gbaColors);
  // make sure there is no magenta in the palette
  const paletteWithoutMangenta = rawPalette.filter((c) => c !== MAGENTA);

  // then append magenta as the first color, to become transparent
  const palette = [MAGENTA].concat(paletteWithoutMangenta);
  while (pad && palette.length < 16) {
    palette.push(0);
  }

  return palette;
}

function reducePalettes(palettes: number[][]): number[] {
  const colorMap: Record<number, boolean> = {};
  const mergedPalette: number[] = [];

  for (const palette of palettes) {
    for (const color of palette) {
      if (!colorMap[color]) {
        colorMap[color] = true;
        mergedPalette.push(color);
      }
    }
  }

  if (mergedPalette.length > 16) {
    throw new Error(
      `reducePalette: final palette is too large: ${mergedPalette.length}`
    );
  }

  return mergedPalette;
}

export { extractPalette, reducePalettes };
