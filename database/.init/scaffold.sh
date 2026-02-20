#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/food-delivery-app-frontend-225148-225187/database"
APP_DIR="$WORKSPACE/app"
cd "$WORKSPACE"
# exit if project already exists (do not overwrite)
if [ -f "$APP_DIR/package.json" ]; then
  exit 0
fi
# choose framework default=react; prefer repo hints in workspace/package.json
FRAMEWORK=react
if [ -f package.json ]; then
  # presence of root package.json suggests React frontend (conservative default)
  FRAMEWORK=react
fi
mkdir -p "$APP_DIR"
if [ "$FRAMEWORK" = "react" ]; then
  if command -v create-react-app >/dev/null 2>&1; then
    env BROWSER=none CI=true create-react-app "$APP_DIR" --use-npm --silent >/dev/null 2>&1
  else
    env BROWSER=none CI=true npx --yes create-react-app "$APP_DIR" --use-npm --silent >/dev/null 2>&1
  fi
elif [ "$FRAMEWORK" = "vue" ]; then
  # @vue/cli is preinstalled per image summary
  vue create --default "$APP_DIR" --quiet >/dev/null 2>&1
else
  # angular
  ng new "$APP_DIR" --defaults --skip-install --quiet >/dev/null 2>&1
fi
cd "$APP_DIR"
[ -f package.json ] || { echo "package.json missing after scaffold" >&2; exit 6; }
# Add firebase SDK via package manager so lockfiles update atomically
FIRE_VER_DESIRED="^10.0.0"
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  yarn add --exact "firebase@${FIRE_VER_DESIRED}" --silent >/dev/null 2>&1 || (echo "yarn add failed" >&2; exit 7)
else
  npm i --save-exact "firebase@${FIRE_VER_DESIRED}" --silent >/dev/null 2>&1 || (echo "npm install failed" >&2; exit 8)
fi
# ensure emulators script exists without overwriting scripts
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{}; if(!p.scripts.emulators) p.scripts.emulators='firebase emulators:start --only auth,firestore,hosting'; fs.writeFileSync('package.json',JSON.stringify(p,null,2));" >/dev/null 2>&1
# create minimal env and firebase config if missing
if [ ! -f .env ]; then
  cat > .env <<ENV
REACT_APP_FIREBASE_PROJECT_ID=firebase-emulator-project
REACT_APP_FIREBASE_API_KEY=demo-key
REACT_APP_FIRESTORE_EMULATOR_HOST=localhost:8080
REACT_APP_AUTH_EMULATOR_HOST=localhost:9099
ENV
fi
if [ ! -f firebase.json ]; then
  cat > firebase.json <<FJ
{
  "emulators": {"auth": {"port": 9099}, "firestore": {"port": 8080}, "hosting": {"port": 5000}},
  "hosting": {"public":"build","ignore":["firebase.json","**/.*","**/node_modules/**"]},
  "firestore": {"rules":"firestore.rules"}
}
FJ
fi
if [ ! -f firestore.rules ]; then
  cat > firestore.rules <<'RULES'
service cloud.firestore {
  match /databases/{database}/documents { match /{document=**} { allow read, write: if true; } }
}
RULES
fi
