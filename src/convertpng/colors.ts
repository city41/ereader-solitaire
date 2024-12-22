function rgbToGBA16(r: number, g: number, b: number): number {
  const gbaR = Math.floor((31 * r) / 255);
  const gbaG = Math.floor((31 * g) / 255);
  const gbaB = Math.floor((31 * b) / 255);

  return (gbaB << 10) | (gbaG << 5) | gbaR;
}

export { rgbToGBA16 };
