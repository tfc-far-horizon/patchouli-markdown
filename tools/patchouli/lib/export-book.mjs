import { mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { orderKeys, yamlFenced } from './markdown-utils.mjs';
import { renderPageItem } from './render-page.mjs';

export async function exportBook(source, out) {
  const categoriesDir = path.join(source, 'categories');
  const entriesDir = path.join(source, 'entries');
  const categories = await readJsonFiles(categoriesDir);

  await rm(out, { recursive: true, force: true });
  await mkdir(out, { recursive: true });

  for (const categoryFile of categories) {
    const categoryId = path.basename(categoryFile.name, '.json');
    const entryDir = path.join(entriesDir, categoryId);
    const entries = await readJsonFiles(entryDir).catch((error) => {
      if (error.code === 'ENOENT') return [];
      throw error;
    });

    entries.sort(compareEntries);

    const md = renderCategoryDocument(categoryId, categoryFile.data, entries);
    await writeFile(path.join(out, `${categoryId}.md`), md, 'utf8');
  }
}

function renderCategoryDocument(categoryId, category, entries) {
  const lines = [];

  lines.push(yamlFenced('patchouli-category', orderKeys({
    id: categoryId,
    ...category,
  }, ['id', 'name', 'description', 'icon', 'sortnum'])));
  lines.push('');

  for (const entryFile of entries) {
    const entryId = path.basename(entryFile.name, '.json');
    lines.push(`#${entryFile.data.name}`);
    lines.push('');

    const entryMeta = { id: `${categoryId}/${entryId}`, ...entryFile.data };
    delete entryMeta.pages;
    lines.push(yamlFenced('patchouli-entry', orderKeys(entryMeta, [
      'id',
      'name',
      'category',
      'icon',
      'read_by_default',
      'sortnum',
      'extra_recipe_mappings',
    ])));
    lines.push('');

    for (const page of entryFile.data.pages ?? []) {
      lines.push(renderPageItem(page));
    }
  }

  return `${lines.join('\n').replace(/\n{4,}/g, '\n\n\n').trimEnd()}\n`;
}

async function readJsonFiles(dir) {
  const names = await readdir(dir);
  const jsonNames = names.filter((name) => name.endsWith('.json')).sort();
  return Promise.all(
    jsonNames.map(async (name) => ({
      name,
      data: JSON.parse(await readFile(path.join(dir, name), 'utf8')),
    }))
  );
}

function compareEntries(left, right) {
  const leftSort = left.data.sortnum ?? Number.POSITIVE_INFINITY;
  const rightSort = right.data.sortnum ?? Number.POSITIVE_INFINITY;
  if (leftSort !== rightSort) return leftSort - rightSort;
  return left.name.localeCompare(right.name);
}
