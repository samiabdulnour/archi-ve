#!/usr/bin/env bash
#
# build-web.sh — copy the web app into ./www/ for Capacitor.
#
# Capacitor's iOS bundler reads webDir (set to "www" in capacitor.config.json)
# and copies that directory into the Xcode project on every `npx cap sync ios`.
# Our app lives in repo-root as plain HTML, so this script just stages a clean
# copy each time. Run it BEFORE `npx cap sync ios`.
#
# Usage:  bash scripts/build-web.sh
# Or via npm: npm run build:web

set -euo pipefail

# Walk up to the repo root so the script works no matter where it's invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

OUT="www"
rm -rf "$OUT"
mkdir -p "$OUT"

# Copy the web app's runtime files. Everything else (BUILD-IOS.md, APPSTORE.md,
# CLAUDE.md, scripts/, .gitignore, etc.) stays out — those are not shipped in
# the iOS bundle.
cp index.html             "$OUT/"
cp manifest.webmanifest   "$OUT/"
cp -R fonts               "$OUT/"
cp -R icons               "$OUT/"
cp -R vendor              "$OUT/"

echo "✓ wrote $(find "$OUT" -type f | wc -l | tr -d ' ') files into ./$OUT/"
