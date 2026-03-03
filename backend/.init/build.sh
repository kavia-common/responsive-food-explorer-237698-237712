#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend"
cd "$WORKSPACE"
# ensure headless env persisted (idempotent)
if [ ! -f /etc/profile.d/node_headless.sh ]; then
  sudo bash -c 'printf "export CI=true\nexport BROWSER=none\n" >/etc/profile.d/node_headless.sh'
fi
export CI=true
export BROWSER=none
# verify node and npm
if ! command -v node >/dev/null 2>&1; then echo "node not found" >&2; exit 2; fi
NODE_VERSION=$(node -v | sed 's/v//')
MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$MAJOR" -lt 16 ]; then echo "node >=16 required, found $NODE_VERSION" >&2; exit 3; fi
if [ ! -f package.json ]; then echo "package.json missing" >&2; exit 4; fi
export NODE_ENV=production
export PATH="$PWD/node_modules/.bin:$PATH"
# choose package manager and run build
if [ -f yarn.lock ]; then
  yarn install --silent --immutable || yarn install --silent
  yarn build --silent
else
  if [ -f package-lock.json ]; then
    npm ci --silent
  else
    npm i --silent
  fi
  npm run build --silent
fi
