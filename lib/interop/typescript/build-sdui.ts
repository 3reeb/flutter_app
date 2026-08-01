import * as fs from 'fs';
import * as path from 'path';

// ── Helpers ────────────────────────────────────────────────────────────────────

/**
 * Safely converts any value to a flat string so Dart's DDC runtime never
 * encounters `IdentityMap<String, dynamic>` where a `String` is expected.
 */
function coerceToString(v: unknown): string {
  if (v === null || v === undefined) return '';
  if (typeof v === 'string') return v;
  if (typeof v === 'boolean' || typeof v === 'number') return String(v);
  // Objects / arrays → JSON-encode so Dart can re-decode if needed
  try { return JSON.stringify(v); } catch { return String(v); }
}

/**
 * Flatten a meta/custom object so every leaf value becomes a string.
 * This prevents the Dart DDC "IdentityMap is not a subtype of String" crash.
 */
function flattenMetaToStrings(obj: Record<string, unknown>): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [k, v] of Object.entries(obj)) {
    result[k] = coerceToString(v);
  }
  return result;
}


/**
 * Deeply normalizes any config value for safe JSON output.
 * - unwraps SduiElement instances to their native node form
 * - strips accidental {_node: ...} wrappers
 * - recursively preserves ordinary JSON objects/arrays
 */
function normalizeForOutput<T>(value: T): T {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) {
    return value.map((item) => normalizeForOutput(item)) as unknown as T;
  }
  if (typeof value !== 'object') return value;

  const obj = value as Record<string, unknown>;

  if ('_node' in obj && obj._node && typeof obj._node === 'object') {
    return normalizeForOutput(obj._node as T);
  }

  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) out[k] = normalizeForOutput(v);
  }
  return out as T;
}


/**
 * Templates must carry a subtype for the runtime template builder.
 * The Dart runtime resolves the subtype from either:
 *  - props.__subType
 *  - the colon suffix in `type`
 */
function patchTemplateSubtypes<T>(value: T, fallbackSubtype?: string): T {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) {
    return value.map((item) => patchTemplateSubtypes(item, fallbackSubtype)) as unknown as T;
  }
  if (typeof value !== 'object') return value;

  const obj = value as Record<string, unknown>;

  if (obj.type === 'template') {
    const props = (obj.props && typeof obj.props === 'object' && !Array.isArray(obj.props))
      ? (obj.props as Record<string, unknown>)
      : (obj.props = {} as Record<string, unknown>) as Record<string, unknown>;

    const explicitSubtype =
      typeof props.__subType === 'string' && props.__subType.trim()
        ? props.__subType.trim()
        : '';
    const inheritedSubtype =
      typeof props.name === 'string' && props.name.trim()
        ? props.name.trim()
        : (fallbackSubtype ?? '').trim();
    const subtype = explicitSubtype || inheritedSubtype;

    if (subtype) props.__subType = subtype;
  }

  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) obj[k] = patchTemplateSubtypes(v as any, fallbackSubtype) as unknown as T;
  }
  return value;
}

function serializeRenderableNode<T>(value: T, fallbackSubtype?: string): T {
  return patchTemplateSubtypes(normalizeForOutput(value), fallbackSubtype);
}

// ── Main ───────────────────────────────────────────────────────────────────────

// This dynamically imports the config and writes it to a file router structure
async function buildSdui() {
  try {
    const configModule = await import('./quantum.config');
    const config = configModule.default || (configModule as any).kernel?.defineConfig() || configModule;

    const baseAssetsDir = path.resolve(process.cwd(), 'assets');
    const pagesDir = path.join(baseAssetsDir, 'pages');
    const configDir = path.join(baseAssetsDir, 'config');

    // Ensure base directories exist
    fs.mkdirSync(pagesDir, { recursive: true });
    fs.mkdirSync(configDir, { recursive: true });

    // 1. Export Global Config to config/kernel.json
    // We clone the config and remove the app.pages tree so it's not duplicated
    const kernelConfig: any = { ...config };
    if (kernelConfig.app) {
      kernelConfig.app = { ...kernelConfig.app };
      delete kernelConfig.app.pages;
    }
    fs.writeFileSync(
      path.join(configDir, 'kernel.json'),
      JSON.stringify(normalizeForOutput(kernelConfig), null, 2),
      'utf-8'
    );
    console.log(`[SDUI Build] Generated global kernel config at assets/config/kernel.json`);

    // 2. Export Pages recursively
    if (config.app && (config.app as any).pages) {
      exportPageTree(
        (config.app as any).pages,
        pagesDir,
        (config.app as any).layouts,
        (config.app as any).fragments,
      );
    }

    console.log(`[SDUI Build] Successfully generated File Router JSONs`);
  } catch (error) {
    console.error('[SDUI Build Error] Failed to generate SDUI configuration:', error);
    process.exit(1);
  }
}

// ── Recursive page exporter ────────────────────────────────────────────────────

