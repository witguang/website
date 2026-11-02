---
title: 用内容集合管理博客：Astro 5 的写法
description: 从零配一个带类型校验的博客内容集合，顺便说清 id、slug 和渲染方式在 Astro 5 里的变化。
pubDate: 2026-10-19
tags: ['Astro', '前端']
---

Astro 5 把内容集合的配置从 `src/content/config.ts` 挪到了 `src/content.config.ts`，同时引入 loader 概念——内容可以来自本地 Markdown，也可以来自 API 或数据库。对博客来说，变化最大的是 **id 现在是 slug，不再是 `slug` 字段**。

## 配置一个集合

先建内容目录 `src/content/blog/`，然后在 `src/content.config.ts` 里声明：

```ts
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
```

`z.coerce.date()` 这个细节值得强调：YAML 里的 `2026-10-19` 会被解析成字符串，直接 `z.date()` 会在构建时报错。

## id 与 slug

在 Astro 4 里要自己维护一个 `slug` 字段。Astro 5 之后，文件名就是 id：

```
src/content/blog/why-own-website.md  →  id: "why-own-website"
```

路由里直接拿它拼地址，不用再担心两者不一致：

```ts
export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map((post) => ({ params: { slug: post.id } }));
}
```

## 渲染

`entry.render()` 被移到了 `astro:content` 的 `render` 函数上，返回值多了一个 `headings`，正好用来生成目录：

```ts
import { render } from 'astro:content';

const { Content, headings } = await render(post);
```

`headings` 里每项带 `depth`、`slug` 和 `text`，过滤 `depth <= 2` 就是一个像样的 TOC，不需要再引额外的插件。

## 草稿的处理

我不喜欢「本地看到草稿、线上看不到」这种差异靠人记。让构建自己判断更稳：

```ts
const includeDrafts = import.meta.env.DEV;
const posts = all.filter((post) => includeDrafts || !post.data.draft);
```

这样 `npm run dev` 时草稿带一个角标出现在列表里，`npm run build` 时直接从产物里消失。

## 一句提醒

内容集合的 schema 是构建期校验，不是运行时。写错 frontmatter 时构建会失败并指出是哪个文件哪一行——这比页面白屏后去翻控制台舒服得多，也是我坚持用它的主要原因。
