import {
  renderCraftingPage,
  renderMultiblockPage,
  renderMultiMultiBlockPage,
  renderPageItemTitle,
  renderRawPage,
  renderTextPage,
  renderTfcRecipePage,
  renderYamlPage,
  tfcRecipePageTypes,
  renderEmptyPage,
} from './page-renderers.mjs';

export function renderPageItem(page) {
  const pageType = page.type ?? 'patchouli:text';
  const itemTitle = renderPageItemTitle(page);

  if (pageType === 'patchouli:text') {
    return renderTextPage(page, itemTitle);
  }

  if (pageType === 'patchouli:crafting') {
    return renderCraftingPage(page, itemTitle, pageType);
  }

  if (pageType === 'patchouli:image') {
    return renderYamlPage(page, itemTitle, pageType, ['images', 'border']);
  }

  if (pageType === 'patchouli:spotlight') {
    return renderYamlPage(page, itemTitle, pageType, ['item', 'link_recipes', 'link_recipe']);
  }

  if (pageType === 'patchouli:entity') {
    return renderYamlPage(page, itemTitle, pageType, ['entity', 'scale', 'name']);
  }

  if (pageType === 'patchouli:multiblock') {
    return renderMultiblockPage(page);
  }

  if (pageType === 'tfc:multimultiblock') {
    return renderMultiMultiBlockPage(page, itemTitle);
  }

  if (tfcRecipePageTypes.has(pageType)) {
    return renderTfcRecipePage(page, itemTitle, pageType);
  }

  if (pageType === 'patchouli:empty') {
    return renderEmptyPage();
  }

  return renderRawPage(page, itemTitle, pageType);
}
