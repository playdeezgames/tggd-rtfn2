#!/usr/bin/env bash
# Builds the web build and copies it to docs/ for GitHub Pages (served from main, /docs):
# https://playdeezgames.github.io/tggd-rtfn2/
# docs/ is generated and wiped on each run; the port's notes live in design/. Never commits or pushes.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf odin/out
./odin/build.sh
rm -f odin/out/*.pdb
rm -rf docs
mkdir docs
cp -r odin/out/. docs/
touch docs/.nojekyll
echo "docs/ ready: $(du -sh docs | cut -f1)"
