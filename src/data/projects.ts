export type Project = {
  name: string;
  summary: string;
  stack: string[];
  status: '进行中' | '已上线' | '维护中' | '归档';
  featured?: boolean;
  links?: { label: string; href: string }[];
};

export const projects: Project[] = [
  {
    name: '笔记工具 LocalNote',
    summary:
      '本地优先的 Markdown 笔记应用，数据存在浏览器 IndexedDB 与本地文件夹，支持双向链接和全文检索。',
    stack: ['TypeScript', 'Svelte', 'IndexedDB'],
    status: '进行中',
    featured: true,
  },
  {
    name: '静态站点脚手架',
    summary:
      '一套 Astro + Nginx 的极简部署模板，一条命令完成构建、上传和回滚，用在自己的几个小站上。',
    stack: ['Astro', 'Shell', 'Nginx'],
    status: '维护中',
    featured: true,
  },
  {
    name: '读书笔记检索',
    summary:
      '把散落在各处的读书笔记汇总成可检索的索引，按主题聚合并生成年度回顾。',
    stack: ['Python', 'SQLite', 'FastAPI'],
    status: '已上线',
  },
  {
    name: '早年的博客主题',
    summary: '第一次自己写 CSS 的产物，保留下来当作纪念，已不再维护。',
    stack: ['HTML', 'CSS'],
    status: '归档',
  },
];
