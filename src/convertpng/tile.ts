import { Canvas, ImageData } from "canvas";
import { rgbToGBA16 } from "./colors";

function extractTile(imageData: ImageData, palette: number[]) {
  const tileData: number[] = [];

  for (let p = 0; p < imageData.data.length; p += 8) {
    // first pixel in tile, high nibble

    // if this pixel has any transparency, then use palette index 0
    // which will make it fully transparent on the gba

    let hindex = 0;

    if (imageData.data[p + 7] === 255) {
      // this is a fully opaque pixel, so use it
      const hr = imageData.data[p + 4];
      const hg = imageData.data[p + 5];
      const hb = imageData.data[p + 6];
      const hgbaColor = rgbToGBA16(hr, hg, hb);
      hindex = palette.indexOf(hgbaColor);
    }

    // second pixel in tile, low nibble

    // if this pixel has any transparency, then use palette index 0
    // which will make it fully transparent on the gba
    let lindex = 0;

    if (imageData.data[p + 3] === 255) {
      // this is a fully opaque pixel, so use it
      const lr = imageData.data[p + 0];
      const lg = imageData.data[p + 1];
      const lb = imageData.data[p + 2];
      const lgbaColor = rgbToGBA16(lr, lg, lb);
      lindex = palette.indexOf(lgbaColor);
    }

    const tileByte = ((hindex & 0xf) << 4) | (lindex & 0xf);

    tileData.push(tileByte);
  }

  return tileData;
}

// a GBA tile using a 16 color palette has two indexes per byte
// so one 8x8 tile is 4x8 bytes
//
// [ p1|p2,   p3|p4,   p5|p6,   p7|p8]
// [p9|p10, p11|p12, p13|p14, p15|p16]
// ...
//
// it is stored row oriented
// for an image that has multiple tiles, it is stored in a flat 1d array
//
// [a|b]
// [c|d]
//
// becomes [a][b][c][d]
//
// sprites with more than one frame look like this in the png
//
// [a1|b1][a2|b2]
// [c1|d1][c2|d2]
//
// and become this in the data
// [a1][b1][c1][d1][a2][b2][c2][d2]
function extractTiles(
  c: Canvas,
  palette: number[],
  frameCount: number
): number[][] {
  const context = c.getContext("2d")!;
  const tilesData: number[][] = [];

  const frameWidthT = c.width / 8 / frameCount;
  const frameHeightT = c.height / 8;

  for (let f = 0; f < frameCount; ++f) {
    for (let y = 0; y < frameHeightT; ++y) {
      for (let x = f * frameWidthT; x < (f + 1) * frameWidthT; ++x) {
        const imageData = context.getImageData(x * 8, y * 8, 8, 8);
        const curTileData = extractTile(imageData, palette);
        tilesData.push(curTileData);
      }
    }
  }

  return tilesData;
}

function dedupeTiles(tiles: number[][]): number[][] {
  const dedupedMap = tiles.reduce<Record<string, number[]>>((accum, tile) => {
    const key = tile.join(",");

    accum[key] = tile;

    return accum;
  }, {});

  return Object.values(dedupedMap);
}

export { extractTiles, dedupeTiles };
