import fs from 'fs';
import path from 'path';

// This dynamically imports the config and writes it to assets/sdui.json
async function buildSdui() {
  try {
    const configModule = await import('../lib/interop/typescript/quantum.config');
    const config = configModule.default || configModule.kernel?.defineConfig() || configModule;

    const outPath = path.resolve(process.cwd(), 'assets', 'sdui.json');

    // Ensure assets dir exists
    const outDir = path.dirname(outPath);
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }

    fs.writeFileSync(outPath, JSON.stringify(config, null, 2), 'utf-8');
    console.log(`[SDUI Build] Successfully generated JSON configuration at ${outPath}`);
  } catch (error) {
    console.error('[SDUI Build Error] Failed to generate SDUI configuration:', error);
    process.exit(1);
  }
}

buildSdui();
