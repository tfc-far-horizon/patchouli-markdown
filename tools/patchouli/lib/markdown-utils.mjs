import YAML from 'yaml';

export function patchouliTextToMarkdown(text) {
  const normalized = text
    .replaceAll('$(br2)', '\n\n')
    .replaceAll('$(br)', '\n')
    .replace(/\$\(l:([^)]+)\)(.*?)\$\(\)/g, (_, target, label) => {
      return `[${escapeLinkText(label)}](${target})`;
    })
    .replace(/\$\(bold\)(.*?)\$\(\)/g, '^$1^')
    .replaceAll('$', '\\$');

  return normalized.split('\n');
}

export function patchouliTitleToMarkdown(title) {
  return patchouliTextToMarkdown(title).join(' ');
}

export function fenced(language, value) {
  const content = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
  return `\`\`\`${language}\n${content}\n\`\`\``;
}

export function emptyFenced(language) {
  return `\`\`\`${language}\n\`\`\``;
}

export function yamlFenced(language, value) {
  const content = YAML.stringify(value, {
    lineWidth: 0,
    singleQuote: false,
  }).trimEnd();
  return `\`\`\`${language}\n${content}\n\`\`\``;
}

export function stringifyYaml(value) {
  return YAML.stringify(value, {
    lineWidth: 0,
    singleQuote: false,
  }).trimEnd();
}

export function orderKeys(object, preferredKeys) {
  const ordered = {};
  for (const key of preferredKeys) {
    if (Object.hasOwn(object, key)) ordered[key] = object[key];
  }
  for (const key of Object.keys(object)) {
    if (!Object.hasOwn(ordered, key)) ordered[key] = object[key];
  }
  return ordered;
}

export function indent(line) {
  if (line === '') return '\t';
  return line
    .split('\n')
    .map((part) => `\t${part}`)
    .join('\n');
}

export function inlineCode(text) {
  return `\`${String(text).replaceAll('`', '\\`')}\``;
}

export function hasOwnText(value) {
  return value !== undefined && value !== null && value !== '';
}

export function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function escapeLinkText(text) {
  return String(text).replaceAll('[', '\\[').replaceAll(']', '\\]');
}
