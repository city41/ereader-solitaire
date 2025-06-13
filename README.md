# Solitaire for the Nintendo E-Reader

This is the classic game of solitaire for the Nintendo E-Reader. It is written as an E-Reader z80 application.

![screenshot](https://github.com/city41/ereader-solitaire/blob/main/screenshot_2x.png?raw=true)

This is the first z80/ereader app I wrote, and so the code is pretty bad in places, and the build process is also pretty bad. I will eventually come back and modernize it.

## To build

Only tested on Ubuntu 22. It should "just work" on Ubuntu and other Linuxes

```bash
cd src
make clean && make sav
```

This will create `src/solitaire.sav` which can be loaded into an emulator or flash card along with the ereader ROM.

![running the sav](https://github.com/city41/ereader-solitaire/blob/main/runningSav.png?raw=true)

## Running in mGBA

As long as `mgba` is in your path, then `make clean && make runsav` should build the game then immediately launch it in mGBA. This requires the ereader ROM to be where the Makefile expects it. Look for `EREADER_MGBA_ROM` in the Makefile.

## Creating raws and bmps

To create raws, you will need wine installed. That is because the linux version of nedcmake has a bug and usually crashes.

`make raws` will build the `.raw` files that can then be loaded into an emulator or converted into bitmaps for printing.

`make bmps` will directly make the bmps for you, no need to muck with raws. You can set DPI too, `make DPI=600 bmps`, the default is 1200.

## Building on other OSes

I have never tested this. But basically you will need to get the proper ereader tools, place them in `bin/`, and then update the Makefile accordingly.

A modern port of the tools can be found here: https://github.com/breadbored/nedclib

The original tools for Windows can be found here: https://caitsith2.com/ereader/devtools.htm

## Changing the graphics

You will need nodejs for this. Make sure you run `yarn` at the root of the repo to get all the node modules.

Change the graphics in the `src/resources/` as you see fit. Then run `make gfx`. If you add frames of animation, `resources/resources.json` will need to be updated, as will the sprite definitions in the code.

The graphics are built using `src/convertpng`, a very simple png to gba graphics tool I made. I hope to one day make it full featured and release it on its own.

## The assembler

I wrote this using [asz80](https://shop-pdp.net/ashtml/asz80.htm) which is a very old, but pretty good, z80 assembler. It's main gotcha is it doesn't directly produce a binary. If you look in the Makefile, you will see asm->bin is several steps.

You can get asz80 binaries here: https://shop-pdp.net/ashtml/asxget.php

## Japanese support

Solitaire runs as-is on the Japanese E-Reader+. It has no text, and is completely compatible.

To build for Japanese: `make REGION=2 raws` or `make REGION=2 bmps`. `REGION=2` is not needed when building the sav file, as no region checking is done with sav files.

To run it in mGBA on the Japanese ereader ROM, `make runsavjpn`. With the sav file approach, there is no region checking. It will appear garbeled in the ereader menu, but other than that work just fine. You need to have the Japanese ereader ROM where the Makefile expects it. Check the Makefile for details.
