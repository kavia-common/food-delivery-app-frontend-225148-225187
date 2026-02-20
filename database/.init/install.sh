#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/food-delivery-app-frontend-225148-225187/database"
APP_DIR="$WORKSPACE/app"
cd "$APP_DIR"
mkdir -p "$WORKSPACE/logs"
# Deterministic install: prefer yarn --frozen-lockfile, else npm ci; fail fast on mismatch
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  yarn --silent --frozen-lockfile 2>"$WORKSPACE/logs/install-01.log" || { echo "yarn --frozen-lockfile failed" >&2; exit 7; }
elif [ -f package-lock.json ]; then
  npm ci --silent 2>"$WORKSPACE/logs/install-01.log" || { echo "npm ci failed" >&2; exit 8; }
else
  # no lockfile: best-effort install but fail on error
  if command -v yarn >/dev/null 2>&1; then
    yarn --silent 2>"$WORKSPACE/logs/install-01.log" || { echo "yarn install failed" >&2; exit 9; }
  else
    npm i --silent 2>"$WORKSPACE/logs/install-01.log" || { echo "npm install failed" >&2; exit 10; }
  fi
fi
# validate build tool presence (react-scripts for CRA) and record version
if [ -d node_modules ] && [ -f package.json ]; then
  if node -e "const p=require('./package.json'); const has=(p.dependencies&&p.dependencies['react-scripts'])||(p.devDependencies&&p.devDependencies['react-scripts']); if(has) process.exit(0); else process.exit(1);" 2>/dev/null; then
    node -e "console.log(require('./node_modules/react-scripts/package.json').version)" > "$WORKSPACE/logs/react-scripts.version" 2>/dev/null || true
  fi
fi
# record success for downstream steps
echo "install: ok" >> "$WORKSPACE/.setup_logs" || true
