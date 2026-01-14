#!/usr/bin/env node
/**
 * Convert an exported LanguageCrush lesson HTML (in ./exports) into a normalized lesson JSON for the iOS app bundle.
 *
 * Usage:
 *   node scripts/convert.js lesson3
 *
 * This script expects:
 *   exports/<key>.html
 *
 * It will write:
 *   ios/tagalog-lite/raw/normalized/<key>.json
 */
const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const EXPORTS_DIR = path.join(ROOT, "exports");
const NORMALIZED_DIR = path.join(
  ROOT,
  "ios",
  "tagalog-lite",
  "raw",
  "normalized"
);

function slugify(input) {
  const s = String(input ?? "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "") // remove diacritics
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+/, "")
    .replace(/-+$/, "");
  return s.length ? s : "lesson";
}

function decodeHtmlEntities(s) {
  return String(s ?? "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'");
}

function stripHtml(html) {
  const s = String(html ?? "")
    .replace(/<\s*br\s*\/?>/gi, "\n")
    .replace(/<\/\s*p\s*>/gi, "\n")
    .replace(/<[^>]*>/g, "");
  return decodeHtmlEntities(s).replace(/\u00a0/g, " ");
}

function cleanText(s) {
  return String(s ?? "")
    .replace(/\r/g, "")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/[ \t]{2,}/g, " ")
    .trim();
}

function stripLeadingTagalogPrefixes(s) {
  let out = cleanText(s);
  out = out.replace(/^\*\s*/, "");
  out = out.replace(/^(ex|ans)\s*:\s*/i, "");
  return cleanText(out);
}

function stripLeadingEnglishPrefixes(s) {
  let out = cleanText(s);
  out = out.replace(/^=\s*/, "");
  return cleanText(out);
}

function normalizeMarkdownSpacing(s) {
  let out = String(s ?? "");
  out = out.replace(/(\S)_(\s+)([^_]+?)_/g, "$1$2_$3_");
  out = out.replace(/(\S)\*\*(\s+)([^*]+?)\*\*/g, "$1$2**$3**");
  return out;
}

function draftTextToMarkdown(text, inlineStyleRanges) {
  const t = String(text ?? "");
  const ranges = Array.isArray(inlineStyleRanges) ? inlineStyleRanges : [];
  const len = t.length;

  /** @type {Array<{start:number,end:number,style:"BOLD"|"ITALIC"|"UNDERLINE"}>} */
  const normalized = [];
  for (const r of ranges) {
    const start = Number(r?.offset ?? 0);
    const end = start + Number(r?.length ?? 0);
    const style = String(r?.style ?? "");
    if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start)
      continue;
    if (start < 0 || start >= len) continue;
    const clampedEnd = Math.min(end, len);
    if (style !== "BOLD" && style !== "ITALIC" && style !== "UNDERLINE")
      continue;
    normalized.push({ start, end: clampedEnd, style });
  }

  if (normalized.length === 0) return cleanText(t);

  const boundaries = new Set([0, len]);
  for (const r of normalized) {
    boundaries.add(r.start);
    boundaries.add(r.end);
  }
  const points = Array.from(boundaries).sort((a, b) => a - b);

  const openOrder = ["UNDERLINE", "BOLD", "ITALIC"];
  const closeOrder = ["ITALIC", "BOLD", "UNDERLINE"];

  const openToken = (style) => {
    if (style === "BOLD") return "**";
    if (style === "ITALIC") return "_";
    if (style === "UNDERLINE") return "<u>";
    return "";
  };
  const closeToken = (style) => {
    if (style === "BOLD") return "**";
    if (style === "ITALIC") return "_";
    if (style === "UNDERLINE") return "</u>";
    return "";
  };

  /** @type {Set<string>} */
  let active = new Set();
  let out = "";

  for (let i = 0; i < points.length - 1; i++) {
    const a = points[i];
    const b = points[i + 1];
    if (b <= a) continue;
    const segmentText = t.slice(a, b);
    if (!segmentText) continue;

    /** @type {Set<string>} */
    const nextActive = new Set();
    for (const r of normalized) {
      if (r.start <= a && a < r.end) nextActive.add(r.style);
    }

    for (const style of closeOrder) {
      if (active.has(style) && !nextActive.has(style)) out += closeToken(style);
    }
    for (const style of openOrder) {
      if (!active.has(style) && nextActive.has(style)) out += openToken(style);
    }

    out += segmentText;
    active = nextActive;
  }

  for (const style of closeOrder) {
    if (active.has(style)) out += closeToken(style);
  }

  return cleanText(normalizeMarkdownSpacing(out));
}

