# tagalog-lite-ios

This repo is an early prototype for turning **LanguageCrush Tagalog Lite** lesson exports into a consistent, iOS-friendly JSON format, plus a tiny browser viewer to sanity-check the output.

## What you have

- **Raw exports**: `exports/*.html` (downloaded lesson pages)
- **Schema**: `lesson.schema.json` (normalized format)
- **Converter**: `scripts/convert.js` (extracts `bodyRaw` from the HTML and normalizes it)
- **Normalized output**: `ios/tagalog-lite/raw/normalized/*.json`
- **Viewer**: `web/` (renders a normalized JSON in the browser)

## Convert an exported lesson

Put a lesson HTML export into `exports/` as:

- `exports/lesson3.html` (example)

Then run:

```bash
node scripts/convert.js lesson3
```

Output:

- `ios/tagalog-lite/raw/normalized/lesson3.json`

## View in the browser

Start a tiny static server:

```bash
node scripts/serve.js
```

Open:

- `http://localhost:5173/web/`
- or load a specific file: `http://localhost:5173/web/?file=ios/tagalog-lite/raw/normalized/lesson3.json`

## Note: audio files

- **Download audio**: `node scripts/download-audio.js` (scans `ios/tagalog-lite/raw/normalized/*.json` and downloads blobs into `ios/tagalog-lite/raw/audio/`)
- **Playback in viewer**: the viewer looks for `ios/tagalog-lite/raw/audio/<blobKey>.m4a`, then `.mp3`, then `.mp4`
- **Audio format note**: even if the remote URL ends with `audio.mp3`, the bytes are often an M4A container; the downloader auto-detects and saves as `.m4a` so iOS can play it.
- **Git**: audio media files under `ios/tagalog-lite/raw/audio/` are ignored via `.gitignore`
