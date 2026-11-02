/**
 * 标签 → URL slug。
 * 中文标签直接做目录名在跨平台构建时容易出编码问题，所以统一映射成 ASCII。
 * 新增常用标签时，在这里补一行就能得到更可读的地址（否则走稳定性哈希兜底）。
 */
const slugMap: Record<string, string> = {
  随想: 'notes',
  写作: 'writing',
  阅读: 'reading',
  思考: 'thinking',
  观察: 'observation',
  方法: 'method',
  前端: 'frontend',
  工程: 'engineering',
  部署: 'deploy',
  设计: 'design',
  工具: 'tools',
  Astro: 'astro',
  Nginx: 'nginx',
  TypeScript: 'typescript',
};

export function tagSlug(tag: string): string {
  const mapped = slugMap[tag];
  if (mapped) return mapped;
  if (/^[a-zA-Z0-9-]+$/.test(tag)) return tag.toLowerCase();
  let hash = 0;
  for (let i = 0; i < tag.length; i += 1) {
    hash = (hash * 31 + tag.charCodeAt(i)) >>> 0;
  }
  return `t-${hash.toString(36)}`;
}
