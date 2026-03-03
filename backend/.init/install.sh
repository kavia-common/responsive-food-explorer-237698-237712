#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend}"
cd "$WORKSPACE"

# Persist headless env vars idempotently for future shells
PROFILE_FILE="/etc/profile.d/node_headless.sh"
TMP_FILE="/tmp/node_headless.sh.$$"
cat >"$TMP_FILE" <<'EOF'
# headless node environment for CI and to prevent browsers opening
export CI=true
export BROWSER=none
EOF
if [ ! -f "$PROFILE_FILE" ] || ! cmp -s "$TMP_FILE" "$PROFILE_FILE"; then
  sudo mv "$TMP_FILE" "$PROFILE_FILE"
  sudo chmod 644 "$PROFILE_FILE"
else
  rm -f "$TMP_FILE"
fi

# verify node >=16 and npm available
if ! command -v node >/dev/null 2>&1; then echo "node not found" >&2; exit 10; fi
NODE_VERSION=$(node -v | sed 's/^v//')
NODE_MAJOR=${NODE_VERSION%%.*}
if [ "$NODE_MAJOR" -lt 16 ]; then echo "node >=16 required, found $NODE_VERSION" >&2; exit 11; fi
if ! command -v npm >/dev/null 2>&1; then echo "npm not found" >&2; exit 12; fi

# ensure package.json exists
if [ ! -f package.json ]; then echo "package.json not found" >&2; exit 2; fi

# choose package manager based on lockfiles
PM="npm"
if [ -f yarn.lock ]; then PM="yarn"; fi
if [ -f yarn.lock ] && [ -f package-lock.json ]; then echo "Warning: both yarn.lock and package-lock.json present; preferring yarn" >&2; PM="yarn"; fi

# run deterministic install
if [ "$PM" = "npm" ]; then
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund --silent
  else
    npm install --no-audit --no-fund --silent
  fi
else
  if command -v yarn >/dev/null 2>&1; then
    if [ -f yarn.lock ]; then
      # try immutable install first, fall back to normal install if immutable fails
      yarn install --immutable --silent || yarn install --silent
    else
      yarn install --silent
    fi
  else
    echo "yarn not available, falling back to npm" >&2
    npm install --no-audit --no-fund --silent
  fi
fi

# verify node_modules exists
if [ ! -d node_modules ]; then echo "install failed: node_modules missing" >&2; exit 3; fi

# print core package versions if present
for pkg in react react-dom vite; do
  if [ -f "node_modules/$pkg/package.json" ]; then
    node -e "try{console.log(require('./node_modules/$pkg/package.json').version)}catch(e){}" 2>/dev/null || true
  fi
done
