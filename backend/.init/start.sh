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
LOGFILE=/tmp/validation_server.log
# determine output dir
OUT_DIR="dist"
if [ ! -d "$OUT_DIR" ]; then
  if [ -d build ]; then OUT_DIR=build; else echo "build output not found (dist or build)" >&2; exit 5; fi
fi
# start server in its own process group so we can kill -PGID
if [ -x ./node_modules/.bin/serve ]; then
  setsid ./node_modules/.bin/serve -s "$OUT_DIR" -l "$PORT" >"$LOGFILE" 2>&1 &
  PID=$!
  PGID=$(ps -o pgid= $PID | tr -d ' ')
elif [ -x ./node_modules/.bin/vite ]; then
  setsid ./node_modules/.bin/vite preview --port "$PORT" >"$LOGFILE" 2>&1 &
  PID=$!
  PGID=$(ps -o pgid= $PID | tr -d ' ')
else
  setsid node -e "const http=require('http'),fs=require('fs'),path=require('path');const dir=process.argv[1]||'dist';const port=+process.env.PORT||3000;const srv=http.createServer((req,res)=>{let url=req.url.split('?')[0];let p=path.join(dir,url==='/'?'/index.html':url);fs.readFile(p,(e,d)=>{if(e){res.statusCode=404;res.end('not found');}else{res.end(d);}})});srv.listen(port,()=>console.log('static-server',process.pid));" "$OUT_DIR" >"$LOGFILE" 2>&1 &
  PID=$!
  PGID=$(ps -o pgid= $PID | tr -d ' ')
fi
# persist PID/PGID for stop
echo "$PID" >/tmp/validation_server.pid
echo "$PGID" >/tmp/validation_server.pgid
# wait for server to respond
for i in $(seq 1 30); do
  sleep 1
  if curl -sS --max-time 2 "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "server did not start; log:" >&2
    sed -n '1,200p' "$LOGFILE" >&2 || true
    exit 6
  fi
done
