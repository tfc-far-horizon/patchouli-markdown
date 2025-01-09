GREEN := 
YELLOW := 
RED := 
RESET := 
BLUE := 

TEXTEMPDIR = texworks

# CABAL = if command -v wasm32-wasi-cabal &>/dev/null; then wasm32-wasi-cabal; else cabal --with-compiler=
define CABAL
	wasm32-wasi-cabal $(1) $(2) $(3)
endef

#   env -i GHCRTS=-H64m "$(type -P wizer)" --allow-wasi --wasm-bulk-memory true --inherit-env true --init-func _initialize -o dist/bin.wasm "$hs_wasm_path"
#   wasm-opt ${1+"$@"} dist/bin.wasm -o dist/bin.wasm
#   wasm-tools strip -o dist/bin.wasm dist/bin.wasm

define WIZER
	env -i GHCRTS=-H64m $$HOME/.ghc-wasm/wasmtime/bin/wizer \
		--allow-wasi \
		--wasm-bulk-memory true \
		--inherit-env true \
		--init-func _initialize \
		-o $(2) \
		$(1) && \
	$$HOME/.ghc-wasm/binaryen/bin/wasm-opt $(2) -o $(2); \
	$$HOME/.ghc-wasm/wasmtime/bin/wasm-tools strip -o $(2) $(2);
endef

define NVM
	NVM_DIR="$$HOME/.nvm" \
	[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" \
	&& nvm $(1) $(2) $(3)
endef
LHS2TEX = lhs2TeX
TEX     = xelatex -output-directory=$(TEXTEMPDIR) --synctex=1

DIST = dist
SRC  = src
DOCS = docs

all: wasm-dists docs

# make docs

docs: docspath docsmade

docspath:
	@mkdir -p $(DOCS) $(TEXTEMPDIR)

docsmade: $(patsubst $(SRC)/%.lhs,$(DOCS)/%.pdf,$(wildcard $(SRC)/*.lhs))
	@echo all docs made

$(TEXTEMPDIR)/%.tex: $(SRC)/%.lhs ./lhs2tex.header
	$(shell (cat ./lhs2tex.header && cat $< && echo $$'\\end{document}') | lhs2TeX --poly > $@)

$(TEXTEMPDIR)/%.pdf: $(TEXTEMPDIR)/%.tex
	@echo
	sed -i "s/\\documentclass{article}/\\documentclass{ctexart}/" $<
	sed -i "s/$$\\end{document}/\\end{document}/" $<
	$(TEX) $<

$(DOCS)/%.pdf: $(TEXTEMPDIR)/%.pdf
	@-mkdir -p $(DOCS)
	cp $< $@
	cp $(subst .pdf,.synctex.gz,$<) $(subst .pdf,.synctex.gz, $@)


# make wasms

wasm-dists: distpath $(DIST)/compiler.wasm $(DIST)/analyser.wasm $(DIST)/ghc_wasm_jsffi.mjs $(DIST)/wizer.wasm
	@echo all bindists made

distpath:
	@mkdir -p $(DIST)

dist/wizer.wasm: $(DIST)/analyser.wasm
	$(call WIZER, $<, $@)

$(DIST)/%.wasm: $(wildcard src/*.lhs) $(wildcard src/*.hs) igem-markdown.cabal
	@echo 
	$(call CABAL, build, $(notdir $(basename $@)))
	@echo $(GREEN)copy/register ..$(RESET)
	find dist-newstyle -name $(notdir $@) -exec cp {} ./${DIST}/ \;
	@echo $(GREEN)done$(RESET)

$(DIST)/ghc_wasm_jsffi.mjs: $(DIST)/analyser.wasm
	$(call NVM, run, lts/jod) $$(wasm32-wasi-ghc --print-libdir)/post-link.mjs -i $< -o $@

cleandocs:
	-rm -rf $(DOCS)
	-rm -rf $(TEXTEMPDIR)

restart: cleandocs
	-rm -rf $(DIST)

.PHONY: all cleandocs restart docspath distpath
