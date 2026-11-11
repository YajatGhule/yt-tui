# yt-tui

A full-screen terminal UI around [yt-dlp](https://github.com/yt-dlp/yt-dlp).
Pick quality and file type with the arrow keys and Enter, then type where to save it.

## Features

- Quality list built from the video's real formats, with estimated size and codecs
- Video (mp4, mkv, webm) or audio (mp3, m4a, opus, flac, wav), with a bitrate menu for lossy audio
- Save path field with Tab completion and free-space check
- Live progress bar with speed, ETA, post-processing stages and playlist progress
- Playlists are saved into their own folder with numbered files
- Esc goes back a step, Esc during a download cancels it

## Requirements

- Python 3 (standard library only, plus `windows-curses` on Windows)
- `yt-dlp` and `ffmpeg` on your PATH

## Install

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.sh | sh
```

One command, no questions. It installs `yt-dlp` and `ffmpeg` if they are missing
(Homebrew, pacman, apt, dnf or zypper), puts yt-tui in `~/.local/bin` and adds that to your PATH.
On macOS it also adds **yt-tui.app** to `~/Applications`, so you can open it from Launchpad
or Spotlight.

Or from a clone: `./install.sh`. Set `PREFIX` to install somewhere else.
To remove it: `curl -fsSL https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.sh | sh -s -- --uninstall`

### Windows

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.ps1 | iex
```

Or from a clone: `powershell -ExecutionPolicy Bypass -File install.ps1`.
It installs `windows-curses`, gets `yt-dlp` and `ffmpeg` through winget if needed,
puts yt-tui in `%LOCALAPPDATA%\Programs\yt-tui` and adds it to your PATH.
Use Windows Terminal for the full colour theme.

## Usage

```sh
yt-tui                 # asks for a URL
yt-tui 'https://www.youtube.com/watch?v=...'
```
