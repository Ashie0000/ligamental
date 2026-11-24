#!/usr/bin/env bash
# build_mac.sh — one-shot build on macOS. Produces FragUnlock.dylib ready to
# drop into Sideloadly's "Advanced Options → Inject Dylib/Framework" slot.
#
# Requires: Xcode Command Line Tools (xcrun, clang, strip). No ldid, no
# optool, no theos. Sideloadly handles LC_LOAD_DYLIB insertion AND re-signing
# at install time, so nothing else is needed on the Mac side.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found — install Xcode CLT: xcode-select --install" >&2
  exit 1
fi

make clean >/dev/null 2>&1 || true
make

if [ ! -f FragUnlock.dylib ]; then
  echo "build failed — no FragUnlock.dylib produced" >&2
  exit 2
fi

OUT_DIR="$(pwd)/dist"
mkdir -p "$OUT_DIR"
cp FragUnlock.dylib "$OUT_DIR/FragUnlock.dylib"

echo ""
echo "================================================================"
echo "  FragUnlock.dylib built: $OUT_DIR/FragUnlock.dylib"
echo ""
echo "  Next steps in Sideloadly (Windows or macOS):"
echo "    1. Open Sideloadly."
echo "    2. Drag the original IPA onto the Sideloadly window:"
echo "         com.ohbibi.fps_v5.7.2_und3fined.ipa"
echo "    3. Click the 'Advanced Options' gear."
echo "    4. Under 'Inject Files', add:"
echo "         FragUnlock.dylib"
echo "    5. Pick your Apple ID (free or paid developer account)."
echo "    6. Plug in the iPhone/iPad, click Start."
echo ""
echo "  Free account note: app works 7 days before resign is needed."
echo "  Paid dev account: 1 year."
echo "  No jailbreak required."
echo "================================================================"
