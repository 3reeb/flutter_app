import fs from 'fs';
import path from 'path';

// This dynamically imports the config and writes it to a file router structure
async function buildSdui() {
  try {
    const configModule = await import('../lib/interop/typescript/quantum.config');
    const config = configModule.default || configModule.kernel?.defineConfig() || configModule;

    const baseAssetsDir = path.resolve(process.cwd(), 'assets');
    const pagesDir = path.join(baseAssetsDir, 'pages');
    const configDir = path.join(baseAssetsDir, 'config');

    // Ensure base directories exist
    fs.mkdirSync(pagesDir, { recursive: true });
    fs.mkdirSync(configDir, { recursive: true });

    // 1. Export Global Config to config/kernel.json
    // We clone the config and remove the app.pages tree so it's not duplicated
    const kernelConfig = { ...config };
    if (kernelConfig.app) {
      kernelConfig.app = { ...kernelConfig.app };
      delete kernelConfig.app.pages; 
    }
    fs.writeFileSync(
      path.join(configDir, 'kernel.json'),
      JSON.stringify(kernelConfig, null, 2),
      'utf-8'
    );
    console.log(`[SDUI Build] Generated global kernel config at assets/config/kernel.json`);

    // 2. Export Pages recursively
    if (config.app && config.app.pages) {
      console.log('PAGES DUMP:', JSON.stringify(config.app.pages, null, 2));
      exportPageTree(config.app.pages, pagesDir, config.app.layouts, config.app.fragments);
    }
    
    console.log(`[SDUI Build] Successfully generated File Router JSONs`);
  } catch (error) {
    console.error('[SDUI Build Error] Failed to generate SDUI configuration:', error);
    process.exit(1);
  }
}

// Function to recursively export pages
function exportPageTree(pages, currentDir, layouts, fragments) {
  if (!Array.isArray(pages)) {
    // If it's a wrapper, it might have .items or .children
    pages = pages.items || pages.children || [];
  }

  for (const page of pages) {
    if (!page || !page.path) continue;

    // Handle path conversion to folders (e.g. '/dashboard/reports' -> 'dashboard/reports')
    let routePath = page.path;
    if (routePath.startsWith('/')) {
      routePath = routePath.substring(1);
    }
    
    // Determine the actual folder path
    // e.g. path '/dashboard/[reportId]' -> folder: 'dashboard', filename: '[reportId].json'
    // or path '/' -> folder: '.', filename: 'page.json'
    // or path '/dashboard' -> folder: 'dashboard', filename: 'page.json'
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
    if (page.layout && page.layout.$ref) {
      const layoutId = page.layout.$ref;
      const layoutDef = layouts[layoutId];
      if (layoutDef) {
        const layoutFile = path.join(targetFolder, '_layout.json');
        if (!fs.existsSync(layoutFile)) {
          fs.writeFileSync(layoutFile, JSON.stringify(layoutDef, null, 2));
          console.log(`  -> Generated Layout: ${path.relative(process.cwd(), layoutFile)}`);
        }
      }
    }

    // Build the page object we will write
    const pageObj = { ...page };
    
    // Resolve fragments
    if (page.page && page.page.$ref) {
      const fragmentId = page.page.$ref;
      const fragmentDef = fragments[fragmentId];
      if (fragmentDef) {
        pageObj.fragment = fragmentDef;
      }
    }
    
    // Write page.json or [id].json
    const pageFile = path.join(targetFolder, filename);
    fs.writeFileSync(pageFile, JSON.stringify(pageObj, null, 2));
    console.log(`  -> Generated Page: ${path.relative(process.cwd(), pageFile)}`);

    // Recursively process children
    if (page.children) {
      exportPageTree(page.children, currentDir, layouts, fragments);
    }
  }
}

buildSdui();
