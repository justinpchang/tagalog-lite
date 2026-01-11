#!/usr/bin/env node
/**
 * Tiny static server for local dev (no deps).
 *
 * Usage:
 *   node scripts/serve.js
 * Then open:
 *   http://localhost:5173/web/
 *   http://localhost:5173/web/?file=normalized/lesson3.json
 */
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const { URL } = require("node:url");

const ROOT = path.resolve(__dirname, "..");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".mp3": "audio/mpeg",
  ".m4a": "audio/mp4",
  ".mp4": "video/mp4",
};

function safeJoin(root, urlPath) {
  const decoded = decodeURIComponent(urlPath);
  const clean = decoded.replace(/^\/+/, "");
  const abs = path.resolve(root, clean);
  if (!abs.startsWith(root)) return null;
  return abs;
}

function send(res, status, headers, body) {
  res.writeHead(status, headers);
  res.end(body);
}

const server = http.createServer((req, res) => {
  try {
    const u = new URL(req.url || "/", "http://localhost");
    const pathname = u.pathname === "/" ? "/web/" : u.pathname;

    // Directory handling
    if (pathname.endsWith("/")) {
      const indexPath = safeJoin(ROOT, pathname + "index.html");
      if (!indexPath) return send(res, 400, {}, "Bad path");
      if (!fs.existsSync(indexPath)) return send(res, 404, {}, "Not found");
      const body = fs.readFileSync(indexPath);
      return send(res, 200, { "Content-Type": MIME[".html"] }, body);
    }

    const filePath = safeJoin(ROOT, pathname);
    if (!filePath) return send(res, 400, {}, "Bad path");
    if (!fs.existsSync(filePath)) return send(res, 404, {}, "Not found");

    const ext = path.extname(filePath).toLowerCase();
    const type = MIME[ext] || "application/octet-stream";
    const body = fs.readFileSync(filePath);
    send(res, 200, { "Content-Type": type }, body);
  } catch (e) {
    send(res, 500, { "Content-Type": "text/plain; charset=utf-8" }, String(e));
  }
});

const port = Number(process.env.PORT || 5173);
server.listen(port, "127.0.0.1", () => {
  // eslint-disable-next-line no-console
  console.log(`Server running at http://localhost:${port}/web/`);
});