function exportPageTree(pages: any, currentDir: string, layouts: any, fragments: any) {
  if (!Array.isArray(pages)) {
    // If it's a wrapper object, it might have .routes, .items or .children
    pages = pages.routes || pages.items || pages.children || [];
  }

  for (const page of pages) {
    if (!page || !page.path) continue;

    // Handle path conversion to folders (e.g. '/dashboard/reports' -> 'dashboard/reports')
    let routePath: string = page.path;
    if (routePath.startsWith('/')) {
      routePath = routePath.substring(1);
    }

    // Determine the actual folder path
    // e.g. path '/dashboard/[reportId]' -> folder: 'dashboard', filename: '[reportId].json'
    //      path '/'                     -> folder: '.',          filename: 'page.json'
    //      path '/dashboard'            -> folder: 'dashboard',  filename: 'page.json'
    const parts = routePath.split('/').filter(Boolean);

    let targetFolder = currentDir;
    let filename = 'page.json';

    if (parts.length === 0) {
      targetFolder = currentDir;
      filename = 'page.json';
    } else {
      const lastPart = parts[parts.length - 1];
      if (lastPart.startsWith('[') && lastPart.endsWith(']')) {
        targetFolder = path.join(currentDir, ...parts.slice(0, parts.length - 1));
        filename = `${lastPart}.json`;
      } else {
        targetFolder = path.join(currentDir, ...parts);
        filename = 'page.json';
      }
    }

    fs.mkdirSync(targetFolder, { recursive: true });

    // Output Layout if defined and we haven't written it to this folder yet
    if (page.layout && page.layout.name) {
      const layoutId = page.layout.name;
      const layoutDef = layouts?.[layoutId];
      if (layoutDef) {
        const layoutFile = path.join(targetFolder, '_layout.json');
        if (!fs.existsSync(layoutFile)) {
          const layoutObj: any = { ...layoutDef };
          // Map TS layout 'template' to Dart AST 'ui'
          if (layoutObj.template) {
            layoutObj.ui = serializeRenderableNode(layoutObj.template, layoutId);
            delete layoutObj.template;
          }
          fs.writeFileSync(layoutFile, JSON.stringify(normalizeForOutput(layoutObj), null, 2));
          console.log(`  -> Generated Layout: ${path.relative(process.cwd(), layoutFile)}`);
        }
      }
    }

    // Build the page object we will write
    const pageObj: any = { ...page };

    // 1. Resolve fragments and map to 'ui'
    if (page.page && page.page.name) {
      const fragmentId = page.page.name;
      const fragmentDef = fragments?.[fragmentId];
      if (fragmentDef && fragmentDef.template) {
        pageObj.ui = normalizeForOutput(fragmentDef.template);
      }
    }

    // 2. Map SEO/Meta to unified Dart 'meta'
    //
    //    ⚠️  CRITICAL: All values in meta.custom MUST be flat strings.
    //    Dart's DDC runtime enforces strict type checks — if it finds a
    //    Map<String,dynamic> where a String is expected it throws:
    //    "IdentityMap<String, dynamic> is not a subtype of String".
    //    We guard against this at build time here AND at runtime in Dart.
    const newMeta: Record<string, unknown> = {};

    if (pageObj.seo) {
      if (pageObj.seo.title)       newMeta.title       = String(pageObj.seo.title);
      if (pageObj.seo.description) newMeta.description = String(pageObj.seo.description);
      if (pageObj.seo.keywords)    newMeta.keywords    = pageObj.seo.keywords;   // string[]
      if (pageObj.seo.ogImage)     newMeta.ogImage     = String(pageObj.seo.ogImage);
      delete pageObj.seo;
    }

    // Page-level meta tags (e.g. { area: 'marketing', kind: 'landing' })
    // Coerce every value to string so the Dart side stays type-safe.
    if (pageObj.meta && typeof pageObj.meta === 'object' && !Array.isArray(pageObj.meta)) {
      newMeta.custom = flattenMetaToStrings(pageObj.meta as Record<string, unknown>);
    }

    pageObj.meta = newMeta;

    // 3. Map Guards to Dart-compatible 'redirect' structures
    if (pageObj.guards && Array.isArray(pageObj.guards)) {
      pageObj.guards = pageObj.guards.map((g: any) => {
        if (g.type === 'auth') {
          return {
            type: 'redirect',
            condition: 'auth.isAuthenticated',
            to: g.redirectTo || '/login',
          };
        }
        if (g.type === 'role') {
          return {
            type: 'redirect',
            condition: `auth.roles.includes('${g.role ? g.role[0] : ''}')`,
            to: g.redirectTo || '/',
          };
        }
        return g;
      });
    }

    // 4. Cleanup TS-only properties Dart doesn't expect
    delete pageObj.page;
    delete pageObj.fragment;
    delete pageObj.layout;    // Let the folder _layout.json inheritance handle this
    delete pageObj.children;
    delete pageObj.nested;

    // Write page.json or [paramId].json
    const pageFile = path.join(targetFolder, filename);
    fs.writeFileSync(pageFile, JSON.stringify(normalizeForOutput(pageObj), null, 2));
    console.log(`  -> Generated Page: ${path.relative(process.cwd(), pageFile)}`);

    // Recursively process children — use currentDir (not targetFolder) so sibling
    // nested routes are placed relative to the root pages dir as their paths imply.
    if (page.children) {
      exportPageTree(page.children, currentDir, layouts, fragments);
    }
  }
}

buildSdui();