function guessTitleFromHtml(htmlText) {
  const m = htmlText.match(
    /<h1[^>]*class="[^"]*\bpx-4\b[^"]*"[^>]*>([^<]+)<\/h1>/i
  );
  if (m?.[1]) return cleanText(decodeHtmlEntities(m[1]));
  return null;
}

function draftBlockTypeToSchemaTextType(draftType) {
  switch (draftType) {
    case "header-one":
      return "h1";
    case "header-two":
      return "h2";
    case "header-three":
      return "h3";
    case "header-four":
    case "header-five":
    case "header-six":
      return "h3";
    case "unstyled":
    default:
      return "p";
  }
}

function entityToBilingualItem(entity, audioPath) {
  const entityType = String(entity?.type ?? "");
  const qRaw = cleanText(stripHtml(entity?.data?.question ?? ""));
  const aRaw = cleanText(stripHtml(entity?.data?.answer ?? ""));

  // EXAMPLE: question=Tagalog, answer=English
  // QUESTION: question=English, answer=Tagalog
  const tagalogRaw = entityType === "QUESTION" ? aRaw : qRaw;
  const englishRaw = entityType === "QUESTION" ? qRaw : aRaw;

  const tagalog = stripLeadingTagalogPrefixes(tagalogRaw);
  const english = stripLeadingEnglishPrefixes(englishRaw);

  // Only treat leading '*' as "optional"; everything else is handled by caller rules.
  const required = !tagalogRaw.trimStart().startsWith("*");

  return {
    tagalog: tagalog || "(missing)",
    english: english || "(missing)",
    required,
    audioPath: audioPath ?? null,
  };
}

function decodeJsStringLiteralAt(text, startQuoteIdx) {
  const quote = text[startQuoteIdx];
  if (quote !== '"' && quote !== "'") {
    throw new Error("Expected string literal quote at start index.");
  }

  let i = startQuoteIdx + 1;
  let out = "";
  while (i < text.length) {
    const ch = text[i];
    if (ch === quote) return { value: out, endIdx: i + 1 };
    if (ch !== "\\") {
      out += ch;
      i++;
      continue;
    }

    // escape
    i++;
    if (i >= text.length) break;
    const e = text[i++];
    if (e === "n") out += "\n";
    else if (e === "r") out += "\r";
    else if (e === "t") out += "\t";
    else if (e === "b") out += "\b";
    else if (e === "f") out += "\f";
    else if (e === "v") out += "\v";
    else if (e === "0") out += "\0";
    else if (e === "\\") out += "\\";
    else if (e === quote) out += quote;
    else if (e === "x") {
      const hex = text.slice(i, i + 2);
      if (!/^[0-9a-fA-F]{2}$/.test(hex)) throw new Error("Bad \\x escape");
      out += String.fromCharCode(parseInt(hex, 16));
      i += 2;
    } else if (e === "u") {
      if (text[i] === "{") {
        const close = text.indexOf("}", i + 1);
        if (close === -1) throw new Error("Bad \\u{...} escape");
        const hex = text.slice(i + 1, close);
        if (!/^[0-9a-fA-F]+$/.test(hex)) throw new Error("Bad \\u{...} escape");
        out += String.fromCodePoint(parseInt(hex, 16));
        i = close + 1;
      } else {
        const hex = text.slice(i, i + 4);
        if (!/^[0-9a-fA-F]{4}$/.test(hex)) throw new Error("Bad \\u escape");
        out += String.fromCharCode(parseInt(hex, 16));
        i += 4;
      }
    } else {
      // unknown escape, keep literal
      out += e;
    }
  }
  throw new Error("Unterminated string literal while parsing bodyRaw.");
}

function extractBodyRawFromHtml(htmlText) {
  // Look for: "bodyRaw": "...."
  const key = '"bodyRaw"';
  let idx = 0;
  while (true) {
    const found = htmlText.indexOf(key, idx);
    if (found === -1) break;
    let i = found + key.length;
    while (i < htmlText.length && /\s/.test(htmlText[i])) i++;
    if (htmlText[i] !== ":") {
      idx = found + 1;
      continue;
    }
    i++;
    while (i < htmlText.length && /\s/.test(htmlText[i])) i++;
    const startQuote = htmlText[i];
    if (startQuote !== '"' && startQuote !== "'") {
      idx = found + 1;
      continue;
    }
    const { value } = decodeJsStringLiteralAt(htmlText, i);
    return value;
  }
  throw new Error('Could not find a "bodyRaw" string in the exported HTML.');
}

