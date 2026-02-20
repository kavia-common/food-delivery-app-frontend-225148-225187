#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/food-delivery-app-frontend-225148-225187/database"
APP_DIR="$WORKSPACE/app"
cd "$APP_DIR"
mkdir -p "$WORKSPACE/logs"
# Only start hosting emulator to serve the build
IMPORT_ARG=""
if [ -d ./firebase ]; then IMPORT_ARG="--import=./firebase --export-on-exit"; fi
nohup env NODE_ENV=production firebase emulators:start --only hosting --project firebase-emulator-project $IMPORT_ARG >"$WORKSPACE/logs/validation-emu.out" 2>"$WORKSPACE/logs/validation-emu.err" &
EMU_PID=$!
# capture PGID (may be same as PID if not in new pg)
EMU_PGID=$(ps -o pgid= -p "$EMU_PID" | tr -d ' ' || echo "")
printf "%s\n" "$EMU_PID" > "$WORKSPACE/.validation_emulator.pid"
printf "%s\n" "$EMU_PGID" > "$WORKSPACE/.validation_emulator.pgid"
# small delay to let logs start
sleep 0.5
# print minimal info
echo "$EMU_PID" >"$WORKSPACE/logs/validation_emu_pid.txt"
