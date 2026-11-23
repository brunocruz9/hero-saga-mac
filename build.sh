#!/bin/bash
# Monta "Hero Saga para Mac.app" (universal arm64 + x86_64) e o .dmg de distribuição.
# Pré-requisito: Command Line Tools da Apple (xcode-select --install).
set -euo pipefail
cd "$(dirname "$0")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)"
[ -d engine/wswine.bundle ] || tools/fetch-engine.sh engine
APP="build/Hero Saga para Mac.app"
rm -rf build; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for a in arm64 x86_64; do
  swiftc -O -parse-as-library -target $a-apple-macos13 Sources/*.swift -o build/bin-$a
done
lipo -create build/bin-arm64 build/bin-x86_64 -output "$APP/Contents/MacOS/HeroSagaMac"
rm build/bin-*
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns LICENSES.txt LGPL-2.1.txt "$APP/Contents/Resources/"
cp -a engine "$APP/Contents/Resources/engine"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"

# DMG
STAGE="build/dmg"; mkdir -p "$STAGE"
cp -a "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp docs/LEIA-ME.txt "$STAGE/LEIA-ME.txt"
DMG="build/HeroSagaParaMac-$VERSION.dmg"
hdiutil create -volname "Hero Saga para Mac" -srcfolder "$STAGE" -fs HFS+ -format ULFO -ov "$DMG" >/dev/null
rm -rf "$STAGE"
( cd build && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256" )
du -sh "$APP" "$DMG"; cat "$DMG.sha256"
