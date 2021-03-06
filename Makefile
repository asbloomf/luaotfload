# Makefile for luaotfload

NAME         = luaotfload
DOC          = $(NAME).pdf
DTX          = $(NAME).dtx
OTFL         = $(wildcard luaotfload-*.lua) luaotfload-blacklist.cnf

GLYPHSCRIPT  = mkglyphlist
GLYPHSOURCE  = glyphlist.txt
CHARSCRIPT   = mkcharacters

RESOURCESCRIPTS = $(GLYPHSCRIPT) $(CHARSCRIPT)

SCRIPTNAME   = luaotfload-tool
SCRIPT       = $(SCRIPTNAME).lua
MANSOURCE	 = $(SCRIPTNAME).rst
MANPAGE   	 = $(SCRIPTNAME).1
OLDSCRIPT    = luaotfload-legacy-tool.lua

GRAPH  		 = filegraph
DOTPDF 		 = $(GRAPH).pdf
DOT    		 = $(GRAPH).dot

# Files grouped by generation mode
GLYPHS      = luaotfload-glyphlist.lua
CHARS       = luaotfload-characters.lua
RESOURCES	= $(GLYPHS) $(CHARS)
GRAPHED     = $(DOTPDF)
MAN			= $(MANPAGE)
COMPILED    = $(DOC)
UNPACKED    = luaotfload.sty luaotfload.lua
GENERATED   = $(GRAPHED) $(UNPACKED) $(COMPILED) $(RESOURCES) $(MAN)
SOURCE 		= $(DTX) $(MANSOURCE) $(OTFL) README Makefile NEWS $(RESOURCESCRIPTS)

# test files
TESTDIR 		= tests
TESTFILES 		= $(wildcard $(TESTDIR)/*.tex $(TESTDIR)/*.ltx)
TESTFILES_SYS 	= $(TESTDIR)/systemfonts.tex $(TESTDIR)/fontconfig_conf_reading.tex
TESTFILES_TL 	= $(filter-out $(TESTFILES_SYS), $(TESTFILES))

# Files grouped by installation location
SCRIPTFILES = $(SCRIPT) $(OLDSCRIPT) $(RESOURCESCRIPTS)
RUNFILES    = $(UNPACKED) $(filter-out $(SCRIPTFILES),$(OTFL))
DOCFILES    = $(DOC) $(DOTPDF) README NEWS
MANFILES	= $(MANPAGE)
SRCFILES    = $(DTX) Makefile

# The following definitions should be equivalent
# ALL_FILES = $(RUNFILES) $(DOCFILES) $(SRCFILES)
ALL_FILES = $(GENERATED) $(SOURCE)

# Installation locations
FORMAT = luatex
SCRIPTDIR = $(TEXMFROOT)/scripts/$(NAME)
RUNDIR    = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR    = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
MANDIR    = $(TEXMFROOT)/doc/man/man1/
SRCDIR    = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)
TEXMFROOT = $(shell kpsewhich --var-value TEXMFHOME)

CTAN_ZIP = $(NAME).zip
TDS_ZIP  = $(NAME).tds.zip
ZIPS 	 = $(CTAN_ZIP) $(TDS_ZIP)

LUA	= texlua

DO_TEX 		  	= luatex --interaction=batchmode $< >/dev/null
# (with the next version of latexmk: -pdf -pdflatex=lualatex)
DO_LATEX 	  	= latexmk -pdf -e '$$pdflatex = q(lualatex %O %S)' -silent $< >/dev/null
DO_GRAPHVIZ 	= dot -Tpdf -o $@ $< > /dev/null
DO_GLYPHS 		= $(LUA) $(GLYPHSCRIPT) > /dev/null
DO_CHARS 		= $(LUA) $(CHARSCRIPT)  > /dev/null
DO_DOCUTILS 	= rst2man $< >$@ 2>/dev/null

all: $(GENERATED)
graph: $(GRAPHED)
doc: $(GRAPHED) $(COMPILED) $(MAN)
manual: $(MAN)
unpack: $(UNPACKED)
resources: $(RESOURCES)
chars: $(CHARS)
ctan: $(CTAN_ZIP)
tds: $(TDS_ZIP)
world: all ctan

$(GLYPHS): /dev/null
	$(DO_GLYPHS)

$(CHARS): /dev/null
	$(DO_CHARS)

$(GRAPHED): $(DOT)
	$(DO_GRAPHVIZ)

$(COMPILED): $(DTX)
	$(DO_LATEX)

$(UNPACKED): $(DTX)
	$(DO_TEX)

$(MAN): $(MANSOURCE)
	$(DO_DOCUTILS)

$(CTAN_ZIP): $(SOURCE) $(COMPILED) $(TDS_ZIP)
	@echo "Making $@ for CTAN upload."
	@$(RM) -- $@
	@zip -9 $@ $^ >/dev/null

define run-install
@mkdir -p $(SCRIPTDIR) && cp $(SCRIPTFILES) $(SCRIPTDIR)
@mkdir -p $(RUNDIR) && cp $(RUNFILES) $(RUNDIR)
@mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
@mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
@mkdir -p $(MANDIR) && cp $(MANFILES) $(MANDIR)
endef

$(TDS_ZIP): TEXMFROOT=./tmp-texmf
$(TDS_ZIP): $(ALL_FILES)
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	$(run-install)
	@cd $(TEXMFROOT) && zip -9 ../$@ -r . >/dev/null
	@$(RM) -r -- $(TEXMFROOT)

.PHONY: install manifest clean mrproper

install: $(ALL_FILES)
	@echo "Installing in '$(TEXMFROOT)'."
	$(run-install)

check: $(RUNFILES) $(TESTFILES_TL)
	@rm -rf var
	@for f in $(TESTFILES_TL); do \
	    echo "check: luatex $$f"; \
	    luatex --interaction=batchmode $$f \
	    > /dev/null || exit $$?; \
	    done

check-all: $(TESTFILES_SYS) check
	@cd $(TESTDIR); for f in $(TESTFILES_SYS); do \
	    echo "check: luatex $$f"; \
	    $(TESTENV) luatex --interaction=batchmode ../$$f \
	    > /dev/null || exit $$?; \
	    done

manifest: 
	@echo "Source files:"
	@for f in $(SOURCE); do echo $$f; done
	@echo ""
	@echo "Derived files:"
	@for f in $(GENERATED); do echo $$f; done

clean: 
	@$(RM) -- *.log *.aux *.toc *.idx *.ind *.ilg *.out $(TESTDIR)/*.log

mrproper: clean
	@$(RM) -- $(GENERATED) $(ZIPS) $(GLYPHSOURCE) $(TESTDIR)/*.pdf

