#!/bin/bash
# Confere, arquivo por arquivo, se o motor dentro do app é idêntico ao publicado pelos projetos oficiais.
# Uso: tools/verify-engine.sh "/Applications/Hero Saga para Mac.app"
set -euo pipefail
APP="${1:-/Applications/Hero Saga para Mac.app}"
REF="$(mktemp -d)"; trap 'rm -rf "$REF"' EXIT
"$(dirname "$0")/fetch-engine.sh" "$REF/engine" >/dev/null
if diff -rq "$REF/engine" "$APP/Contents/Resources/engine"; then
  echo "OK: todos os arquivos do motor são idênticos aos oficiais."
else
  echo "ATENÇÃO: há diferenças (listadas acima)."; exit 1
fi
