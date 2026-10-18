import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const enDir = path.join(rootDir, 'src/locales/en');
const arDir = path.join(rootDir, 'src/locales/ar');
const outFile = path.join(rootDir, 'src/generated/locale_keys.g.ts');
const isCheckOnly = process.argv.includes('--check');

function flattenJson(obj, prefix = '') {
  const result = {};
  for (const [key, val] of Object.entries(obj)) {
    const nextKey = prefix ? `${prefix}.${key}` : key;
    if (val !== null && typeof val === 'object' && !Array.isArray(val)) {
      Object.assign(result, flattenJson(val, nextKey));
    } else {
      result[nextKey] = String(val);
    }
  }
  return result;
}

function extractPlaceholders(text) {
  const matches = text.match(/\{\{\s*[\w.]+\s*\}\}/g) ?? [];
  return matches.map((m) => m.replace(/\s+/g, '')).sort();
}

function loadLocaleNamespaceMap(localeDir) {
  const files = fs.readdirSync(localeDir).filter((f) => f.endsWith('.json')).sort();
  const map = {};
  for (const file of files) {
    const ns = path.basename(file, '.json');
    const raw = JSON.parse(fs.readFileSync(path.join(localeDir, file), 'utf8'));
    map[ns] = flattenJson(raw);
  }
  return map;
}

function validateParity(enMap, arMap) {
  const errors = [];
  const namespaces = Array.from(new Set([...Object.keys(enMap), ...Object.keys(arMap)])).sort();
  for (const ns of namespaces) {
    if (!enMap[ns]) errors.push(`Missing namespace "${ns}" in en`);
    if (!arMap[ns]) errors.push(`Missing namespace "${ns}" in ar`);
    if (!enMap[ns] || !arMap[ns]) continue;
    const allKeys = Array.from(new Set([...Object.keys(enMap[ns]), ...Object.keys(arMap[ns])])).sort();
    for (const k of allKeys) {
      if (!(k in enMap[ns])) errors.push(`Missing key "${ns}:${k}" in en`);
      else if (!(k in arMap[ns])) errors.push(`Missing key "${ns}:${k}" in ar`);
      else {
        const enPh = extractPlaceholders(enMap[ns][k]).join(',');
        const arPh = extractPlaceholders(arMap[ns][k]).join(',');
        if (enPh !== arPh) {
          errors.push(`Placeholder mismatch in "${ns}:${k}": en=[${enPh}] vs ar=[${arPh}]`);
        }
      }
    }
  }
  return errors;
}

function buildGeneratedSource(enMap) {
  const lines = [
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
    '// Run `npm run i18n:generate` to regenerate from src/locales/{en,ar}/*.json',
    '',
    'export const LocaleKeys = {',
  ];
  for (const ns of Object.keys(enMap).sort()) {
    for (const key of Object.keys(enMap[ns]).sort()) {
      const propName = `${ns}_${key.replace(/[.-]/g, '_')}`;
      lines.push(`  ${propName}: '${ns}:${key}',`);
    }
  }
  lines.push('} as const;', '', 'export type LocaleKey = (typeof LocaleKeys)[keyof typeof LocaleKeys];', '');
  return lines.join('\n');
}

const enMap = loadLocaleNamespaceMap(enDir);
const arMap = loadLocaleNamespaceMap(arDir);
const parityErrors = validateParity(enMap, arMap);

if (parityErrors.length > 0) {
  process.stderr.write(`i18n parity check failed:\n${parityErrors.map((e) => `  - ${e}`).join('\n')}\n`);
  process.exit(1);
}

const expectedSource = buildGeneratedSource(enMap);
if (isCheckOnly) {
  if (!fs.existsSync(outFile) || fs.readFileSync(outFile, 'utf8') !== expectedSource) {
    process.stderr.write('src/generated/locale_keys.g.ts is out of date. Run `npm run i18n:generate`.\n');
    process.exit(1);
  }
  process.exit(0);
}

fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, expectedSource, 'utf8');
