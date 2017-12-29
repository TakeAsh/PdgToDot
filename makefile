# PdgToDot sample make file

DIR_SAMPLES = ./Samples

SVGS = \
	$(DIR_SAMPLES)/Isono.svg \
	$(DIR_SAMPLES)/Simpsons.svg

PNGS = \
	$(DIR_SAMPLES)/Isono.png \
	$(DIR_SAMPLES)/Simpsons.png

DOTS = \
	$(DIR_SAMPLES)/Isono.dot \
	$(DIR_SAMPLES)/Simpsons.dot

.SUFFIXES: .svg .png .dot .pdg

.dot.svg:
	dot -Tsvg -o $@ $<
	dot -Tsvg -o $*_LR.svg $*_LR.dot

.dot.png:
	dot -Tpng -o $@ $<
	dot -Tpng -o $*_LR.png $*_LR.dot

.pdg.dot:
	perl ./PdgToDot.pl $<
	perl ./TBtoLR.pl $<
	perl ./PdgToDot.pl $*_LR.pdg

.PHONY: all
all: svg png;

.PHONY: svg
svg: $(SVGS)

.PHONY: png
png: $(PNGS)

.PHONY: dot
dot: $(DOTS)

.PHONY: clean
clean:
	rm -f $(DIR_SAMPLES)/*.svg $(DIR_SAMPLES)/*.png $(DIR_SAMPLES)/*.dot $(DIR_SAMPLES)/*_LR.pdg

$(DIR_SAMPLES)/Isono.svg:
$(DIR_SAMPLES)/Isono.png:
$(DIR_SAMPLES)/Isono.dot:

$(DIR_SAMPLES)/Simpsons.svg:
$(DIR_SAMPLES)/Simpsons.png:
$(DIR_SAMPLES)/Simpsons.dot:

