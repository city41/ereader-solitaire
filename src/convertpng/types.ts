export type SpriteSpec = {
  file: string;
  frames: number;
};

export type BackgroundSpec = {
  file: string;
};

export type ImportedJsonSpec = {
  outputDir: string;

  sprites?: SpriteSpec[];
  backgrounds?: BackgroundSpec[];
};

export type JsonSpec = Required<ImportedJsonSpec>;
