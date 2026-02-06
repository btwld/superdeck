#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.cwd();
const DOCS_DIR = path.join(ROOT, 'docs');
const DOCS_JSON = path.join(ROOT, 'docs.json');

const REQUIRED_FRONTMATTER = ['title', 'description'];

const PROPER_NOUNS = new Set([
  'SuperDeck',
  'Flutter',
  'GitHub',
  'DartPad',
  'Mermaid',
  'CLI',
  'API',
  'YAML',
  'JSON',
  'MDX',
  'PDF',
  'macOS',
  'MeasureSize',
  'DeckOptions',
  'WidgetDefinition',
  'CI/CD',
  'Dart',
  'Markdown',
  'Actions',
]);

const errors = [];

const posix = (p) => p.split(path.sep).join('/');

function addError(file, message, line) {
  const where = line ? `${file}:${line}` : file;
  errors.push(`${where} ${message}`);
}

async function listDocsFiles(dir) {
  const out = [];
  async function walk(curr) {
    const entries = await fs.readdir(curr, { withFileTypes: true });
    for (const entry of entries) {
      const abs = path.join(curr, entry.name);
      if (entry.isDirectory()) {
        await walk(abs);
      } else if (entry.isFile() && entry.name.endsWith('.mdx')) {
        out.push(abs);
      }
    }
  }
  await walk(dir);
  return out;
}

function stripInlineMarkup(text) {
  return text
    .replace(/`[^`]*`/g, '')
    .replace(/\[(.*?)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, '')
    .trim();
}

function isSentenceCaseHeading(text) {
  const plain = stripInlineMarkup(text);
  if (!plain) return true;
  const words = plain.split(/\s+/).filter(Boolean);
  if (words.length <= 1) return true;

  for (let i = 1; i < words.length; i++) {
    const raw = words[i];
    const clean = raw
      .replace(/^["'“”‘’([{<]+/, '')
      .replace(/["'“”‘’).,:;!?\]}>-]+$/, '');
    if (!clean) continue;
    if (/^[a-z0-9]/.test(clean)) continue;
    if (PROPER_NOUNS.has(clean)) continue;
    if (/^[A-Z0-9_-]{2,}$/.test(clean)) continue;
    if (/^[A-Z][a-z]/.test(clean)) return false;
  }

  return true;
}

function parseFrontmatter(content, relPath) {
  const lines = content.split(/\r?\n/);
  if (lines[0]?.trim() !== '---') {
    addError(relPath, 'Missing frontmatter opening delimiter (`---`).');
    return { attrs: {}, bodyStartLine: 1 };
  }

  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === '---') {
      end = i;
      break;
    }
  }

  if (end === -1) {
    addError(relPath, 'Missing frontmatter closing delimiter (`---`).');
    return { attrs: {}, bodyStartLine: 1 };
  }

  const attrs = {};
  for (let i = 1; i < end; i++) {
    const line = lines[i];
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) continue;
    const [, key, value] = match;
    attrs[key] = value.trim().replace(/^"|"$/g, '').replace(/^'|'$/g, '');
  }

  return { attrs, bodyStartLine: end + 2 };
}

function resolveInternalDocPath(href) {
  if (!href.startsWith('/')) return null;
  if (href.startsWith('/assets/')) return null;

  const cleaned = href.split('#')[0].split('?')[0].replace(/\/$/, '');

  if (cleaned === '') return path.join(DOCS_DIR, 'index.mdx');

  if (cleaned.endsWith('.mdx')) {
    return path.join(DOCS_DIR, cleaned.slice(1));
  }

  const candidate = path.join(DOCS_DIR, `${cleaned.slice(1)}.mdx`);
  return candidate;
}

function extractHeadingsAndLinks(content) {
  const lines = content.split(/\r?\n/);
  const headings = [];
  const absoluteLinks = [];

  let inFence = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (/^```/.test(line.trim())) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
    if (headingMatch) {
      headings.push({
        level: headingMatch[1].length,
        text: headingMatch[2].trim(),
        line: i + 1,
      });
    }

    const linkRegex = /\[[^\]]+\]\((\/[^)\s]+)\)/g;
    let linkMatch;
    while ((linkMatch = linkRegex.exec(line)) !== null) {
      absoluteLinks.push({ href: linkMatch[1], line: i + 1 });
    }
  }

  return { headings, absoluteLinks };
}

