#!/bin/bash
# Compila este fork de Cyrus y lo instala en un prefix, con el mismo layout que
# `npm install -g --prefix <prefix> cyrus-ai`: <prefix>/lib/node_modules/cyrus-ai y <prefix>/bin/cyrus.
# Así cualquier unit que hoy corre <prefix>/bin/cyrus pasa al fork sin cambios.
#
# Uso: eternauta/instalar.sh [--prefix DIR | --en RUTA] [--ref REF]
#   --prefix  dónde instalar (por defecto ~/.local/cyrus)
#   --en      reemplaza el paquete cyrus-ai que está en RUTA, sin tocar bin/. Para una app que tiene
#             cyrus-ai como dependencia: --en <app>/node_modules/cyrus-ai. El paquete nuevo trae sus
#             dependencias adentro (cyrus-edge-worker, cyrus-claude-runner…), así que lo que esté
#             parcheado en <app>/node_modules/cyrus-* deja de usarse.
#   --ref     qué compilar (por defecto lo que está en el checkout; ej. origin/eternauta)
#
# Requisitos: git, Node 22+ con corepack (trae pnpm). No reinicia nada: después hay que reiniciar
# los servicios que corren Cyrus. La instalación anterior queda en cyrus-ai.anterior para volver.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
PREFIX=$HOME/.local/cyrus; REF=; EN=
while [ $# -gt 0 ]; do
  case $1 in
    --prefix) PREFIX=$2; shift 2 ;;
    --en) EN=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    *) echo "uso: $0 [--prefix DIR | --en RUTA] [--ref REF]" >&2; exit 2 ;;
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

if [ -n "$EN" ]; then
  EN=${EN%/}; [ "$(basename "$EN")" = cyrus-ai ] || { echo "✗ --en tiene que terminar en /cyrus-ai" >&2; exit 2; }
  DEST=$(dirname "$EN"); PREFIX=$DEST
else
  DEST=$PREFIX/lib/node_modules
fi
NUEVO=$DEST/cyrus-ai.nuevo
mkdir -p "$DEST"
rm -rf "$NUEVO" "$NUEVO.links"
pnpm --filter cyrus-ai deploy --prod --legacy "$NUEVO.links" >/dev/null
# pnpm deploy arma el árbol con hardlinks: los paquetes del workspace comparten inodo con
# packages/*/dist de este checkout. tsc reescribe esos archivos en el lugar, así que un `pnpm build`
# acá le cambiaba el código a la instalación que está corriendo, sin los archivos nuevos. El 23/11
# eso dejó los tres Cyrus de archi caídos 11 horas al primer reinicio (ALE-182). Una copia propia
# (cp -R no sigue los symlinks de .pnpm) la desata del checkout y de la store de pnpm.
cp -R "$NUEVO.links" "$NUEVO"
rm -rf "$NUEVO.links"
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
if [ -z "$EN" ]; then
  mkdir -p "$PREFIX/bin"
  ln -sfn ../lib/node_modules/cyrus-ai/dist/src/app.js "$PREFIX/bin/cyrus"
fi
echo "✓ instalado en $PREFIX ($VERSION + fork $COMMIT); $ANTERIOR"
echo "· falta reiniciar los servicios que corren Cyrus"
