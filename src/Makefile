# Makefile.asm
#
# This Makefile takes z80 assembly code and does everything need to get it bunbled into raw cards, bmps, and can
# also directly run the result in mGBA
#
# The compiled z80 bin can either be one you have made via assembling a z80 program, or one you
# have extracted out of an existing e-reader card
SHELL :=/bin/bash


# root name of the z80 assembly file (without the .asm extension) that is the starting point of everything here 
Z80_ASM_NAME=main
# The primary name that will show up in the E-Reader interface
EREADER_NAME=Solitaire
# The root name for the raw and bmp files, will be $OUTNAME.ereader1.raw, $OUTNAME.ereader2.raw, $OUTNAME.dotcode1.bmp, etc
OUTNAME=solitaire

# make sure your bin directory just above is setup for your operating system
# wine is unfortunately needed because the linux version of nedcmake has a bug that
# often prevents it from working
WINE=wine
BIN=../bin
RAW2BMP=$(BIN)/raw2bmp
NEDCMAKE=$(WINE) $(BIN)/nedcmake.exe
NEFLMAKE=$(BIN)/neflmake
NEVPK=$(BIN)/nevpk
ASLINK=$(BIN)/aslink
ASZ80=$(BIN)/asz80
# convertpng is a node program
CONVERTPNG=../scripts/convertpng.sh

REGION ?= 1
DPI ?= 1200

# the mgba executable on your path. In order to use runraws it will need to be a pretty recent version
MGBA=mgbae.sh
# the ereader rom for each region
EREADER_MGBA_ROM=~/roms/gba/ereaderUSA.zip
EREADER_MGBA_ROM_SAV=~/roms/gba/ereaderUSA.sav
EREADER_MGBA_ROM_JPN=~/roms/gba/ereaderJPN.zip
EREADER_MGBA_ROM_SAV_JPN=~/roms/gba/ereaderJPN.sav

sav: $(OUTNAME).sav

gfx:
	$(CONVERTPNG) $(shell pwd)/resources/resources.json

$(OUTNAME).sav: $(Z80_ASM_NAME).vpk
	$(NEFLMAKE) -i $(Z80_ASM_NAME).vpk -o $(OUTNAME).sav -type 1 -name "$(EREADER_NAME)" 

# this craziness allows this Makefile to work no matter how many strips a given z80 binary needs
# so after nedcmake runs, if it made one raw or 8 raws, it will create new make rules for each created raw
# that way "make raws" or "make bmps" makes the correct number accounting for all needed strips
raws.mk: $(Z80_ASM_NAME).vpk
	$(NEDCMAKE) -i $(Z80_ASM_NAME).vpk -o $(Z80_ASM_NAME).raw -type 1 -region $(REGION) -name "$(EREADER_NAME)" -raw -save 1;
	I=1; for r in $(Z80_ASM_NAME).raw*.raw; do \
		echo "$(OUTNAME).ereader$$I.raw: $r"; \
		echo "	mv $$r $(OUTNAME).ereader$$I.raw"; \
		echo "RAW_TARGETS += $(OUTNAME).ereader$$I.raw"; \
		echo "$(OUTNAME).ereader$$I.bmp: $(OUTNAME).ereader$$I.raw"; \
		echo "	$(RAW2BMP) -i $(OUTNAME).ereader$$I.raw -o $(OUTNAME).dotcode$$I -dpi $(DPI)"; \
		echo "BMP_TARGETS += $(OUTNAME).ereader$$I.bmp"; \
		((I = I + 1)); \
	done > $@

-include raws.mk

raws: $(RAW_TARGETS)
bmps: $(BMP_TARGETS)

$(Z80_ASM_NAME).vpk: $(Z80_ASM_NAME).bin
	$(NEVPK) -i $(Z80_ASM_NAME).bin -o $(Z80_ASM_NAME).vpk -c -level 2

$(Z80_ASM_NAME).bin: $(Z80_ASM_NAME).s19
	objcopy --input-target=srec --output-target=binary $(Z80_ASM_NAME).s19 $(Z80_ASM_NAME).bin

$(Z80_ASM_NAME).s19: $(Z80_ASM_NAME).rel
	$(ASLINK) -n -s $(Z80_ASM_NAME).rel

$(Z80_ASM_NAME).rel: $(Z80_ASM_NAME).asm
	$(ASZ80) -o -s -w $(Z80_ASM_NAME).asm

clean:
	rm -rf $(OUTNAME).ereader*.raw \
	$(Z80_ASM_NAME).vpk \
	$(Z80_ASM_NAME).rel \
	$(Z80_ASM_NAME).bin \
	$(Z80_ASM_NAME).s19 \
	$(Z80_ASM_NAME).raw-*.raw \
	raws.mk \
	$(OUTNAME).dotcode*.bmp \
	*.sav \
	*.sym

runsav: $(OUTNAME).sav
	rm $(EREADER_MGBA_ROM_SAV);
	cp $(OUTNAME).sav $(EREADER_MGBA_ROM_SAV);
	$(MGBA) $(EREADER_MGBA_ROM)

runsavjpn: $(OUTNAME).sav
	rm $(EREADER_MGBA_ROM_SAV_JPN);
	cp $(OUTNAME).sav $(EREADER_MGBA_ROM_SAV_JPN);
	$(MGBA) $(EREADER_MGBA_ROM_JPN)

