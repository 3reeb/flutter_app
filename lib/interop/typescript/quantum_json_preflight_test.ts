#!/usr/bin/env node
/* Quantum JSON Preflight Test Engine
 *
 * Purpose:
 *  - catch the "black screen" class of failures before Flutter runs
 *  - validate generated JSON output from TS build
 *  - verify route discovery, layout discovery, and renderability heuristics
 *
 * Usage:
 *   node quantum_json_preflight_test.js <projectRoot> [configJson]
 *
 * Defaults:
 *   projectRoot: current working directory
 *   configJson : <projectRoot>/assets/config/kernel.json
 *
 * Exit codes:
 *   0 = no blocking issues
 *   1 = blocking issues found
 */

const fs = require('fs');
const path = require('path');

function readJson(filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(text);
}

function exists(p) {
  try { return fs.existsSync(p); } catch { return false; }
}

function isObj(v) {
  return !!v && typeof v === 'object' && !Array.isArray(v);
}

function normalizePath(p) {
  return String(p || '').replace(/\\/g, '/').replace(/\/+/g, '/');
}

function joinUrl(...parts) {
  return normalizePath(parts.filter(Boolean).join('/')).replace(/\/+/g, '/');
}

function isLayoutLikeFile(name) {
  return name === '_layout.json' || name === '_layout.yaml' || name === '_layout.yml';
}

function isPageLikeFile(name) {
  return /^(page|index|route)\.(json|ya?ml)$/i.test(name) || /^\[.*\]\.(json|ya?ml)$/i.test(name);
}

function routeFromFile(relFile) {
  const parts = normalizePath(relFile).split('/').filter(Boolean);
  const file = parts.pop();
  if (!file) return null;

  const stem = file.replace(/\.(json|ya?ml)$/i, '');
  const segments = [...parts, stem].filter(Boolean);

  // route groups like (marketing) are excluded
  const filtered = segments.filter(seg => !(seg.startsWith('(') && seg.endsWith(')')));

  if (filtered.length === 0) return '/';

  // leaf conventions
  const last = filtered[filtered.length - 1];
  if (last === 'page' || last === 'index' || last === 'route') {
    filtered.pop();
  } else if (last.startsWith('[...') && last.endsWith(']')) {
    filtered[filtered.length - 1] = '*';
  } else if (last.startsWith('[') && last.endsWith(']')) {
    filtered[filtered.length - 1] = ':' + last.slice(1, -1);
  }

  const routeSegs = filtered
    .map(seg => {
      if (seg.startsWith('[...') && seg.endsWith(']')) return '*';
      if (seg.startsWith('[') && seg.endsWith(']')) return ':' + seg.slice(1, -1);
      return seg;
    })
    .filter(Boolean);

  return '/' + routeSegs.join('/');
}

function walk(dir, relBase = '') {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = relBase ? path.posix.join(relBase, entry.name) : entry.name;
    if (entry.isDirectory()) out.push(...walk(abs, rel));
    else out.push({ abs, rel: normalizePath(rel), name: entry.name });
  }
  return out;
}

function flatStringMap(value, pathPrefix = '') {
  const issues = [];
  if (!isObj(value)) return issues;
  for (const [k, v] of Object.entries(value)) {
    if (k === 'custom' && isObj(v)) {
      for (const [ck, cv] of Object.entries(v)) {
        if (cv !== null && typeof cv !== 'string') {
          issues.push(`${pathPrefix}.custom.${ck} must be a string`);
        }
      }
    } else if (v !== null && typeof v !== 'string') {
      issues.push(`${pathPrefix}.${k} must be a string`);
    }
  }
  return issues;
}

function nodeIssues(node, p = 'ui', seen = new Set()) {
  const issues = [];
  if (node === null || node === undefined) {
    issues.push(`${p} is null/undefined`);
    return issues;
  }
  if (Array.isArray(node)) {
    if (node.length === 0) issues.push(`${p} is an empty array`);
    node.forEach((child, i) => issues.push(...nodeIssues(child, `${p}[${i}]`, seen)));
    return issues;
  }
  if (!isObj(node)) {
    // primitives can be valid text payloads in some paths
    return issues;
  }

  const type = String(node.type || node.kind || '').trim();
  const key = JSON.stringify(node);
  if (seen.has(key)) return issues;
  seen.add(key);

  if (!type) issues.push(`${p} missing type/kind`);

  const textish = new Set(['text', 'title']);
  const containerish = new Set(['box', 'page', 'layout', 'template', 'shell', 'row', 'col', 'grid', 'stack', 'layer', 'masonry', 'matrix', 'responsive']);

  if (textish.has(type)) {
    const text = node.props && (node.props.text ?? node.props.value);
    if (typeof text !== 'string' || !text.trim()) {
      issues.push(`${p} (${type}) missing props.text`);
    }
  }

  const children = Array.isArray(node.children) ? node.children : [];
  const slots = isObj(node.slots) ? node.slots : {};
  if (containerish.has(type) && children.length === 0 && Object.keys(slots).length === 0) {
    issues.push(`${p} (${type}) has no children/slots`);
  }

  for (const [slotName, slotValue] of Object.entries(slots)) {
    issues.push(...nodeIssues(slotValue, `${p}.slots.${slotName}`, seen));
  }
  children.forEach((child, i) => issues.push(...nodeIssues(child, `${p}.children[${i}]`, seen)));

  // Heuristic: common render core nodes should have props or content
  if (!containerish.has(type) && !textish.has(type)) {
    const hasProps = isObj(node.props) && Object.keys(node.props).length > 0;
    const hasContent = children.length > 0 || Object.keys(slots).length > 0;
    if (!hasProps && !hasContent) {
      issues.push(`${p} (${type || 'unknown'}) is empty and likely renders nothing`);
    }
  }
  return issues;
}

