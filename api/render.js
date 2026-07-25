// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI → IMAGE RENDER API
// api/render.js
//
// Vercel Serverless Function (Node.js)
//
// POST /api/render
// Content-Type: application/json
//
// REQUEST BODY:
//   {
//     "json":       { ...any QuantumVM SDUI schema... },   // required
//     "width":      390,      // optional, logical dp (default 390)
//     "height":     844,      // optional, logical dp (default 844, null = auto)
//     "pixelRatio": 2,        // optional, device pixel ratio (default 2)
//     "background": "#ffffff" // optional, CSS color (default transparent)
//   }
//
// RESPONSE:
//   Content-Type: image/png
//   Body: raw PNG binary
//
//   On error → JSON { "error": "...", "details": "..." }
//
// HOW IT WORKS:
//   1. Launches a headless Chromium via @sparticuz/chromium (optimised for λ)
//   2. Opens the deployed Flutter web app at /#/export?q=<base64-json>
//   3. Waits for Flutter to render the schema offscreen + write the base64
//      PNG into a hidden DOM element (#__qx_export_result)
//   4. Reads the base64, decodes it, streams it back as image/png
//
// ENVIRONMENT VARIABLES (set in Vercel dashboard):
//   QUANTUM_APP_URL  — Base URL of your deployed Flutter app.
//                      Defaults to the current request host so it works
//                      automatically on Vercel without any manual config.
//   RENDER_SECRET    — Optional shared secret. If set, the caller must
//                      pass the header  X-Render-Secret: <value>  or the
//                      query param ?secret=<value>.  Prevents public abuse.
//   RENDER_TIMEOUT   — How long (ms) to wait for Flutter to finish painting.
//                      Default: 30000 (30 s).
// ════════════════════════════════════════════════════════════════════════════

const chromium = require('@sparticuz/chromium-min');
const puppeteer = require('puppeteer-core');

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function base64UrlEncode(str) {
  return Buffer.from(str, 'utf8')
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function sendError(res, status, message, details = '') {
  console.error(`[quantum/render] ${message}`, details);
  res.status(status).json({ error: message, details: String(details) });
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    if (req.body) return resolve(req.body); // already parsed by Vercel
    let raw = '';
    req.on('data', (chunk) => { raw += chunk; });
    req.on('end', () => {
      try { resolve(JSON.parse(raw)); }
      catch (e) { reject(new Error('Invalid JSON body')); }
    });
    req.on('error', reject);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN HANDLER
// ─────────────────────────────────────────────────────────────────────────────

module.exports = async function handler(req, res) {
  // ── 0. CORS headers ────────────────────────────────────────────────────────
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Render-Secret');

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return sendError(res, 405, 'Method not allowed');

  // ── 1. Optional auth check ─────────────────────────────────────────────────
  const secret = process.env.RENDER_SECRET;
  if (secret) {
    const provided =
      req.headers['x-render-secret'] || req.query?.secret;
    if (provided !== secret) {
      return sendError(res, 401, 'Unauthorized', 'Invalid or missing X-Render-Secret');
    }
  }

  // ── 2. Parse body ──────────────────────────────────────────────────────────
  let body;
  try {
    body = await parseBody(req);
  } catch (e) {
    return sendError(res, 400, 'Bad request', e.message);
  }

  const { json, width = 390, height = 844, pixelRatio = 2, background = 'transparent' } = body;

  if (!json || typeof json !== 'object') {
    return sendError(res, 400, 'Missing or invalid "json" field');
  }

  // ── 3. Build the render URL ────────────────────────────────────────────────
  // The Flutter app reads  /#/export?q=<payload>  and renders the schema.
  const protocol = req.headers['x-forwarded-proto'] || 'https';
  const host = req.headers['host'];
  const baseUrl =
    process.env.QUANTUM_APP_URL ||
    `${protocol}://${host}`;

  const payload = base64UrlEncode(JSON.stringify({
    json,
    width,
    height,
    pixelRatio,
    background,
  }));

  const renderUrl = `${baseUrl}/#/export?q=${payload}`;

  // ── 4. Launch headless Chromium ────────────────────────────────────────────
  const timeout = parseInt(process.env.RENDER_TIMEOUT || '30000', 10);
  let browser;

  try {
    browser = await puppeteer.launch({
      args: [
        ...chromium.args,
        '--disable-web-security',          // allow cross-origin canvas reads
        '--font-render-hinting=none',      // consistent font rendering
        '--disable-font-subpixel-positioning',
      ],
      executablePath: await chromium.executablePath('https://github.com/Sparticuz/chromium/releases/download/v123.0.1/chromium-v123.0.1-pack.tar'),
      headless: chromium.headless,
      defaultViewport: {
        width: Math.ceil(width),
        height: height ? Math.ceil(height) : 1200,
        deviceScaleFactor: pixelRatio,
      },
    });

    const page = await browser.newPage();

    // Silence noisy Flutter console logs
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        console.error('[flutter]', msg.text().slice(0, 200));
      }
    });

    // ── 5. Navigate to the Flutter export route ────────────────────────────
    console.log(`[quantum/render] → ${renderUrl}`);
    await page.goto(renderUrl, {
      waitUntil: 'networkidle0',
      timeout,
    });

    // ── 6. Wait for the Flutter app to signal "ready" ──────────────────────
    // Flutter writes  document.body.dataset.qxReady = 'true'  after capturing.
    await page.waitForFunction(
      () => document.body?.dataset?.qxReady === 'true',
      { timeout, polling: 200 }
    );

    // ── 7. Read the base64 PNG from the hidden DOM element ─────────────────
    const base64Png = await page.evaluate(() => {
      const el = document.getElementById('__qx_export_result');
      return el ? el.textContent : null;
    });

    if (!base64Png) {
      return sendError(res, 500, 'Render failed', 'Flutter did not write export result to DOM');
    }

    // Strip optional data-URL prefix (data:image/png;base64,...)
    const raw = base64Png.replace(/^data:image\/png;base64,/, '');
    const buffer = Buffer.from(raw, 'base64');

    // ── 8. Stream the PNG back ─────────────────────────────────────────────
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Length', buffer.length);
    res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
    res.status(200).end(buffer);

    console.log(`[quantum/render] ✅ ${buffer.length} bytes, ${width}×${height}@${pixelRatio}x`);

  } catch (err) {
    return sendError(res, 500, 'Render error', err.message);
  } finally {
    if (browser) {
      try { await browser.close(); } catch (_) {}
    }
  }
};
