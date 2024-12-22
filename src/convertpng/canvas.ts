import * as path from "node:path";
import * as os from "node:os";
import * as fsp from "node:fs/promises";
import { Canvas, createCanvas, Image } from "canvas";
import magick from "imagemagick";
import { mkdirp } from "mkdirp";

async function _reduceColorsWithMagick(
  renderedFilePath: string,
  maxColors: number
): Promise<string> {
  const outputPath = `${renderedFilePath}.reduced.png`;

  return new Promise((resolve, reject) => {
    magick.convert(
      [
        renderedFilePath,
        "-dither",
        "none",
        "-colors",
        maxColors.toString(),
        `png8:${outputPath}`,
      ],
      (err) => {
        if (err) {
          reject(err);
        } else {
          resolve(outputPath);
        }
      }
    );
  });
}

async function reduceColors(c: Canvas, maxColors: number): Promise<Canvas> {
  const tmpDir = path.resolve(os.tmpdir(), `reduceColors_${Date.now()}`);
  await mkdirp(tmpDir);
  const tmpPath = path.resolve(
    tmpDir,
    `_reduceColors_${maxColors}_${Date.now()}.png`
  );
  const b = c.toBuffer();

  await fsp.writeFile(tmpPath, b);
  const reducedPath = await _reduceColorsWithMagick(tmpPath, maxColors);

  return createCanvasFromPath(reducedPath);
}

async function createCanvasFromPath(pngPath: string): Promise<Canvas> {
  return new Promise((resolve) => {
    const img = new Image();

    img.onload = () => {
      const canvas = createCanvas(img.width, img.height);
      const context = canvas.getContext("2d");
      context.drawImage(img, 0, 0);
      resolve(canvas);
    };

    img.src = pngPath;
  });
}

export { createCanvasFromPath, reduceColors };
