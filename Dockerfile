FROM texlive/texlive:latest-full

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_SOURCE
ARG IMAGE_DESCRIPTION="CI image for igem-markdown"
ARG IMAGE_LICENSE="AGPL-3.0-or-later"

ARG GHC_NATIVE_VERSION=9.12.2
ARG CABAL_VERSION=3.14.2.0
ARG GHC_WASM_VERSION=wasm32-wasi-9.12
ARG GHC_WASM_GHCUP_CHANNEL=https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/ghcup-wasm-0.0.9.yaml

LABEL org.opencontainers.image.source="${IMAGE_SOURCE}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.licenses="${IMAGE_LICENSE}"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Keep the global environment native and minimal.
# Do NOT put wasm CC/AR/LD/etc. here: native ghcup/cabal steps must not see them.
ENV HOME=/root
ENV TEXMFHOME=/root/.texmf
ENV PATH=/root/.ghcup/bin:/root/.cabal/bin:/root/.local/bin:${PATH}

# Base tools. Stable layer.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    file \
    git \
    gpg \
    jq \
    locales \
    unzip \
    xz-utils \
    zstd \
    zsh \
  && locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Native build dependencies used by ghcup, native GHC/Cabal, and C-backed Haskell packages.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    make \
    patch \
    pkg-config \
    libffi-dev \
    libffi8 \
    libgmp-dev \
    libgmp10 \
    libncurses-dev \
    libncurses6 \
    libtinfo6 \
  && rm -rf /var/lib/apt/lists/*

# JavaScript/WASM-side tools that the project build may call directly.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
  && rm -rf /var/lib/apt/lists/*

# Install ghcup without letting it install a default toolchain implicitly.
RUN curl -fsSL https://get-ghcup.haskell.org \
  | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_MINIMAL=1 \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    sh

# Native Haskell toolchain. This must run before any wasm environment is sourced.
RUN ghcup install ghc "${GHC_NATIVE_VERSION}" --set -f
RUN ghcup install cabal "${CABAL_VERSION}" --set -f

# Native lhs2TeX install. This intentionally uses native cabal/ghc, not wasm CC/AR/LD.
RUN cabal update \
  && cabal install lhs2tex --overwrite-policy=always

# Install ghc-wasm-meta support tools, but skip GHC here because we install it with ghcup below.
RUN curl -fsSL https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/bootstrap.sh \
  | SKIP_GHC=1 sh

# Small helper: source ghc-wasm-meta's generated env only for commands that need it.
# This avoids globally poisoning native builds with wasm CC/AR/LD.
RUN cat > /usr/local/bin/with-ghc-wasm-env <<'EOF_HELPER' \
  && chmod +x /usr/local/bin/with-ghc-wasm-env
#!/usr/bin/env bash
set -euo pipefail
GHC_WASM_ENV_FILE="${GHC_WASM_ENV:-/root/.ghc-wasm/env}"
if [[ ! -f "${GHC_WASM_ENV_FILE}" ]]; then
  echo "with-ghc-wasm-env: ${GHC_WASM_ENV_FILE} not found" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${GHC_WASM_ENV_FILE}"
exec "$@"
EOF_HELPER

# Install the wasm GHC. CONFIGURE_ARGS and wasm CC/AR/LD are taken from /root/.ghc-wasm/env
# only inside this RUN layer.
RUN source /root/.ghc-wasm/env \
  && : "${CONFIGURE_ARGS:=--host=x86_64-linux --target=wasm32-wasi --with-intree-gmp --with-system-libffi}" \
  && ghcup config add-release-channel "${GHC_WASM_GHCUP_CHANNEL}" \
  && ghcup install ghc "${GHC_WASM_VERSION}" -- ${CONFIGURE_ARGS} \
  && ghcup set ghc "${GHC_WASM_VERSION}"

# Prewarm the wasm Cabal index. Use the wasm wrapper, not plain cabal.
RUN with-ghc-wasm-env wasm32-wasi-cabal update

# Make interactive shells convenient without affecting earlier native Docker build steps.
RUN echo 'source /root/.ghc-wasm/env' > /etc/profile.d/ghc-wasm.sh

WORKDIR /workspace

# Optional project-specific dependency prewarming.
# This Dockerfile is a toolchain image by default, so it does not COPY the project source.
# If you want to bake igem-markdown dependencies into the image, add COPY lines before this RUN.
RUN if [[ -f cabal.project ]] || compgen -G '*.cabal' > /dev/null; then \
      with-ghc-wasm-env wasm32-wasi-cabal build compiler --only-dependencies; \
    else \
      echo 'No Cabal project files copied; skipping project dependency prewarm.'; \
    fi
