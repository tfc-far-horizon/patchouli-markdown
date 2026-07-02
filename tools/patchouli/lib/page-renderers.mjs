import {
  emptyFenced,
  fenced,
  hasOwnText,
  indent,
  inlineCode,
  isPlainObject,
  orderKeys,
  patchouliTextToMarkdown,
  patchouliTitleToMarkdown,
  stringifyYaml,
  yamlFenced,
} from './markdown-utils.mjs';

export const tfcRecipePageTypes = new Set([
  'tfc:knapping_recipe',
  'tfc:anvil_recipe',
  'tfc:heat_recipe',
  'tfc:quern_recipe',
  'tfc:sealed_barrel_recipe',
  'tfc:rock_knapping_recipe',
  'tfc:loom_recipe',
  'tfc:welding_recipe',
  'tfc:glassworking_recipe',
  'tfc:drying_recipe',
  'tfc:tri_anvil_recipe',
  'tfc:instant_barrel_recipe',
]);

export function renderTextPage(page, itemTitle) {
  const body = [];
  appendAnchorLine(body, page);
  body.push(...patchouliTextToMarkdown(page.text ?? '').map(indent));
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderCraftingPage(page, itemTitle, pageType) {
  const body = [];
  appendAnchorLine(body, page);
  const craftingBlock = renderCraftingRecipes(page);
  body.push(indent(fenced(craftingBlock.raw ? `raw/${pageType}` : pageType, craftingBlock.content)));
  appendPageTextBody(body, page);
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderYamlPage(page, itemTitle, pageType, preferredKeys = []) {
  const body = [];
  appendAnchorLine(body, page);
  const pageData = pageBodyData(page, preferredKeys);
  if (Object.keys(pageData).length > 0) {
    body.push(indent(yamlFenced(pageType, pageData)));
  }
  appendPageTextBody(body, page);
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderMultiMultiBlockPage(page, itemTitle) {
  const unsupportedKeys = Object.keys(page).filter((key) => {
    return !['type', 'title', 'anchor', 'text', 'multiblocks'].includes(key);
  });

  if (unsupportedKeys.length > 0 || !Array.isArray(page.multiblocks)) {
    return renderRawPage(page, itemTitle, page.type ?? 'tfc:multimultiblock');
  }

  const body = [];
  appendAnchorLine(body, page);
  body.push(indent(emptyFenced('tfc:multimultiblock')));

  for (const multiblock of page.multiblocks) {
    if (typeof multiblock === 'string') {
      body.push(indent(`+ ${inlineCode(multiblock)}`));
    } else if (isPlainObject(multiblock)) {
      body.push(indent('+ multiblock'));
      body.push(indent(indent(yamlFenced('patchouli:multiblock', multiblock))));
    } else {
      return renderRawPage(page, itemTitle, page.type ?? 'tfc:multimultiblock');
    }
  }

  appendPageTextBody(body, page);
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderMultiblockPage(page) {
  const itemTitle = renderPageItemTitleWithName(page);
  const body = [];
  appendAnchorLine(body, page);
  const pageData = pageBodyData(page, ['multiblock', 'multiblock_id', 'enable_visualize']);
  delete pageData.name;
  if (Object.keys(pageData).length > 0) {
    body.push(indent(yamlFenced('patchouli:multiblock', pageData)));
  }
  appendPageTextBody(body, page);
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderTfcRecipePage(page, itemTitle, pageType) {
  const recipeBlock = renderTfcRecipeBlock(page);
  const body = [];
  appendAnchorLine(body, page);
  body.push(indent(fenced(recipeBlock.raw ? `raw/${pageType}` : pageType, recipeBlock.content)));
  appendPageTextBody(body, page);
  return [`+ ${itemTitle}`, ...body].join('\n');
}

export function renderRawPage(page, itemTitle, pageType) {
  return [
    `+ ${itemTitle}`,
    ...renderAnchorLines(page),
    indent(fenced(`raw/${pageType}`, page)),
  ].join('\n');
}

export function renderPageItemTitle(page) {
  const title = hasOwnText(page.title) ? page.title : null;
  if (title) return patchouliTitleToMarkdown(title);
  return '_untitled_';
}

export function renderEmptyPage() {
  return '+ _empty_'
}

function renderPageItemTitleWithName(page) {
  const title = hasOwnText(page.title) ? page.title : page.name;
  if (hasOwnText(title)) return patchouliTitleToMarkdown(title);
  return '_untitled_';
}

function renderCraftingRecipes(page) {
  const unsupportedKeys = Object.keys(page).filter((key) => {
    return !['type', 'title', 'anchor', 'text', 'recipe', 'recipe2'].includes(key);
  });

  if (unsupportedKeys.length > 0) {
    return {
      raw: true,
      content: JSON.stringify(page, null, 2),
    };
  }

  return {
    raw: false,
    content: [page.recipe, page.recipe2].filter(hasOwnText).join('\n'),
  };
}

function renderTfcRecipeBlock(page) {
  const unsupportedKeys = Object.keys(page).filter((key) => {
    return !['type', 'title', 'anchor', 'text', 'recipe', 'recipes', 'recipe2', 'recipe3', 'header'].includes(key);
  });

  if (unsupportedKeys.length > 0) {
    return {
      raw: true,
      content: JSON.stringify(page, null, 2),
    };
  }

  if (hasOwnText(page.header)) {
    return {
      raw: false,
      content: stringifyYaml(orderKeys({
        header: page.header,
        recipes: collectRecipeIds(page),
      }, ['header', 'recipes'])),
    };
  }

  return {
    raw: false,
    content: collectRecipeIds(page).join('\n'),
  };
}

function collectRecipeIds(page) {
  if (Array.isArray(page.recipes)) return page.recipes.filter(hasOwnText);
  return [page.recipe, page.recipe2, page.recipe3].filter(hasOwnText);
}

function pageBodyData(page, preferredKeys) {
  const data = { ...page };
  delete data.type;
  delete data.title;
  delete data.anchor;
  delete data.text;
  return orderKeys(data, preferredKeys);
}

function renderPageTextBody(page) {
  if (!hasOwnText(page.text)) return [];
  return patchouliTextToMarkdown(page.text).map(indent);
}

function appendPageTextBody(body, page) {
  const textBody = renderPageTextBody(page);
  if (textBody.length === 0) return;
  body.push(...textBody);
}

function appendAnchorLine(body, page) {
  if (!hasOwnText(page.anchor)) return;
  body.push(indent(`[](#${page.anchor})`));
}

function renderAnchorLines(page) {
  const lines = [];
  appendAnchorLine(lines, page);
  return lines;
}
