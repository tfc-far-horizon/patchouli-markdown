FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_SOURCE
ARG IMAGE_DESCRIPTION="CI image for igem-markdown"
ARG IMAGE_LICENSE="AGPL-3.0-or-later"

LABEL org.opencontainers.image.source="${IMAGE_SOURCE}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.licenses="${IMAGE_LICENSE}"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV HOME=/root
ENV NVM_DIR=/root/.nvm
ENV CONFIGURE_ARGS="--host=x86_64-linux --target=wasm32-wasi --with-intree-gmp --with-system-libffi"

ENV PATH=/root/.ghcup/bin:/root/.cabal/bin:/root/.ghc-wasm/wasm-run/bin:/root/.ghc-wasm/wasm32-wasi-cabal/bin:/root/.ghc-wasm/wasmtime/bin:/root/.ghc-wasm/binaryen/bin:/root/.ghc-wasm/nodejs/lib/node_modules/.bin:/root/.ghc-wasm/nodejs/bin:/root/.ghc-wasm/wasi-sdk/bin:/root/.ghc-wasm/wasm32-wasi-ghc/bin:/root/.local/bin:${PATH}
ENV AR=/root/.ghc-wasm/wasi-sdk/bin/llvm-ar
ENV CC=/root/.ghc-wasm/wasi-sdk/bin/wasm32-wasi-clang
ENV CC_FOR_BUILD=cc
ENV CXX=/root/.ghc-wasm/wasi-sdk/bin/wasm32-wasi-clang++
ENV LD=/root/.ghc-wasm/wasi-sdk/bin/wasm-ld
ENV NM=/root/.ghc-wasm/wasi-sdk/bin/llvm-nm
ENV OBJCOPY=/root/.ghc-wasm/wasi-sdk/bin/llvm-objcopy
ENV OBJDUMP=/root/.ghc-wasm/wasi-sdk/bin/llvm-objdump
ENV RANLIB=/root/.ghc-wasm/wasi-sdk/bin/llvm-ranlib
ENV SIZE=/root/.ghc-wasm/wasi-sdk/bin/llvm-size
ENV STRINGS=/root/.ghc-wasm/wasi-sdk/bin/llvm-strings
ENV STRIP=/root/.ghc-wasm/wasi-sdk/bin/llvm-strip
ENV LLC=/bin/false
ENV OPT=/bin/false
ENV CONF_CC_OPTS_STAGE1="-Wno-error=int-conversion -O3 -mcpu=lime1 -mreference-types -msimd128"
ENV CONF_CXX_OPTS_STAGE1="-fno-exceptions -Wno-error=int-conversion -O3 -mcpu=lime1 -mreference-types -msimd128"
ENV CONF_GCC_LINKER_OPTS_STAGE1="-Wl,--error-limit=0,--keep-section=ghc_wasm_jsffi,--keep-section=target_features,--stack-first,--strip-debug "
ENV CONF_CC_OPTS_STAGE2="-Wno-error=int-conversion -O3 -mcpu=lime1 -mreference-types -msimd128"
ENV CONF_CXX_OPTS_STAGE2="-fno-exceptions -Wno-error=int-conversion -O3 -mcpu=lime1 -mreference-types -msimd128"
ENV CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--error-limit=0,--keep-section=ghc_wasm_jsffi,--keep-section=target_features,--stack-first,--strip-debug "
ENV CROSS_EMULATOR=/root/.ghc-wasm/wasm-run/bin/wasm-run.mjs
ENV NODE_PATH=/root/.ghc-wasm/nodejs/lib/node_modules
ENV TEXMFHOME=/root/.texmf

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    gpg \
    jq \
    libffi-dev \
    libgmp-dev \
    libncurses-dev \
    locales \
    make \
    nodejs \
    npm \
    patch \
    pkg-config \
    texlive-lang-chinese \
    texlive-latex-extra \
    texlive-xetex \
    unzip \
    xz-utils \
    zstd \
    zsh \
  && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

# Install ghcup and its default native toolchain first so we can build lhs2tex.
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get-ghcup.haskell.org \
  | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh

RUN source /root/.ghcup/env \
  && ghcup install cabal 3.14.2.0 \
  && ghcup set cabal 3.14.2.0 \
  && cabal update \
  && cabal install lhs2tex --overwrite-policy=always

# Install the wasm toolchain used by this project.
RUN curl -fsSL https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/bootstrap.sh \
  | SKIP_GHC=1 sh

RUN source /root/.ghcup/env \
  && ghcup config add-release-channel https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/ghcup-wasm-0.0.9.yaml \
  && ghcup install ghc wasm32-wasi-9.12 -- ${CONFIGURE_ARGS} \
  && ghcup set ghc wasm32-wasi-9.12

# Provide the same nvm-based Node.js entrypoint the Makefile expects.
RUN git clone --depth 1 https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
  && source "$NVM_DIR/nvm.sh" \
  && nvm install node \
  && nvm alias default node

WORKDIR /workspace
