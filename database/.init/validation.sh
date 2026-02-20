#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/food-delivery-app-frontend-225148-225187/database"
APP_DIR="$WORKSPACE/app"
cd "$APP_DIR"
mkdir -p "$WORKSPACE/logs"
: >"$WORKSPACE/.setup_logs" || true
# Ensure build exists; if not, call build script
if [ ! -d build ] || [ -z "$(ls -A build 2>/dev/null)" ]; then
  bash "$WORKSPACE/.init/build.sh" || { echo "build step failed" | tee -a "$WORKSPACE/.setup_logs"; exit 2; }
fi
# prepare import arg only if exists
IMPORT_ARG=""
if [ -d ./firebase ]; then IMPORT_ARG="--import=./firebase --export-on-exit"; fi
# start hosting emulator only
nohup env NODE_ENV=production firebase emulators:start --only hosting --project firebase-emulator-project $IMPORT_ARG >"$WORKSPACE/logs/validation-emu.out" 2>"$WORKSPACE/logs/validation-emu.err" &
EMU_PID=$!
EMU_PGID=$(ps -o pgid= -p "$EMU_PID" | tr -d ' ' || echo "")
printf "%s\n" "$EMU_PID" > "$WORKSPACE/.validation_emulator.pid"
printf "%s\n" "$EMU_PGID" > "$WORKSPACE/.validation_emulator.pgid"
# readiness helper
wait_for(){ host=$1; port=$2; timeout=${3:-40}; i=0; while :; do if command -v curl >/dev/null 2>&1; then code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://$host:$port/" || echo "000"); if echo "$code" | grep -E '^2' >/dev/null; then return 0; fi; fi; if (exec 3<>/dev/tcp/$host/$port) >/dev/null 2>&1; then exec 3>&-; return 0; fi; i=$((i+1)); if [ $i -ge $timeout ]; then return 1; fi; sleep 1; done }
if ! wait_for localhost 5000 40; then echo "hosting emulator not ready" | tee -a "$WORKSPACE/.setup_logs"; # attempt cleanup
  if [ -n "$EMU_PGID" ]; then sudo kill -TERM -"$EMU_PGID" 2>/dev/null || true; sleep 1; sudo kill -KILL -"$EMU_PGID" 2>/dev/null || true; fi
  exit 3
fi
# fetch root and capture status
status=$(curl -s -o "$WORKSPACE/logs/validation_index.html" -w '%{http_code}' --max-time 5 http://localhost:5000/ || echo "000")
FIRE_VER=$(command -v firebase >/dev/null 2>&1 && firebase --version 2>/dev/null || echo unknown)
printf "%s\n" "firebase: $FIRE_VER" >>"$WORKSPACE/.setup_logs"
printf "%s\n" "hosting_status:$status" >>"$WORKSPACE/.setup_logs"
# capture headers
curl -sI --max-time 3 http://localhost:5000/ | head -n10 >"$WORKSPACE/logs/validation_headers.txt" || true
# capture small evidence files already written: validation_index.html and headers
# cleanup: try graceful, then force
if [ -n "$EMU_PGID" ] && [ "$EMU_PGID" != "" ]; then
  sudo kill -TERM -"$EMU_PGID" 2>/dev/null || true; sleep 1; sudo kill -KILL -"$EMU_PGID" 2>/dev/null || true;
else
  if [ -n "$EMU_PID" ] && [ "$EMU_PID" != "" ]; then
    sudo kill -TERM "$EMU_PID" 2>/dev/null || true; sleep 1; sudo kill -KILL "$EMU_PID" 2>/dev/null || true;
  fi
fi
printf "%s\n" "validation completed" >>"$WORKSPACE/.setup_logs" || true
