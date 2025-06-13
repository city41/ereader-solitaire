export type BasicSpriteSpec = {
  file: string;
  frames: number;
  trimPalette?: boolean;
};

export type SharedPaletteSpriteSpec = {
  name: string;
  trimPalette?: boolean;
  sharedPalette: BasicSpriteSpec[];
};

export type SpriteSpec = BasicSpriteSpec | SharedPaletteSpriteSpec;

export type BackgroundSpec = {
  file: string;
  trimPalette?: boolean;
};

export type ImportedJsonSpec = {
  outputDir: string;

  sprites?: SpriteSpec[];
  backgrounds?: BackgroundSpec[];
};

export type JsonSpec = Required<ImportedJsonSpec>;
