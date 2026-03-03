#!/usr/bin/env bash
set -euo pipefail
# Minimal smoke test runner that prefers project-local jest, else global jest, else node check
WORKSPACE="${WORKSPACE:-/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend}"
cd "$WORKSPACE"
# ensure headless env for this run (persisting to /etc/profile.d is done in env-setup step)
export CI=true
export BROWSER=none
# ensure local .bin on PATH
export PATH="$PWD/node_modules/.bin:$PATH"
if [ ! -d "$WORKSPACE" ]; then
  echo "ERROR: workspace not found: $WORKSPACE" >&2
  exit 2
fi
# prefer project-local jest
if [ -x ./node_modules/.bin/jest ]; then
  mkdir -p __tests__
  if [ ! -f __tests__/smoke.test.js ]; then
    cat > __tests__/smoke.test.js <<'JS'
test('smoke', () => { expect(1+1).toBe(2) })
JS
  fi
  ./node_modules/.bin/jest --colors --runInBand
elif command -v jest >/dev/null 2>&1; then
  TMPD=$(mktemp -d)
  cat > "$TMPD/smoke.test.js" <<'JS'
test('smoke', () => { expect(1+1).toBe(2) })
JS
  jest --runInBand --colors "$TMPD" || { rm -rf "$TMPD"; exit 2; }
  rm -rf "$TMPD"
else
  # final fallback: quick node runtime assertion
  node -e "if(1+1!==2){console.error('smoke failed');process.exit(2)}"
fi
