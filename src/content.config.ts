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
    /** 草稿只在本地 dev 可见，build 时会被排除 */
    draft: z.boolean().default(false),

  }),
});

/** 想法：一句话、一段话，或者一个小故事。短内容，不进 RSS、不单独成页 */
const notes = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/notes' }),
  schema: z.object({
    date: z.coerce.date(),
    /** 决定列表里的标签样式，也提示读者这条大概多长 */
    kind: z.enum(['一句话', '一段话', '小故事']).default('一段话'),
    /** 只有小故事需要标题 */
    title: z.string().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog, notes };
