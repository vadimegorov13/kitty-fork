#!/bin/sh
#
# Install the kitty.app built by "python3 setup.py kitty.app" into /Applications
# along with a clickable "Kitty Quick Access" app that toggles the quick access
# terminal. Run this from Terminal.app, not from kitty, as it replaces kitty.
#
# Create only the clickable app, using the specified kitten:
#   ./install-macos.sh --launcher-only /path/to/Name.app /path/to/kitten [args for kitten...]

set -e

create_launcher() {
    app="$1"; kitten="$2"; shift 2
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$(dirname "$kitten")/../Resources/kitty.icns" "$app/Contents/Resources/"
    {
        echo '#!/bin/sh'
        echo 'cd "$HOME"'
        printf '"%s" quick-access-terminal' "$kitten"
        for arg in "$@"; do printf ' "%s"' "$arg"; done
        echo ' </dev/null >/dev/null 2>&1 &'
    } > "$app/Contents/MacOS/kitty-quick-access-launcher"
    chmod +x "$app/Contents/MacOS/kitty-quick-access-launcher"
    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleName</key><string>Kitty Quick Access</string>
    <key>CFBundleIdentifier</key><string>net.kovidgoyal.kitty-quick-access-launcher</string>
    <key>CFBundleExecutable</key><string>kitty-quick-access-launcher</string>
    <key>CFBundleIconFile</key><string>kitty.icns</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSUIElement</key><true/>
</dict></plist>
PLIST
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
}

if [ "$1" = "--launcher-only" ]; then
    shift
    create_launcher "$@"
    exit 0
fi

cd "$(dirname "$0")"
[ -x kitty.app/Contents/MacOS/kitty ] || { echo "kitty.app is not built" >&2; exit 1; }
if [ "$TERM" = "xterm-kitty" ]; then echo "Run this from Terminal.app, not from kitty" >&2; exit 1; fi

backup="$HOME/kitty-original-backup.app"
if [ -d /Applications/kitty.app ] && [ ! -e "$backup" ]; then
    echo "Backing up the current kitty to $backup"
    cp -R /Applications/kitty.app "$backup"
fi
pkill -x kitty-quick-access || true
pkill -x kitty || true
if brew list --cask kitty >/dev/null 2>&1; then brew uninstall --cask kitty; fi
rm -rf /Applications/kitty.app
cp -R kitty.app /Applications/kitty.app
codesign --force --deep --sign - /Applications/kitty.app
mkdir -p "$HOME/.local/bin"
ln -sf /Applications/kitty.app/Contents/MacOS/kitty "$HOME/.local/bin/kitty"
ln -sf /Applications/kitty.app/Contents/MacOS/kitten "$HOME/.local/bin/kitten"
create_launcher "/Applications/Kitty Quick Access.app" /Applications/kitty.app/Contents/MacOS/kitten
echo "Installed. Open Kitty Quick Access from /Applications or add it to VisorPro."
