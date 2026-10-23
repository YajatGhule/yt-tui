#!/bin/sh
# yt-tui installer for Linux and macOS.
#   ./install.sh                      install from this checkout
#   curl -fsSL https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.sh | sh
# Set PREFIX to change the target (default: ~/.local, script goes to $PREFIX/bin).
set -eu

REPO_RAW="https://raw.githubusercontent.com/YajatGhule/yt-tui/main"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"

say() { printf '\033[1;31m▶\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

has python3 || { warn "python3 not found, install Python 3 first"; exit 1; }
python3 -c 'import curses' 2>/dev/null || { warn "your Python has no curses module"; exit 1; }

mkdir -p "$BIN"
here=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$here" ] && [ -f "$here/yt-tui" ]; then
    install -m 755 "$here/yt-tui" "$BIN/yt-tui"
else
    say "Downloading yt-tui"
    if has curl; then curl -fsSL "$REPO_RAW/yt-tui" -o "$BIN/yt-tui"
    elif has wget; then wget -qO "$BIN/yt-tui" "$REPO_RAW/yt-tui"
    else warn "need curl or wget to download"; exit 1
    fi
    chmod 755 "$BIN/yt-tui"
fi
say "Installed $BIN/yt-tui"

# Suggest how to get the runtime dependencies.
hint() {
    if has pacman; then echo "sudo pacman -S $1"
    elif has apt-get; then echo "sudo apt install $1"
    elif has dnf; then echo "sudo dnf install $1"
    elif has zypper; then echo "sudo zypper install $1"
    elif has brew; then echo "brew install $1"
    else echo "install $1 with your package manager"
    fi
}
if ! has yt-dlp; then
    if has pipx; then warn "yt-dlp not found: pipx install yt-dlp"
    else warn "yt-dlp not found: $(hint yt-dlp)"; fi
fi
has ffmpeg || warn "ffmpeg not found (needed for merging and audio): $(hint ffmpeg)"

case ":$PATH:" in
    *":$BIN:"*) say "Run: yt-tui [URL]" ;;
    *) warn "$BIN is not on your PATH. Add this to your shell profile:"
       echo "    export PATH=\"$BIN:\$PATH\"" ;;
esac
