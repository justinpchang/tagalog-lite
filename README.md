# tagalog-lite-ios

This repo is an early prototype for turning **LanguageCrush Tagalog Lite** lesson exports into a consistent, iOS-friendly JSON format, plus a tiny browser viewer to sanity-check the output.

## What you have

- **Raw exports**: `exports/*.html` (downloaded lesson pages)
- **Schema**: `lesson.schema.json` (normalized format)
- **Converter**: `scripts/convert.js` (extracts `bodyRaw` from the HTML and normalizes it)
- **Normalized output**: `normalized/*.json`
- **Viewer**: `web/` (renders a normalized JSON in the browser)

## Convert an exported lesson

Put a lesson HTML export into `exports/` as:

- `exports/lesson3.html` (example)

Then run:

```bash
node scripts/convert.js lesson3
```

Output:

- `normalized/lesson3.json`

## View in the browser

Start a tiny static server:

```bash
node scripts/serve.js
```

Open:

- `http://localhost:5173/web/`
- or load a specific file: `http://localhost:5173/web/?file=normalized/lesson3.json`

## Note: audio files

- **Download audio**: `node scripts/download-audio.js` (scans `normalized/*.json` and downloads blobs into `audio/`)
- **Playback in viewer**: the viewer looks for `audio/<blobKey>.m4a`, then `.mp3`, then `.mp4`
- **Git**: audio media files under `audio/` are ignored via `.gitignore`
