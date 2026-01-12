#!/usr/bin/env node
/**
 * Download all audio blobs referenced by normalized lessons.
 *
 * Scans:   ./ios/tagalog-lite/raw/normalized/*.json
 * Writes:  ./ios/tagalog-lite/raw/audio/<blobKey>.(m4a|mp3|mp4)
 *
 * Usage:
 *   node scripts/download-audio.js
 *
 * Notes:
 * - We intentionally download from the `blobs_direct` endpoint (no auth) per your permission.
 * - The remote URL ends in `audio.mp3`, but the content is often an M4A/MP4 container.
 *   We sniff the bytes and save with the correct extension so iOS can play it reliably.
 */

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const RAW_DIR = path.join(ROOT, "ios", "tagalog-lite", "raw");
const NORMALIZED_DIR = path.join(RAW_DIR, "normalized");
const AUDIO_DIR = path.join(RAW_DIR, "audio");
const MANIFEST_PATH = path.join(AUDIO_DIR, "manifest.json");

const BLOB_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function listNormalizedFiles() {
  if (!fs.existsSync(NORMALIZED_DIR)) return [];
  return fs
    .readdirSync(NORMALIZED_DIR)
    .filter((f) => f.toLowerCase().endsWith(".json"))
    .map((f) => path.join(NORMALIZED_DIR, f));
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function collectBlobKeysFromLesson(lesson) {
  /** @type {Set<string>} */
  const keys = new Set();

  const maybeAdd = (v) => {
    if (typeof v !== "string") return;
    const s = v.trim();
    if (!s) return;
    if (!BLOB_RE.test(s)) return;
    keys.add(s);
  };

  for (const v of lesson?.vocabulary ?? []) maybeAdd(v?.audioPath);

  for (const b of lesson?.contents ?? []) {
    if (b?.type === "sentence") maybeAdd(b?.item?.audioPath);
  }

  for (const s of lesson?.exampleSentences ?? []) maybeAdd(s?.audioPath);

  return keys;
}

function buildBlobUrl(blobKey) {
  return `https://languagecrush.com/api/blobs_direct/book/${blobKey}/ORIGINAL/audio.mp3`;
}

async function downloadToFile(url, outPath) {
  const res = await fetch(url, { redirect: "follow" });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(outPath, buf);
  return buf.length;
}

function sniffAudioExtensionFromBuffer(buf) {
  if (!Buffer.isBuffer(buf) || buf.length < 12) return null;

  // MP4/M4A: [size][ftyp][brand...]
  if (buf.slice(4, 8).toString("ascii") === "ftyp") {
    const brand = buf.slice(8, 12).toString("ascii");
    if (brand === "M4A ") return "m4a";
    // Common MP4 brands: isom, mp42, MSNV, etc.
    return "mp4";
  }

  // MP3: starts with "ID3" or frame sync 0xFFE?
  if (buf.slice(0, 3).toString("ascii") === "ID3") return "mp3";
  if (buf[0] === 0xff && (buf[1] & 0xe0) === 0xe0) return "mp3";

  return null;
}

function sniffAudioExtensionFromFile(filePath) {
  try {
    const fd = fs.openSync(filePath, "r");
    try {
      const buf = Buffer.alloc(32);
      const read = fs.readSync(fd, buf, 0, buf.length, 0);
      return sniffAudioExtensionFromBuffer(buf.slice(0, read));
    } finally {
      fs.closeSync(fd);
    }
  } catch {
    return null;
  }
}

function getExistingAudioPath(blobKey) {
  const exts = ["m4a", "mp3", "mp4"];
  for (const ext of exts) {
    const p = path.join(AUDIO_DIR, `${blobKey}.${ext}`);
    if (fs.existsSync(p) && fs.statSync(p).size > 0) return p;
  }
  return null;
}

async function main() {
  const normalizedFiles = listNormalizedFiles();
  if (normalizedFiles.length === 0) {
    console.error(`No normalized lesson JSON found in: ${NORMALIZED_DIR}`);
    process.exit(2);
  }

  fs.mkdirSync(AUDIO_DIR, { recursive: true });

  /** @type {Map<string, { sources: string[] }>} */
  const manifest = new Map();

  /** @type {Set<string>} */
  const allKeys = new Set();

  for (const filePath of normalizedFiles) {
    const lesson = readJson(filePath);
    const lessonKeys = collectBlobKeysFromLesson(lesson);
    for (const k of lessonKeys) {
      allKeys.add(k);
      const rel = path.relative(ROOT, filePath);
      const entry = manifest.get(k) || { sources: [] };
      if (!entry.sources.includes(rel)) entry.sources.push(rel);
      manifest.set(k, entry);
    }
  }

  const keys = Array.from(allKeys).sort();
  console.log(
    JSON.stringify(
      {
        normalizedFiles: normalizedFiles.length,
        uniqueBlobKeys: keys.length,
        audioDir: path.relative(ROOT, AUDIO_DIR),
      },
      null,
      2
    )
  );

  let downloaded = 0;
  let skipped = 0;
  let failed = 0;

  for (const blobKey of keys) {
    const existing = getExistingAudioPath(blobKey);
    if (existing) {
      // If the file is mislabeled (common: .mp3 that is actually M4A), rename it.
      const detected = sniffAudioExtensionFromFile(existing);
      const currentExt = path.extname(existing).slice(1).toLowerCase();
      if (detected && detected !== currentExt) {
        const renamed = path.join(AUDIO_DIR, `${blobKey}.${detected}`);
        if (!fs.existsSync(renamed)) {
          fs.renameSync(existing, renamed);
          console.log(`Renamed ${path.basename(existing)} -> ${path.basename(renamed)}`);
        } else {
          // If both exist, keep the correctly named one and delete the mislabeled one.
          fs.unlinkSync(existing);
        }
      }
      skipped++;
      continue;
    }

    const url = buildBlobUrl(blobKey);
    process.stdout.write(`Downloading ${blobKey}… `);
    try {
      // Download to a temp file first, sniff, then move to the correct extension.
      const tmpPath = path.join(AUDIO_DIR, `${blobKey}.download`);
      const bytes = await downloadToFile(url, tmpPath);
      const buf = fs.readFileSync(tmpPath);
      const ext = sniffAudioExtensionFromBuffer(buf) || "mp3";
      const outPath = path.join(AUDIO_DIR, `${blobKey}.${ext}`);
      fs.renameSync(tmpPath, outPath);
      downloaded++;
      process.stdout.write(`ok (${bytes} bytes)\n`);
    } catch (e) {
      failed++;
      process.stdout.write(
        `failed (${e instanceof Error ? e.message : String(e)})\n`
      );
      try {
        const tmpPath = path.join(AUDIO_DIR, `${blobKey}.download`);
        if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
      } catch {
        // ignore
      }
    }
  }

  const manifestObj = {};
  for (const [k, v] of manifest.entries()) manifestObj[k] = v;
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifestObj, null, 2) + "\n");

  console.log(
    JSON.stringify(
      {
        downloaded,
        skipped,
        failed,
        manifest: path.relative(ROOT, MANIFEST_PATH),
      },
      null,
      2
    )
  );

  if (failed > 0) process.exitCode = 1;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
