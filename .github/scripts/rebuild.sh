#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh for storybookjs/react-native
# Runs on an existing source tree (translated docs in current dir, no fresh clone).
# This is a pnpm monorepo: Docusaurus site lives in docs/ and depends on workspace root.
# Strategy: clone source repo to /tmp for workspace deps, overlay our translated files, build.

REPO_URL="https://github.com/storybookjs/react-native.git"
BRANCH="next"
TMP_DIR="/tmp/storybookjs-react-native-rebuild"

# --- Node 22 via n ---
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:/usr/local/bin:/usr/bin:/bin"

echo "=== Installing Node 22 via n ==="
n 22
node --version
npm --version

# --- pnpm 10.30.3 via corepack ---
echo "=== Enabling corepack ==="
corepack enable

echo "=== Installing pnpm 10.30.3 ==="
corepack prepare pnpm@10.30.3 --activate
pnpm --version

# --- Clone source for workspace dependencies ---
echo "=== Cloning source repo to $TMP_DIR for workspace deps ==="
rm -rf "$TMP_DIR"
git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

# --- Install workspace dependencies ---
echo "=== Installing workspace dependencies ==="
cd "$TMP_DIR"
pnpm install --frozen-lockfile

# --- Overlay our translated docs over the cloned source ---
# Current dir (OLDPWD) is the translated staging repo root (the docs/ content).
# Copy all our files into the cloned repo's docs/ directory.
echo "=== Overlaying translated content ==="
cp -r "$OLDPWD/." "$TMP_DIR/docs/"

# --- Build from docs directory ---
echo "=== Running docusaurus build ==="
cd "$TMP_DIR/docs"
pnpm run build

# --- Copy build output back ---
echo "=== Copying build output back ==="
cp -r "$TMP_DIR/docs/build" "$OLDPWD/build"

echo "=== Verifying build output ==="
if [ -d "$OLDPWD/build" ] && [ "$(ls -A "$OLDPWD/build")" ]; then
    echo "BUILD SUCCESS: build/ directory exists and contains files"
    ls "$OLDPWD/build" | head -10
else
    echo "BUILD FAILED: build/ directory missing or empty"
    exit 1
fi

echo "[DONE] Build complete."
