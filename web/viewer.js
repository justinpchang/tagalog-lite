function $(id) {
  const el = document.getElementById(id);
  if (!el) throw new Error(`Missing element #${id}`);
  return el;
}

function setStatus(text) {
  $("status").textContent = text;
}

function escapeHtml(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function renderInlineMarkdownToHtml(md) {
  // Minimal “safe enough” renderer for our normalized content:
  // - Escape all HTML
  // - Re-enable <u> tags produced by the converter
  // - Support **bold** and _italic_
  // This is not a full markdown implementation.
  let html = escapeHtml(md);

  // Re-enable underline tags (exact literal only)
  html = html.replace(/&lt;u&gt;/g, "<u>").replace(/&lt;\/u&gt;/g, "</u>");

  // Bold: **text**
  html = html.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");

  // Italic: _text_
  html = html.replace(/_([^_]+)_/g, "<em>$1</em>");

  return html;
}

function createPill(required) {
  const span = document.createElement("span");
  span.className = required ? "pill pill--required" : "pill";
  span.textContent = required ? "required" : "optional";
  return span;
}

function renderBilingualGrid(container, items) {
  container.innerHTML = "";
  for (const item of items) {
    const card = document.createElement("div");
    card.className = "card";

    const top = document.createElement("div");
    top.className = "card__top";

    const t = document.createElement("div");
    t.className = "tagalog";
    t.textContent = item.tagalog;

    const pill = createPill(Boolean(item.required));
    top.appendChild(t);
    top.appendChild(pill);

    const e = document.createElement("div");
    e.className = "english";
    e.textContent = item.english;

    card.appendChild(top);
    card.appendChild(e);

    container.appendChild(card);
  }
}

function renderContents(container, blocks) {
  container.innerHTML = "";
  for (const block of blocks) {
    if (block.type === "sentence") {
      const row = document.createElement("div");
      row.className = "sentenceRow";

      const left = document.createElement("div");
      left.className = "left";
      left.textContent = block.item.tagalog;

      const right = document.createElement("div");
      right.className = "right";
      right.textContent = block.item.english;

      row.appendChild(left);
      row.appendChild(right);
      container.appendChild(row);
      continue;
    }

    const tag = block.type === "p" ? "p" : block.type; // h1/h2/h3
    const el = document.createElement(tag);
    el.innerHTML = renderInlineMarkdownToHtml(block.markdown);
    container.appendChild(el);
  }
}

function validateRoughShape(lesson) {
  if (!lesson || typeof lesson !== "object") return "Lesson is not an object.";
  if (!lesson.title || typeof lesson.title !== "string") return "Missing title.";
  if (!Array.isArray(lesson.vocabulary)) return "Missing vocabulary array.";
  if (!Array.isArray(lesson.contents)) return "Missing contents array.";
  if (!Array.isArray(lesson.exampleSentences))
    return "Missing exampleSentences array.";
  return null;
}

function renderLesson(lesson) {
  const err = validateRoughShape(lesson);
  if (err) throw new Error(err);

  $("lessonTitle").textContent = lesson.title;

  renderBilingualGrid($("vocab"), lesson.vocabulary);
  renderContents($("contents"), lesson.contents);
  renderBilingualGrid($("examples"), lesson.exampleSentences);

  $("lesson").hidden = false;
  setStatus(
    `Loaded: ${lesson.title} (${lesson.vocabulary.length} vocab, ${lesson.contents.length} blocks, ${lesson.exampleSentences.length} sample sentences)`
  );
}

async function loadFromUrl(url) {
  setStatus(`Loading ${url}…`);
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Fetch failed: ${res.status} ${res.statusText}`);
  const lesson = await res.json();
  renderLesson(lesson);
}

function loadFromFile(file) {
  setStatus(`Reading ${file.name}…`);
  const reader = new FileReader();
  reader.onerror = () => setStatus("Failed to read file.");
  reader.onload = () => {
    try {
      const lesson = JSON.parse(String(reader.result ?? ""));
      renderLesson(lesson);
    } catch (e) {
      setStatus(`Invalid JSON: ${e instanceof Error ? e.message : String(e)}`);
    }
  };
  reader.readAsText(file);
}

function init() {
  $("fileInput").addEventListener("change", (e) => {
    const file = e.target?.files?.[0];
    if (file) loadFromFile(file);
  });

  $("loadDefaultBtn").addEventListener("click", () => {
    loadFromUrl("../normalized/lesson3.json").catch((e) => {
      setStatus(e instanceof Error ? e.message : String(e));
    });
  });

  const params = new URLSearchParams(window.location.search);
  const file = params.get("file");
  if (file) {
    loadFromUrl(`../${file.replace(/^\/+/, "")}`).catch((e) => {
      setStatus(e instanceof Error ? e.message : String(e));
    });
  }
}

init();


