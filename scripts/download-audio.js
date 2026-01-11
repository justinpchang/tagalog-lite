#!/usr/bin/env node
/**
 * Download all audio blobs referenced by normalized lessons.
 *
 * Scans:   ./normalized/*.json
 * Writes:  ./audio/<blobKey>.mp3
 *
 * Usage:
 *   node scripts/download-audio.js
 *
 * Notes:
 * - We intentionally download from the `blobs_direct` endpoint (no auth) per your permission.
 * - The remote URL ends in `audio.mp3`, but the content may be an M4A container; we still
 *   save the bytes as `.mp3` to match the fetched URL.
 */

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const NORMALIZED_DIR = path.join(ROOT, "normalized");
const AUDIO_DIR = path.join(ROOT, "audio");
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
    const outPath = path.join(AUDIO_DIR, `${blobKey}.mp3`);
    if (fs.existsSync(outPath) && fs.statSync(outPath).size > 0) {
      skipped++;
      continue;
    }

    const url = buildBlobUrl(blobKey);
    process.stdout.write(`Downloading ${blobKey}… `);
    try {
      const bytes = await downloadToFile(url, outPath);
      downloaded++;
      process.stdout.write(`ok (${bytes} bytes)\n`);
    } catch (e) {
      failed++;
      process.stdout.write(
        `failed (${e instanceof Error ? e.message : String(e)})\n`
      );
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
