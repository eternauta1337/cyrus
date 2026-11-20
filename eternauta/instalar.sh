#!/bin/bash
# Compila este fork de Cyrus y lo instala en un prefix, con el mismo layout que
# `npm install -g --prefix <prefix> cyrus-ai`: <prefix>/lib/node_modules/cyrus-ai y <prefix>/bin/cyrus.
# Así cualquier unit que hoy corre <prefix>/bin/cyrus pasa al fork sin cambios.
#
# Uso: eternauta/instalar.sh [--prefix DIR] [--ref REF]
#   --prefix  dónde instalar (por defecto ~/.local/cyrus)
#   --ref     qué compilar (por defecto lo que está en el checkout; ej. origin/eternauta)
#
# Requisitos: git, Node 22+ con corepack (trae pnpm). No reinicia nada: después hay que reiniciar
# los servicios que corren Cyrus. La instalación anterior queda en cyrus-ai.anterior para volver.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
PREFIX=$HOME/.local/cyrus; REF=
while [ $# -gt 0 ]; do
  case $1 in
    --prefix) PREFIX=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    *) echo "uso: $0 [--prefix DIR] [--ref REF]" >&2; exit 2 ;;
  esac
done

if [ -n "$REF" ]; then
  [ -z "$(git status --porcelain)" ] || { echo "✗ el checkout tiene cambios sin commitear" >&2; exit 1; }
  git fetch -q origin
  git checkout -q --detach "$REF"
fi
COMMIT=$(git rev-parse --short HEAD)
VERSION=$(node -p 'require("./apps/cli/package.json").version')
echo "· compilando cyrus-ai $VERSION, fork en $COMMIT"

corepack enable --install-directory "$(dirname "$(command -v node)")" 2>/dev/null || true
pnpm install --frozen-lockfile >/dev/null
pnpm build >/dev/null

DEST=$PREFIX/lib/node_modules
NUEVO=$DEST/cyrus-ai.nuevo
mkdir -p "$DEST" "$PREFIX/bin"
rm -rf "$NUEVO"
pnpm --filter cyrus-ai deploy --prod --legacy "$NUEVO" >/dev/null
printf 'cyrus-ai %s\nfork eternauta1337/cyrus %s\ninstalado %s\n' \
  "$VERSION" "$(git rev-parse HEAD)" "$(date -u +%FT%TZ)" > "$NUEVO/ETERNAUTA"
node "$NUEVO/dist/src/app.js" --version >/dev/null || { echo "✗ la versión nueva no arranca" >&2; exit 1; }

chmod +x "$NUEVO/dist/src/app.js"

ANTERIOR="sin instalación anterior"
if [ -e "$DEST/cyrus-ai" ]; then
  rm -rf "$DEST/cyrus-ai.anterior"
  mv "$DEST/cyrus-ai" "$DEST/cyrus-ai.anterior"
  ANTERIOR="la anterior quedó en $DEST/cyrus-ai.anterior"
fi
mv "$NUEVO" "$DEST/cyrus-ai"
ln -sfn ../lib/node_modules/cyrus-ai/dist/src/app.js "$PREFIX/bin/cyrus"
echo "✓ instalado en $PREFIX ($VERSION + fork $COMMIT); $ANTERIOR"
echo "· falta reiniciar los servicios que corren Cyrus"