function validatePageJson(pageJson, sourceRel) {
  const issues = [];
  if (!isObj(pageJson)) {
    issues.push(`${sourceRel}: page file is not a JSON object`);
    return issues;
  }

  const ui = pageJson.ui ?? pageJson.view ?? pageJson.template;
  if (ui === undefined) issues.push(`${sourceRel}: missing ui/view/template payload`);
  else issues.push(...nodeIssues(ui, `${sourceRel}:ui`));

  if (pageJson.meta !== undefined) {
    issues.push(...flatStringMap(pageJson.meta, `${sourceRel}.meta`));
  }

  if (pageJson.guards !== undefined && !Array.isArray(pageJson.guards)) {
    issues.push(`${sourceRel}.guards must be an array`);
  }

  if (pageJson.route !== undefined && !isObj(pageJson.route)) {
    issues.push(`${sourceRel}.route must be an object when present`);
  }

  return issues;
}

function main() {
  const projectRoot = normalizePath(process.argv[2] || process.cwd());
  const configPath = normalizePath(process.argv[3] || path.join(projectRoot, 'assets', 'config', 'kernel.json'));
  const report = [];

  if (!exists(configPath)) {
    console.error(`Missing config JSON: ${configPath}`);
    process.exit(1);
  }

  const config = readJson(configPath);
  const pagesDir = normalizePath(
    config?.router?.pagesDir ||
    config?.pagesDir ||
    config?.boot?.pagesDir ||
    'pages'
  );

  const assetsRoot = normalizePath(path.dirname(path.dirname(configPath))); // assets/config/kernel.json -> assets
  const expectedPagesRoot = normalizePath(path.join(assetsRoot, pagesDir));
  const altPagesRoot = normalizePath(path.join(assetsRoot, 'pages'));

  report.push(`config: ${configPath}`);
  report.push(`pagesDir (configured): ${pagesDir}`);
  report.push(`expected pages root: ${expectedPagesRoot}`);

  const actualPagesRootExists = exists(expectedPagesRoot);
  const altPagesRootExists = expectedPagesRoot !== altPagesRoot && exists(altPagesRoot);

  if (!actualPagesRootExists && altPagesRootExists) {
    report.push(`!! MISMATCH: runtime expects ${expectedPagesRoot} but build output exists at ${altPagesRoot}`);
  }

  if (!actualPagesRootExists && !altPagesRootExists) {
    report.push(`!! No pages directory found at ${expectedPagesRoot} or ${altPagesRoot}`);
  }

  const scanRoot = actualPagesRootExists ? expectedPagesRoot : (altPagesRootExists ? altPagesRoot : null);
  const blocking = [];

  if (scanRoot) {
    const files = walk(scanRoot);
    const pageFiles = files.filter(f => isPageLikeFile(f.name));
    const layoutFiles = files.filter(f => isLayoutLikeFile(f.name));

    report.push(`scan root: ${scanRoot}`);
    report.push(`page files: ${pageFiles.length}`);
    report.push(`layout files: ${layoutFiles.length}`);

    const routes = new Map();
    for (const f of pageFiles) {
      const rel = normalizePath(path.relative(scanRoot, f.abs));
      const route = routeFromFile(rel);
      if (!route) continue;
      if (routes.has(route)) {
        blocking.push(`duplicate route: ${route} from ${routes.get(route)} and ${rel}`);
      } else {
        routes.set(route, rel);
      }

      try {
        const data = readJson(f.abs);
        blocking.push(...validatePageJson(data, rel).map(x => `${rel}: ${x}`));
      } catch (e) {
        blocking.push(`${rel}: invalid JSON (${e.message})`);
      }
    }

    if (!routes.has('/')) {
      blocking.push(`root route "/" was not discovered`);
    }

    // check for empty route tree conditions
    if (pageFiles.length === 0) {
      blocking.push(`no page files discovered under ${scanRoot}`);
    }
  }

  // write report if requested
  const reportFile = path.join(projectRoot, 'quantum_json_preflight_report.txt');
  fs.writeFileSync(reportFile, report.join('\n') + '\n', 'utf8');

  if (blocking.length) {
    console.error('Quantum JSON preflight failed:\n' + blocking.map(x => ' - ' + x).join('\n'));
    console.error(`Report written to: ${reportFile}`);
    process.exit(1);
  }

  console.log('Quantum JSON preflight passed.');
  console.log(`Report written to: ${reportFile}`);
}

if (require.main === module) {
  main();
}
