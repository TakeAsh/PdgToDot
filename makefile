# PdgToDot sample make file

DIR_SAMPLES = ./Samples
TARGET1 = Isono
TARGET2 = Simpsons
TARGET3 = Joestars
TARGET4 = ShogiPlayers

SVGS = \
	$(DIR_SAMPLES)/$(TARGET1).svg \
	$(DIR_SAMPLES)/$(TARGET2).svg \
	$(DIR_SAMPLES)/$(TARGET3).svg \
	$(DIR_SAMPLES)/$(TARGET4).svg

PNGS = \
	$(DIR_SAMPLES)/$(TARGET1).png \
	$(DIR_SAMPLES)/$(TARGET2).png \
	$(DIR_SAMPLES)/$(TARGET3).png \
	$(DIR_SAMPLES)/$(TARGET4).png

DOTS = \
	$(DIR_SAMPLES)/$(TARGET1).dot \
	$(DIR_SAMPLES)/$(TARGET2).dot \
	$(DIR_SAMPLES)/$(TARGET3).dot \
	$(DIR_SAMPLES)/$(TARGET4).dot

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

.PHONY: $(TARGET1)
$(TARGET1): $(DIR_SAMPLES)/$(TARGET1).svg $(DIR_SAMPLES)/$(TARGET1).png
$(DIR_SAMPLES)/$(TARGET1).svg:
$(DIR_SAMPLES)/$(TARGET1).png:
$(DIR_SAMPLES)/$(TARGET1).dot:

.PHONY: $(TARGET2)
$(TARGET2): $(DIR_SAMPLES)/$(TARGET2).svg $(DIR_SAMPLES)/$(TARGET2).png
$(DIR_SAMPLES)/$(TARGET2).svg:
$(DIR_SAMPLES)/$(TARGET2).png:
$(DIR_SAMPLES)/$(TARGET2).dot:

.PHONY: $(TARGET3)
$(TARGET3): $(DIR_SAMPLES)/$(TARGET3).svg $(DIR_SAMPLES)/$(TARGET3).png
$(DIR_SAMPLES)/$(TARGET3).svg:
$(DIR_SAMPLES)/$(TARGET3).png:
$(DIR_SAMPLES)/$(TARGET3).dot:

.PHONY: $(TARGET4)
$(TARGET4): $(DIR_SAMPLES)/$(TARGET4).svg $(DIR_SAMPLES)/$(TARGET4).png
$(DIR_SAMPLES)/$(TARGET4).svg:
$(DIR_SAMPLES)/$(TARGET4).png:
$(DIR_SAMPLES)/$(TARGET4).dot:
