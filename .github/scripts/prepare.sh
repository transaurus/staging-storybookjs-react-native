#!/usr/bin/env bash
set -euo pipefail

# prepare.sh for storybookjs/react-native
# Docusaurus 3.9.2 with @docusaurus/faster (Rspack)
# Node >=22 required, pnpm 10.30.3

REPO_URL="https://github.com/storybookjs/react-native.git"
BRANCH="next"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    echo "=== Cloning $REPO_URL ==="
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
    echo "=== $REPO_DIR already exists, skipping clone ==="
fi

# --- Install dependencies from workspace root ---
echo "=== Installing dependencies from workspace root ==="
cd "$REPO_DIR"
pnpm install --frozen-lockfile

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
