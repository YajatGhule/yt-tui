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

- Python 3 (standard library only)
- `yt-dlp` and `ffmpeg` on your PATH

## Install

```sh
install -Dm755 yt-tui ~/.local/bin/yt-tui
```

## Usage

```sh
yt-tui                 # asks for a URL
yt-tui 'https://www.youtube.com/watch?v=...'
```
