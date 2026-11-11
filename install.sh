#!/bin/sh
# yt-tui installer for Linux and macOS. No questions asked: it installs what is
# missing, puts yt-tui on your PATH and, on macOS, adds yt-tui.app to Launchpad.
#   curl -fsSL https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.sh | sh
#   ./install.sh               install from a clone
#   ./install.sh --uninstall   remove yt-tui (leaves yt-dlp and ffmpeg alone)
# PREFIX changes where the script goes (default ~/.local, so ~/.local/bin/yt-tui).
set -eu

RAW="https://raw.githubusercontent.com/YajatGhule/yt-tui/main"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
APP="$HOME/Applications/yt-tui.app"
MARK="# added by yt-tui installer"
OS=$(uname -s)
LOG="${TMPDIR:-/tmp}/yt-tui-install.log"
: > "$LOG"

if [ -t 1 ]; then R='\033[1;31m' G='\033[1;32m' Y='\033[1;33m' D='\033[2m' N='\033[0m'
else R='' G='' Y='' D='' N=''; fi
ok()   { printf "  ${G}✓${N} %s\n" "$*"; }
note() { printf "  ${Y}!${N} %s\n" "$*"; }
die()  { printf "  ${R}✗${N} %s\n" "$*"; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }
run()  { "$@" >>"$LOG" 2>&1; }
tl()   { case "$1" in "$HOME"/*) echo "~${1#"$HOME"}" ;; *) echo "$1" ;; esac; }
fetch() { if has curl; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi; }

shell_rc() {
    case "$(basename "${SHELL:-sh}")" in
        zsh) echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash) if [ "$OS" = Darwin ]; then echo "$HOME/.bash_profile"; else echo "$HOME/.bashrc"; fi ;;
        fish) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/yt-tui.fish" ;;
        *) echo "$HOME/.profile" ;;
    esac
}

if [ "${1:-}" = "--uninstall" ]; then
    printf "\n${R}▶ yt-tui${N} uninstall\n\n"
    rm -f "$BIN/yt-tui" && ok "Removed $(tl "$BIN")/yt-tui"
    if [ -d "$APP" ]; then rm -rf "$APP" && ok "Removed ~/Applications/yt-tui.app"; fi
    rc=$(shell_rc)
    if [ -f "$rc" ] && grep -q "$MARK" "$rc"; then
        { grep -v "$MARK" "$rc" || true; } > "$rc.yt-tui"
        mv "$rc.yt-tui" "$rc" && ok "Removed PATH line from $(tl "$rc")"
    fi
    echo; exit 0
fi

printf "\n${R}▶ yt-tui${N} installer ${D}(%s)${N}\n\n" "$OS"
has curl || has wget || die "Needs curl or wget"

# ── Python with curses ──────────────────────────────────────────────────────
# On a Mac without the Command Line Tools, /usr/bin/python3 is only a stub.
if [ "$OS" = Darwin ] && ! xcode-select -p >/dev/null 2>&1 && ! has brew; then
    xcode-select --install >/dev/null 2>&1 || true
    die "macOS needs its Command Line Tools first. Finish the install window that just opened, then run this again."
fi
if ! has python3 && has brew; then run brew install -q python || true; fi
has python3 || die "Python 3 not found, install it and run this again"
python3 -c 'import curses' 2>/dev/null || die "This Python has no curses module"
ok "Python $(python3 -c 'import platform; print(platform.python_version())')"

# ── yt-dlp and ffmpeg ───────────────────────────────────────────────────────
missing=""
has yt-dlp || missing="yt-dlp"
has ffmpeg || missing="$missing ffmpeg"
if [ -n "$missing" ]; then
    printf "  ${D}…${N} Installing%s\n" "$(echo " $missing" | tr -s ' ')"
    sudo=""; [ "$(id -u)" = 0 ] || sudo="sudo"
    # shellcheck disable=SC2086
    if has brew; then HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 run brew install -q $missing
    elif has pacman; then run $sudo pacman -S --needed --noconfirm $missing
    elif has apt-get; then run $sudo apt-get install -y $missing
    elif has dnf; then run $sudo dnf install -y $missing
    elif has zypper; then run $sudo zypper -n install $missing
    fi || true
    mkdir -p "$BIN"
    if ! has yt-dlp && ! [ -x "$BIN/yt-dlp" ]; then
        # Fall back to the official single-file release, which only needs Python.
        fetch "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" "$BIN/yt-dlp" \
            && chmod 755 "$BIN/yt-dlp" || true
    fi
fi
if has yt-dlp || [ -x "$BIN/yt-dlp" ]; then ok "yt-dlp"; else die "Could not install yt-dlp (details in $LOG)"; fi
if has ffmpeg; then ok "ffmpeg"
elif [ "$OS" = Darwin ]; then note "ffmpeg missing: install Homebrew from brew.sh, then run this again"
else note "ffmpeg missing: install it with your package manager (needed for merging and audio)"
fi

# ── yt-tui itself ───────────────────────────────────────────────────────────
mkdir -p "$BIN"
src=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$src" ] && [ -f "$src/yt-tui" ] && [ -f "$src/install.sh" ]; then
    cp "$src/yt-tui" "$BIN/yt-tui"
else
    src=""
    fetch "$RAW/yt-tui" "$BIN/yt-tui" || die "Download failed"
fi
chmod 755 "$BIN/yt-tui"
ok "yt-tui → $(tl "$BIN")/yt-tui"

# ── macOS: yt-tui.app so it opens from Launchpad and Spotlight ──────────────
if [ "$OS" = Darwin ]; then
    rm -rf "$APP"
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
    cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>yt-tui</string>
    <key>CFBundleDisplayName</key><string>yt-tui</string>
    <key>CFBundleIdentifier</key><string>io.github.yajatghule.yt-tui</string>
    <key>CFBundleExecutable</key><string>yt-tui</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF
    # Terminal runs the .command file. PATH covers Homebrew on Intel and Apple Silicon.
    cat > "$APP/Contents/Resources/yt-tui.command" <<EOF
#!/bin/sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$BIN:\$PATH"
printf '\033]0;yt-tui\007'; clear
exec "$BIN/yt-tui"
EOF
    cat > "$APP/Contents/MacOS/yt-tui" <<'EOF'
#!/bin/sh
exec open -a Terminal "$(dirname "$0")/../Resources/yt-tui.command"
EOF
    chmod 755 "$APP/Contents/MacOS/yt-tui" "$APP/Contents/Resources/yt-tui.command"

    icon="$APP/Contents/Resources/icon.png"
    if [ -n "$src" ] && [ -f "$src/assets/icon.png" ]; then cp "$src/assets/icon.png" "$icon"
    else fetch "$RAW/assets/icon.png" "$icon" || true; fi
    if [ -f "$icon" ] && has sips && has iconutil; then
        set_dir="${TMPDIR:-/tmp}/yt-tui.iconset"; rm -rf "$set_dir"; mkdir -p "$set_dir"
        for s in 16 32 128 256 512; do
            run sips -z $s $s "$icon" --out "$set_dir/icon_${s}x${s}.png" || true
            run sips -z $((s * 2)) $((s * 2)) "$icon" --out "$set_dir/icon_${s}x${s}@2x.png" || true
        done
        run iconutil -c icns "$set_dir" -o "$APP/Contents/Resources/AppIcon.icns" || true
        rm -rf "$set_dir"
    fi
    rm -f "$icon"
    lsreg=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
    if [ -x "$lsreg" ]; then run "$lsreg" -f "$APP" || true; fi
    ok "yt-tui.app → ~/Applications (Launchpad and Spotlight)"
fi

# ── PATH ────────────────────────────────────────────────────────────────────
case ":$PATH:" in
    *":$BIN:"*) ;;
    *)
        rc=$(shell_rc)
        if ! { [ -f "$rc" ] && grep -q "$MARK" "$rc"; }; then
            mkdir -p "$(dirname "$rc")"
            case "$rc" in
                *.fish) echo "fish_add_path \"$BIN\" $MARK" >> "$rc" ;;
                *) echo "export PATH=\"$BIN:\$PATH\" $MARK" >> "$rc" ;;
            esac
        fi
        ok "Added $(tl "$BIN") to PATH in $(tl "$rc") (new terminals)"
        ;;
esac

printf "\n  Run ${R}yt-tui${N}"
if [ "$OS" = Darwin ]; then printf " or open it from Launchpad"; fi
printf "\n\n"
