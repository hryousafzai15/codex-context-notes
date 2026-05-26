#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CodexContextNotes"
BUNDLE_ID="${CODEX_CONTEXT_NOTES_BUNDLE_ID:-com.hussainrehman.CodexContextNotes}"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
VERSION_FILE="$ROOT_DIR/VERSION"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -f "$ROOT_DIR/.*/$APP_NAME.app/Contents/MacOS/$APP_NAME" >/dev/null 2>&1 || true
pkill -f "$ROOT_DIR/.build/.*/$APP_NAME" >/dev/null 2>&1 || true

APP_VERSION="${CODEX_CONTEXT_NOTES_VERSION:-}"
if [[ -z "$APP_VERSION" && -f "$VERSION_FILE" ]]; then
  APP_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${CODEX_CONTEXT_NOTES_BUILD:-$(date -u +%Y%m%d%H%M)}"

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
find "$DIST_DIR" -maxdepth 1 -type d \( -name "$APP_NAME*.app" -o -name "Codex Context Notes*.app" \) ! -name "$APP_NAME.app" -exec rm -rf {} +
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Codex Context Notes</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Bundling $APP_NAME $APP_VERSION ($APP_BUILD)"

find_signing_identity() {
  if [[ -n "${CODEX_CONTEXT_NOTES_CODESIGN_IDENTITY:-}" ]]; then
    printf '%s\n' "$CODEX_CONTEXT_NOTES_CODESIGN_IDENTITY"
    return 0
  fi

  security find-identity -v -p codesigning 2>/dev/null \
    | awk -F '"' '/"[^"]+"/ { print $2; exit }'
}

sign_app() {
  if ! command -v codesign >/dev/null 2>&1; then
    echo "codesign not found; leaving app unsigned." >&2
    return 0
  fi

  local identity
  identity="$(find_signing_identity)"

  if [[ -n "$identity" ]]; then
    echo "Signing $APP_NAME.app with: $identity"
    codesign --force --sign "$identity" "$APP_BUNDLE"
  else
    echo "No stable code-signing identity found; falling back to ad-hoc signing." >&2
    echo "Accessibility permission may need to be re-granted after each rebuild." >&2
    codesign --force --sign - "$APP_BUNDLE"
  fi
}

sign_app

open_app() {
  /usr/bin/open "$APP_BUNDLE" --args "$@"
}

case "$MODE" in
  run)
    open_app
    ;;
  --panel|panel)
    open_app --open-panel
    ;;
  --settings|settings)
    open_app --open-settings
    ;;
  --shortcut-test|shortcut-test)
    open_app --shortcut-self-test
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|panel|settings|shortcut-test|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
