#!/usr/bin/env node
/**
 * Proofread normalized lessons by fixing common invalid markdown artifacts
 * introduced by exports (especially emphasis markers with misplaced spaces).
 *
 * Specifically fixes patterns like:
 *   "_sino _in"   -> "_sino_ in"
 *   "_ang _form"  -> "_ang_ form"
 *   "**foo **bar" -> "**foo** bar"
 *   "*foo *bar"   -> "*foo* bar"
 *
 * Usage:
 *   node scripts/proofread-normalized.js --check
 *   node scripts/proofread-normalized.js --write
 *
 * Exit codes:
 *   --check: 0 if no changes needed, 1 if changes would be made
 *   --write: 0 (or 2 for usage / unexpected errors)
 */
const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const NORMALIZED_DIR = path.join(
  ROOT,
  "ios",
  "tagalog-lite",
  "raw",
  "normalized"
);

function letterNumberClass() {
  // Prefer Unicode properties when supported; fall back to ASCII-ish.
  try {
    // eslint-disable-next-line no-new
    new RegExp("[\\p{L}\\p{N}]", "u");
    return "[\\p{L}\\p{N}]";
  } catch {
    return "[A-Za-z0-9]";
  }
}

function isLetterOrNumber(ch) {
  // Unicode-aware letter/number test (Node supports \p{} with the 'u' flag)
  try {
    return /[\p{L}\p{N}]/u.test(ch);
  } catch {
    // Fallback (should be rare): ASCII-ish
    return /[A-Za-z0-9]/.test(ch);
  }
}

/**
 * Fixes "space before closing marker" emphasis artifacts.
 * Returns { out, fixes } where fixes is the number of replacements performed.
 */
function fixEmphasisArtifacts(input) {
  let out = String(input ?? "");
  let fixes = 0;
  const LN = letterNumberClass();

  /**
   * Generic fixer for markers with an opening token and a closing token.
   * Matches: OPEN (token) SPACE CLOSE (nextNonSpace)
   */
  function fixToken(open, close, innerPattern) {
    // Example for underscore:
    //   /_([^_\s]+)\s_([^\s])/gu
    const re = new RegExp(
      `${open}(${innerPattern})\\s${close}([^\\s])`,
      "gu"
    );
    out = out.replace(re, (_m, inner, next) => {
      fixes++;
      const sep = isLetterOrNumber(next) ? " " : "";
      return `${open}${inner}${close}${sep}${next}`;
    });

    // Also fix end-of-string: "_foo _" -> "_foo_"
    const reEnd = new RegExp(`${open}(${innerPattern})\\s${close}$`, "gu");
    out = out.replace(reEnd, (_m, inner) => {
      fixes++;
      return `${open}${inner}${close}`;
    });
  }

  // Order matters: fix bold before italics so "**x **y" isn't partially consumed.
  // Bold: prevent inner from containing '**' so we don't span across other bold segments.
  fixToken(
    "\\*\\*",
    "\\*\\*",
    `${LN}(?:(?!\\*\\*).)*?`
  );

  // Single '*' italics: avoid matching bold by requiring not-adjacent '*'
  // (Negative lookbehind/ahead are supported in modern Node.)
  out = out.replace(
    new RegExp(`(?<!\\*)\\*(${LN}[^*]*?)\\s\\*(?!\\*)([^\\s])`, "gu"),
    (_m, inner, next) => {
      fixes++;
      const sep = isLetterOrNumber(next) ? " " : "";
      return `*${inner}*${sep}${next}`;
    }
  );
  out = out.replace(
    new RegExp(`(?<!\\*)\\*(${LN}[^*]*?)\\s\\*(?!\\*)$`, "gu"),
    (_m, inner) => {
      fixes++;
      return `*${inner}*`;
    }
  );

  // Underscore italics: allow multi-word phrases but prevent inner from containing '_' so we
  // don't span across other underscore segments.
  fixToken("_", "_", `${LN}[^_]*?`);

  return { out, fixes };
}

function walkAndFixMarkdown(node, stats) {
  if (Array.isArray(node)) {
    for (const item of node) walkAndFixMarkdown(item, stats);
    return;
  }
  if (!node || typeof node !== "object") return;

  for (const [k, v] of Object.entries(node)) {
    if (k === "markdown" && typeof v === "string") {
      const { out, fixes } = fixEmphasisArtifacts(v);
      if (fixes > 0) {
        node[k] = out;
        stats.fixes += fixes;
      }
      continue;
    }
    walkAndFixMarkdown(v, stats);
  }
}

function main() {
  const args = new Set(process.argv.slice(2));
  const write = args.has("--write");
  const check = args.has("--check") || !write;

  if (args.has("--help") || args.has("-h")) {
    console.log(
      [
        "Usage:",
        "  node scripts/proofread-normalized.js --check",
        "  node scripts/proofread-normalized.js --write",
        "",
        "Defaults to --check if no flag is provided.",
      ].join("\n")
    );
    process.exit(0);
  }

  if (!fs.existsSync(NORMALIZED_DIR)) {
    console.error(`Missing directory: ${NORMALIZED_DIR}`);
    process.exit(2);
  }

  const files = fs
    .readdirSync(NORMALIZED_DIR)
    .filter((f) => f.endsWith(".json"))
    .sort((a, b) => a.localeCompare(b, "en"));

  let changedFiles = 0;
  let totalFixes = 0;

  for (const f of files) {
    const filePath = path.join(NORMALIZED_DIR, f);
    const raw = fs.readFileSync(filePath, "utf8");
    const json = JSON.parse(raw);

    const stats = { fixes: 0 };
    walkAndFixMarkdown(json, stats);

    if (stats.fixes > 0) {
      changedFiles++;
      totalFixes += stats.fixes;
      console.log(
        `${check && !write ? "Would fix" : "Fixed"} ${stats.fixes} in ${path.relative(
          ROOT,
          filePath
        )}`
      );
      if (write) {
        fs.writeFileSync(filePath, JSON.stringify(json, null, 2) + "\n", "utf8");
      }
    }
  }

  const summary = `${check && !write ? "Would fix" : "Fixed"} ${totalFixes} occurrence(s) across ${changedFiles} file(s) (${files.length} checked).`;
  console.log(summary);

  if (check && !write && changedFiles > 0) process.exit(1);
  process.exit(0);
}

main();

