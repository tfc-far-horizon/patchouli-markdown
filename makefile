GREEN := 
YELLOW := 
RED := 
RESET := 
BLUE := 

export SHELL=/bin/zsh
TEXTEMPDIR = texworks


define CABAL
	cabal --with-compiler=wasm32-wasi-ghc --with-hc-pkg=wasm32-wasi-ghc-pkg --with-hsc2hs=wasm32-wasi-hsc2hs $(1) $(2) $(3)
endef


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


LHS2TEX = lhs2TeX
TEX     = xelatex -output-directory=$(TEXTEMPDIR) --synctex=1


DIST = dist
SRC  = src
DOCS = docs



all: wasm-dists docs




docs: docspath docsmade

docspath:
	@mkdir -p $(DOCS) $(TEXTEMPDIR)

docsmade: $(patsubst $(SRC)/%.lhs,$(DOCS)/%.pdf,$(wildcard $(SRC)/*.lhs))
	@echo all docs made

$(TEXTEMPDIR)/%.tex: $(SRC)/%.lhs ./lhs2tex.header
#	$(shell (cat ./lhs2tex.header && cat $< && echo $$'\\end{document}') | lhs2TeX --poly > $@)
	{ cat ./lhs2tex.header; cat "$<"; printf '%s\n' '\end{document}'; } | lhs2TeX --poly > "$@"

$(TEXTEMPDIR)/%.pdf: $(TEXTEMPDIR)/%.tex
	@echo
	sed -i "s/\\documentclass{article}/\\documentclass{ctexart}/" $<
	$(TEX) $<


$(DOCS)/%.pdf: $(TEXTEMPDIR)/%.pdf
	@-mkdir -p $(DOCS)
	cp $< $@
	cp $(subst .pdf,.synctex.gz,$<) $(subst .pdf,.synctex.gz, $@)

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


NODE ?= node
$(DIST)/ghc_wasm_jsffi.mjs: $(DIST)/analyser.wasm
	$(NODE) "$$(wasm32-wasi-ghc --print-libdir)/post-link.mjs" -i "$<" -o "$@"


cleandocs:
	-rm -rf $(DOCS)
	-rm -rf $(TEXTEMPDIR)


restart: cleandocs
	-rm -rf $(DIST)

.PHONY: all cleandocs restart docspath distpath bin


bin:
	-mkdir ./bindist
	cabal build compiler
	cabal list-bin compiler | xargs -I {} cp {} ./bindist

