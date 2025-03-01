GREEN := 
YELLOW := 
RED := 
RESET := 
BLUE := 

export SHELL=/bin/bash
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
# env -i GHCRTS=-H64m：
# -i：忽略所有继承的环境变量。
# GHCRTS=-H64m：设置 GHC 的运行时系统选项，分配 64MB 的堆内存。
# $$HOME/.ghc-wasm/wasmtime/bin/wizer：
# $$HOME：表示用户的主目录。
# /.ghc-wasm/wasmtime/bin/wizer：表示 wizer 命令的路径。
# --allow-wasi：
# 允许使用 WebAssembly 系统接口（WASI）。
# --wasm-bulk-memory true：
# 启用 WebAssembly 的批量内存操作。
# --inherit-env true：
# 允许继承环境变量。
# --init-func _initialize：
# 设置初始化函数为 _initialize。
# -o $(2)：
# 指定输出文件为 $(2)。
# $(1)：
# 表示输入文件。
# &&：
# 表示前一个命令成功后执行下一个命令。
# $$HOME/.ghc-wasm/binaryen/bin/wasm-opt $(2) -o $(2)：
# 使用 wasm-opt 命令优化 WebAssembly 模块。
# $$HOME/.ghc-wasm/wasmtime/bin/wasm-tools strip -o $(2) $(2)：
# 使用 wasm-tools 命令移除 WebAssembly 模块中的调试信息。
define NVM
	NVM_DIR="$$HOME/.nvm" \
	[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" \
	&& nvm $(1) $(2) $(3)
endef
LHS2TEX = lhs2TeX
TEX     = xelatex -output-directory=$(TEXTEMPDIR) --synctex=1
# LHS2TEX：定义了 lhs2TeX 命令，用于将 Literate Haskell 文件转换为 TeX 文件。
# TEX：定义了 xelatex 命令，用于编译 TeX 文件。
DIST = dist
SRC  = src
DOCS = docs
# DIST：定义了输出目录 dist。
# SRC：定义了源代码目录 src。
# DOCS：定义了文档目录 docs。
all: wasm-dists docs
# all：默认目标，依赖于 wasm-dists 和 docs。
# wasm-dists：生成 WebAssembly 模块。
# docs：生成文档。

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
	$(TEX) $<
# @echo：输出一个空行。
# sed -i "s/\\documentclass{article}/\\documentclass{ctexart}/" $<：
# sed -i：直接修改文件内容。
# s/\\documentclass{article}/\\documentclass{ctexart}/：将 \\documentclass{article} 替换为 \\documentclass{ctexart}。
# $<：表示第一个依赖文件（即 $(TEXTEMPDIR)/%.tex）。
# $(TEX) $<：
# $(TEX)：调用 xelatex 命令编译 TeX 文件。
# $<：表示第一个依赖文件（即 $(TEXTEMPDIR)/%.tex）。

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
# $(call CABAL, build, $(notdir $(basename $@)))：
# $(call CABAL, ...)：调用 CABAL 宏。
# build：表示调用 cabal build 命令。
# $(notdir $(basename $@))：
# $@：表示目标文件，即 $(DIST)/%.wasm。
# basename $@：获取目标文件的基名，去掉路径和扩展名。
# notdir：获取文件名，去掉路径。
# 例如，如果目标文件是 dist/compiler.wasm，则 $(notdir $(basename $@)) 的值是 compiler。

# @echo $(GREEN)copy/register ..$(RESET)：
# 输出 copy/register ..，并使用 $(GREEN) 和 $(RESET) 设置颜色。
# $(GREEN)：设置文本颜色为绿色。
# $(RESET)：重置文本颜色。

# find dist-newstyle -name $(notdir $@) -exec cp {} ./${DIST}/ \;：
# find dist-newstyle -name $(notdir $@)：
# dist-newstyle：表示 dist-newstyle 目录。
# -name $(notdir $@)：匹配文件名与 $(notdir $@) 相同的文件。
# -exec cp {} ./${DIST}/ \;：
# -exec cp {} ./${DIST}/ \;：将匹配到的文件复制到 $(DIST) 目录。
# {}：表示匹配到的文件。
# ./${DIST}/：表示目标目录。
$(DIST)/ghc_wasm_jsffi.mjs: $(DIST)/analyser.wasm
	$(call NVM, run, stable) $$(wasm32-wasi-ghc --print-libdir)/post-link.mjs -i $< -o $@
# $(call NVM, run, lts/jod)：
# $(call NVM, ...)：调用 NVM 宏。
# run：表示调用 nvm run 命令。
# lts/jod：表示使用 lts/jod 版本的 Node.js。
# $$(wasm32-wasi-ghc --print-libdir)/post-link.mjs：
# wasm32-wasi-ghc --print-libdir：获取 wasm32-wasi-ghc 的库目录。
# post-link.mjs：表示 post-link.mjs 脚本。
# $$：在 Makefile 中，$$ 用于转义 $，以便在宏展开时正确解析。
# -i $< -o $@：
# -i $<：表示输入文件，即 $(DIST)/analyser.wasm。
# -o $@：表示输出文件，即 $(DIST)/ghc_wasm_jsffi.mjs。
cleandocs:
	-rm -rf $(DOCS)
	-rm -rf $(TEXTEMPDIR)
# 目标文件
# cleandocs：这是一个目标，表示清理文档和临时目录。
# 1.2 命令解释
# -rm -rf $(DOCS)：
# -rm：删除文件或目录的命令。
# -rf：递归删除，强制删除，不提示确认。
# $(DOCS)：表示文档目录，例如 docs。
# -：抑制错误信息，即使命令失败也不会导致整个规则失败。
# -rm -rf $(TEXTEMPDIR)：
# $(TEXTEMPDIR)：表示临时 TeX 文件目录，例如 texworks。
restart: cleandocs
	-rm -rf $(DIST)
# 1 目标文件
# restart：这是一个目标，表示清理所有生成的文件和目录。
# 2.2 依赖关系
# cleandocs：表示先执行 cleandocs 目标，清理文档和临时目录。
# 2.3 命令解释
# -rm -rf $(DIST)：
# $(DIST)：表示构建目录，例如 dist。
.PHONY: all cleandocs restart docspath distpath bin
# .PHONY：这是一个特殊目标，用于声明那些不依赖于文件的目标。
# all、cleandocs、restart、docspath、distpath、bin：这些目标被声明为 .PHONY，表示它们不依赖于同名的文件。
bin:
	-mkdir ./bindist
	cabal build compiler
	cabal list-bin compiler | xargs -I {} cp {} ./bindist
# 4.1 目标文件
# bin：这是一个目标，表示生成可执行文件。
# 4.2 命令解释
# -mkdir ./bindist：
# -mkdir：创建目录的命令。
# ./bindist：表示创建 bindist 目录。
# -：抑制错误信息，即使命令失败也不会导致整个规则失败。
# cabal build compiler：
# cabal build：使用 Cabal 构建项目。
# compiler：表示构建 compiler 项目。
# cabal list-bin compiler | xargs -I {} cp {} ./bindist：
# cabal list-bin compiler：列出 compiler 项目生成的可执行文件。
# |：管道符号，将前一个命令的输出作为下一个命令的输入。
# xargs -I {} cp {} ./bindist：
# xargs：将输入作为参数传递给命令。
# -I {}：指定输入的占位符为 {}。
# cp {} ./bindist：将输入的文件复制到 bindist 目录。


# 5. 具体执行过程
# 当你运行 make restart 时，make 会执行以下步骤：
# 清理文档和临时目录：
# cleandocs：删除 $(DOCS) 和 $(TEXTEMPDIR) 目录及其内容。
# 清理构建目录：
# restart：删除 $(DIST) 目录及其内容。
# 当你运行 make bin 时，make 会执行以下步骤：
# 创建 bindist 目录：
# bin：创建 bindist 目录（如果不存在）。
# 构建 compiler 项目：
# cabal build compiler：使用 Cabal 构建 compiler 项目。
# 复制可执行文件：
# cabal list-bin compiler | xargs -I {} cp {} ./bindist：将 compiler 项目生成的可执行文件复制到 bindist 目录。







# lhs2.header的注释补充在这里：
# 在 Makefile 中，有一行是这样的：
# makefile
# $(TEXTEMPDIR)/%.tex: $(SRC)/%.lhs ./lhs2tex.header
# 	$(shell (cat ./lhs2tex.header && cat $< && echo $$'\\end{document}') | lhs2TeX --poly > $@)
# 这行命令是说，对于每个 .lhs 文件，先输出 lhs2tex.header 的内容，然后是 .lhs 文件本身的内容，最后是 \\end{document}，然后通过 lhs2TeX --poly 命令转换成 .tex 文件。

# 按照 Makefile 的规则，这个文件会被转换成 .tex 文件，然后通过 LaTeX 编译成 PDF。在这个过程中，lhs2tex.header 中的格式化规则会被应用，确保 Haskell 代码在文档中正确显示。
# 我再想想，这个 lhs2tex.header 文件和 Makefile 的配合，确实可以让开发者更方便地生成高质量的文档。开发者只需要写好 .lhs 文件，然后运行 make 命令，就可以自动生成 PDF 文档，而不用手动处理格式化的问题。
# 我得总结一下这个过程。lhs2tex.header 文件定义了格式化规则，Makefile 自动化了转换和编译的过程。这样，开发者就可以专注于内容，而不用关心格式化和编译的细节。这个过程确实很高效，也很方便。


# 具体执行过程
# 生成 .tex 文件：
# cat ./lhs2tex.header：输出 lhs2tex.header 文件的内容。
# cat $<：输出 $(SRC)/%.lhs 文件的内容。
# echo $$'\\end{document}'：输出 \\end{document}。
# lhs2TeX --poly：将这些内容转换为 LaTeX 文件。
# 生成 .pdf 文件：
# $(TEXTEMPDIR)/%.pdf: $(TEXTEMPDIR)/%.tex：
# sed -i "s/\\documentclass{article}/\\documentclass{ctexart}/" $<：
# 将 \\documentclass{article} 替换为 \\documentclass{ctexart}。
# $(TEX) $<：
# 使用 xelatex 命令编译 TeX 文件。
# 复制 .pdf 文件：
# $(DOCS)/%.pdf: $(TEXTEMPDIR)/%.pdf：
# cp $< $@：将 .pdf 文件复制到 $(DOCS) 目录。
# cp $(subst .pdf,.synctex.gz,$<) $(subst .pdf,.synctex.gz, $@)：将 .synctex.gz 文件复制到 $(DOCS) 目录。
# 总结
# lhs2tex.header 文件定义了 LaTeX 文档的头部信息和格式化规则，用于将 Literate Haskell 文件转换为 LaTeX 文档。在 Makefile 中，这个文件被用于生成 .tex 文件，然后通过 LaTeX 编译生成 .pdf 文件。通过这种方式，Makefile 自动化地完成了从 Literate Haskell 文件到 PDF 文档的转换过程。