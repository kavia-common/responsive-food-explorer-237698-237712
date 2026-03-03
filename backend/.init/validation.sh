#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend"
cd "$WORKSPACE"
export CI=true
export BROWSER=none
export NODE_ENV=production
export PATH="$PWD/node_modules/.bin:$PATH"
PORT="${VALIDATION_PORT:-3000}"
export PORT
# ensure build done
if [ ! -f package.json ]; then echo "package.json missing" >&2; exit 2; fi
if [ -d dist ] || [ -d build ]; then
  : # build output present
else
  # run build using canonical build script
  if [ -f yarn.lock ]; then
    yarn install --silent --immutable || yarn install --silent
    yarn build --silent
  else
    if [ -f package-lock.json ]; then npm ci --silent; else npm i --silent; fi
    npm run build --silent
  fi
fi
# start server
bash .init/start.sh
# capture response
TMP_HTML=/tmp/validation_response.html
curl -sS --max-time 5 "http://127.0.0.1:$PORT/" | head -c 200 > "$TMP_HTML" || true
sed -n '1,5p' "$TMP_HTML" || true
# stop server
bash .init/stop.sh
