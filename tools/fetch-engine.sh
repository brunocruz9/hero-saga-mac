#!/bin/bash
# Baixa o motor Wine direto das fontes oficiais, confere SHA-256 e monta a pasta engine/.
# Uso: tools/fetch-engine.sh [pasta_destino]   (padrão: ./engine)
set -euo pipefail
DEST="${1:-$(cd "$(dirname "$0")/.." && pwd)/engine}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WINECX_URL="https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineCX24.0.7_7.tar.xz"
WINECX_SHA256="203f9e9fd6c2cc77e6525d798a434ced326145db34a356355e05659d3445fd1c"
STAGING_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.21/wine-staging-11.21-osx64.tar.xz"
STAGING_SHA256="d7bcd5abf4df27aae397a7898aef074fea4a2e0b51e0a55aa9659517bbf9d452"

get() { # url sha arquivo
  echo "Baixando $1"
  curl -fL --retry 3 -o "$3" "$1"
  echo "$2  $3" | shasum -a 256 -c -
}
get "$WINECX_URL" "$WINECX_SHA256" "$TMP/winecx.tar.xz"
get "$STAGING_URL" "$STAGING_SHA256" "$TMP/staging.tar.xz"

rm -rf "$DEST"; mkdir -p "$DEST" "$TMP/staging"
tar -xJf "$TMP/winecx.tar.xz" -C "$DEST"
tar -xJf "$TMP/staging.tar.xz" -C "$TMP/staging"
# Bibliotecas de suporte que o WineCX espera ao lado do wswine.bundle
cp -a "$TMP/staging/Wine Staging.app/Contents/Resources/wine/lib/"*.dylib "$DEST/"
# Mono e Gecko não são usados pelo Hero Saga (o launcher pula o Setup.exe .NET)
rm -rf "$DEST/wswine.bundle/share/wine/mono" "$DEST/wswine.bundle/share/wine/gecko"
echo "Motor pronto em $DEST"
