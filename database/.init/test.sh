#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/food-delivery-app-frontend-225148-225187/database"
APP_DIR="$WORKSPACE/app"
cd "$APP_DIR"
mkdir -p src "$WORKSPACE/logs"
# add minimal smoke test if missing
if [ ! -f src/smoke.test.js ]; then
  cat > src/smoke.test.js <<'TEST'
test('smoke', () => { expect(1+1).toBe(2); });
TEST
fi
# run tests in CI mode non-interactively, capture logs and exit code
export CI=true
npm test --silent -- --watchAll=false --runInBand --passWithNoTests >"$WORKSPACE/logs/test-01.log" 2>&1 || { echo "tests: fail" | tee -a "$WORKSPACE/.setup_logs"; exit 11; }
# on success record outcome
echo "tests: pass" | tee -a "$WORKSPACE/.setup_logs" >/dev/null