function getSidebarHrefs(sidebar) {
  const hrefs = [];

  function walkItem(item) {
    if (!item || typeof item !== 'object') return;
    if (typeof item.href === 'string') hrefs.push(item.href);
    if (Array.isArray(item.pages)) {
      for (const page of item.pages) walkItem(page);
    }
  }

  if (Array.isArray(sidebar)) {
    for (const item of sidebar) walkItem(item);
  } else if (sidebar && typeof sidebar === 'object') {
    for (const value of Object.values(sidebar)) {
      if (Array.isArray(value)) {
        for (const item of value) walkItem(item);
      }
    }
  }

  return hrefs;
}

async function main() {
  const docsFiles = await listDocsFiles(DOCS_DIR);
  const docsPathSet = new Set(docsFiles.map((f) => posix(path.relative(ROOT, f))));

  for (const absPath of docsFiles) {
    const relPath = posix(path.relative(ROOT, absPath));
    const content = await fs.readFile(absPath, 'utf8');
    const { attrs } = parseFrontmatter(content, relPath);

    for (const key of REQUIRED_FRONTMATTER) {
      if (!attrs[key]) {
        addError(relPath, `Missing required frontmatter key: \`${key}\`.`);
      }
    }

    const { headings, absoluteLinks } = extractHeadingsAndLinks(content);

    const h1s = headings.filter((h) => h.level === 1);
    if (h1s.length === 0) {
      addError(relPath, 'Missing H1 heading (`# ...`).');
    }
    if (h1s.length > 1) {
      addError(relPath, 'Duplicate H1 headings found. Keep exactly one H1.', h1s[1].line);
    }

    for (const heading of headings) {
      const text = heading.text;

      if (/^(\d+[.)]|step\s+\d+)/i.test(text)) {
        addError(relPath, `Numbered heading is not allowed: \`${text}\`.`, heading.line);
      }

      if (!isSentenceCaseHeading(text)) {
        addError(
          relPath,
          `Heading should use sentence case (or approved proper nouns): \`${text}\`.`,
          heading.line,
        );
      }
    }

    if (relPath.startsWith('docs/reference/') || relPath === 'docs/guides/cli-reference.mdx') {
      const refStepMatch = content.match(/\bStep\s+\d+\b/i);
      if (refStepMatch) {
        addError(relPath, 'Reference pages must not contain procedural "Step N" language.');
      }
    }

    for (const link of absoluteLinks) {
      const targetAbs = resolveInternalDocPath(link.href);
      if (!targetAbs) continue;
      const targetRel = posix(path.relative(ROOT, targetAbs));
      if (!docsPathSet.has(targetRel)) {
        addError(
          relPath,
          `Broken internal absolute link \`${link.href}\` (expected page \`${targetRel}\`).`,
          link.line,
        );
      }
    }
  }

  const docsJsonRaw = await fs.readFile(DOCS_JSON, 'utf8');
  let docsJson;
  try {
    docsJson = JSON.parse(docsJsonRaw);
  } catch (error) {
    addError('docs.json', `Invalid JSON: ${error.message}`);
  }

  if (docsJson) {
    const sidebarHrefs = getSidebarHrefs(docsJson.sidebar);
    for (const href of sidebarHrefs) {
      const targetAbs = resolveInternalDocPath(href);
      if (!targetAbs) continue;
      const targetRel = posix(path.relative(ROOT, targetAbs));
      if (!(await fileExists(targetAbs))) {
        addError('docs.json', `Sidebar link \`${href}\` points to missing page \`${targetRel}\`.`);
      }
    }
  }

  if (errors.length > 0) {
    console.error('\nDocumentation quality checks failed:\n');
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    console.error(`\nTotal issues: ${errors.length}`);
    process.exit(1);
  }

  console.log('Documentation quality checks passed.');
}

async function fileExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
