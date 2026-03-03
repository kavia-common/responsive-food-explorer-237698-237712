#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend}"
cd "$WORKSPACE"
# if package.json exists, validate scripts and exit
if [ -f package.json ]; then
  if ! grep -q '"start"' package.json || ! grep -q '"build"' package.json; then
    echo "package.json exists but 'start' or 'build' missing; please add scripts: \"start\": \"vite --host\" and \"build\": \"vite build\"" >&2
    exit 4
  fi
  echo "scaffold: package.json present, skipping scaffold"
  exit 0
fi
# detect TS by tsconfig.json or .ts/.tsx files
IS_TS=0
if [ -f tsconfig.json ] || find . -maxdepth 2 -type f \( -name '*.ts' -o -name '*.tsx' \) | grep -q .; then IS_TS=1; fi
# create minimal package.json pinned to stable versions
cat > package.json <<JSON
{
  "name": "responsive-food-explorer-backend",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "start": "vite --host",
    "build": "vite build",
    "preview": "vite preview",
    "serve": "npx serve -s dist",
    "test": "jest --colors"
  },
  "engines": { "node": ">=16" },
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "vite": "5.1.0"
  }
}
JSON
mkdir -p src
if [ "$IS_TS" -eq 1 ]; then
  cat > tsconfig.json <<TS
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"]
}
TS
  cat > src/main.tsx <<TS
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
createRoot(document.getElementById('root') as HTMLElement).render(<App />)
TS
  cat > src/App.tsx <<TS
import React from 'react'
export default function App(){ return <div>Hello from Vite React (TS)</div> }
TS
  MAIN_EXT="tsx"
else
  cat > src/main.jsx <<JS
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
createRoot(document.getElementById('root')).render(<App />)
JS
  cat > src/App.jsx <<JS
import React from 'react'
export default function App(){ return <div>Hello from Vite React</div> }
JS
  MAIN_EXT="jsx"
fi
cat > index.html <<HTML
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>App</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.${MAIN_EXT}"></script></body>
</html>
HTML
# Attempt to persist the scaffold helper for automation agents; if writing fails, print manual one-shot block
SCAFFOLD_SH=.init/scaffold.sh
mkdir -p .init
cat > "$SCAFFOLD_SH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# scaffold helper created by scaffold step
WORKSPACE="${WORKSPACE:-/home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend}"
cd "$WORKSPACE"
# no-op since primary scaffold already executed when package.json missing
exit 0
SH
chmod +x "$SCAFFOLD_SH" || true
# verify write succeeded; if not, provide manual one-shot commands for the engineer to run inside the container
if [ ! -f "$SCAFFOLD_SH" ]; then
  cat >&2 <<'EOF'
ERROR: automation agent could not write the scaffold helper file (.init/scaffold.sh). To proceed manually inside the container run the following exact commands (single block):

mkdir -p /home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend && cd /home/saqiba/Desktop/test_rle/workspace/tmp/kavia/code-generation/responsive-food-explorer-237698-237712/backend && \
cat > package.json <<'JSON'
{
  "name": "responsive-food-explorer-backend",
  "version": "0.0.1",
  "private": true,
  "scripts": {"start":"vite --host","build":"vite build","preview":"vite preview","serve":"npx serve -s dist","test":"jest --colors"},
  "engines":{"node":">=16"},
  "dependencies": {"react":"18.2.0","react-dom":"18.2.0"},
  "devDependencies":{"vite":"5.1.0"}
}
JSON
mkdir -p src && cat > src/main.${MAIN_EXT} <<'SRC'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
createRoot(document.getElementById('root')).render(<App />)
SRC
cat > src/App.${MAIN_EXT == 'tsx' && printf 'tsx' || printf 'jsx'} <<'APP'
import React from 'react'
export default function App(){ return <div>Hello from Vite React</div> }
APP
cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>App</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.${MAIN_EXT}"></script></body>
</html>
HTML

After creating files, run: npm install --no-audit --no-fund --silent

EOF
  exit 5
fi

echo "scaffold: created minimal vite react app (ts=${IS_TS})"