function normalizeRawContentState(raw, { id, title }) {
  const blocks = Array.isArray(raw?.blocks) ? raw.blocks : [];
  const entityMap =
    raw?.entityMap && typeof raw.entityMap === "object" ? raw.entityMap : {};

  /** @type {Set<string>} */
  const vocabSeen = new Set();
  /** @type {Set<string>} */
  const exampleSeen = new Set();

  const vocabulary = [];
  const contents = [];
  const exampleSentences = [];

  /** @type {"vocabulary"|"sample"|"drills"|null} */
  let suppressedSection = null;

  function sectionKindFromHeaderText(headerText) {
    const s = cleanText(headerText).toLowerCase();
    if (s === "vocabulary") return "vocabulary";
    if (s.startsWith("sample sentences") || s.startsWith("sample phrases"))
      return "sample";
    if (s.startsWith("drills")) return "drills";
    return null;
  }

  for (const block of blocks) {
    const type = block?.type;
    const text = cleanText(block?.text ?? "");

    if (typeof type === "string" && type.startsWith("header-")) {
      if (suppressedSection !== "sample") {
        suppressedSection = sectionKindFromHeaderText(text);
      }
      const isGrammarHeader = cleanText(text).toLowerCase() === "grammar";
      if (text && !suppressedSection && !isGrammarHeader) {
        contents.push({
          type: draftBlockTypeToSchemaTextType(type),
          markdown: draftTextToMarkdown(
            block?.text ?? "",
            block?.inlineStyleRanges
          ),
        });
      }
      continue;
    }

    if (type === "atomic") {
      const entityKey = block?.entityRanges?.[0]?.key;
      const entity = entityMap?.[String(entityKey)];
      const entityType = String(entity?.type ?? "");
      if (entityType !== "EXAMPLE" && entityType !== "QUESTION") continue;

      // blobKey only (no audio fetching in-app yet)
      const audioPath = entity?.data?.blobKey
        ? String(entity.data.blobKey)
        : null;
      const baseItem = entityToBilingualItem(entity, audioPath);

      if (suppressedSection === "vocabulary") {
        if (entityType !== "EXAMPLE") continue;
        const item = baseItem; // preserve optional marker -> required=false
        const dedupeKey = `${item.tagalog}|||${item.english}`;
        if (!vocabSeen.has(dedupeKey)) {
          vocabSeen.add(dedupeKey);
          vocabulary.push(item);
        }
        continue;
      }

      if (suppressedSection === "sample") {
        const item = { ...baseItem, required: true };
        const exampleKey = `${item.tagalog}|||${item.english}`;
        if (!exampleSeen.has(exampleKey)) {
          exampleSeen.add(exampleKey);
          exampleSentences.push(item);
        }
        continue;
      }

      if (suppressedSection === "drills") continue;

      // Normal in-lesson sentence block: always required.
      const item = { ...baseItem, required: true };
      contents.push({ type: "sentence", item });
      continue;
    }

    // Treat most remaining blocks as text paragraphs; skip empty spacers.
    if (!text) continue;
    if (suppressedSection) continue;

    contents.push({
      type: draftBlockTypeToSchemaTextType(type),
      markdown: draftTextToMarkdown(
        block?.text ?? "",
        block?.inlineStyleRanges
      ),
    });
  }

  return {
    schemaVersion: 1,
    id,
    title,
    vocabulary,
    contents,
    exampleSentences,
  };
}

function main() {
  const args = process.argv.slice(2);
  if (args.length !== 1) {
    console.error(
      'Usage: node scripts/convert.js <key>   (example: "lesson3")'
    );
    process.exit(2);
  }

  const key = args[0];
  const htmlPath = path.join(EXPORTS_DIR, `${key}.html`);
  if (!fs.existsSync(htmlPath)) {
    throw new Error(`Missing input HTML: ${htmlPath}`);
  }

  const htmlText = fs.readFileSync(htmlPath, "utf8");
  const title = guessTitleFromHtml(htmlText) || key;
  const id = key; // stable and easy to route on iOS

  const bodyRawString = extractBodyRawFromHtml(htmlText);
  const raw = JSON.parse(bodyRawString);

  const normalized = normalizeRawContentState(raw, { id, title });

  fs.mkdirSync(NORMALIZED_DIR, { recursive: true });
  const outPath = path.join(NORMALIZED_DIR, `${key}.json`);
  fs.writeFileSync(outPath, JSON.stringify(normalized, null, 2) + "\n", "utf8");

  console.log(
    JSON.stringify(
      {
        input: path.relative(ROOT, htmlPath),
        output: path.relative(ROOT, outPath),
        id: normalized.id,
        title: normalized.title,
        vocabularyCount: normalized.vocabulary.length,
        contentsCount: normalized.contents.length,
        exampleSentencesCount: normalized.exampleSentences.length,
      },
      null,
      2
    )
  );
}

main();
