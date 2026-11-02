import { getCollection, type CollectionEntry } from 'astro:content';

export type Note = CollectionEntry<'notes'>;

/** 生产构建排除草稿，开发时保留 */
export async function allNotes(): Promise<Note[]> {
  const includeDrafts = import.meta.env.DEV;
  const notes = await getCollection('notes');
  return notes
    .filter((note) => includeDrafts || !note.data.draft)
    .sort((a, b) => b.data.date.getTime() - a.data.date.getTime());
}

/** kind → 用于 CSS 的稳定类名 */
export const kindClass: Record<string, string> = {
  一句话: 'line',
  一段话: 'para',
  小故事: 'story',
};

/** 去掉 Markdown 标记，拿到纯文本，用于列表摘要 */
export function plainText(body: string | undefined): string {
  if (!body) return '';
  return body
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/^\s{0,3}#{1,6}\s+/gm, '')
    .replace(/^\s{0,3}[-*+]\s+/gm, '')
    .replace(/^\s{0,3}>\s?/gm, '')
    .replace(/[*_`]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function noteExcerpt(note: Note, max = 80): string {
  const text = plainText(note.body);
  return text.length > max ? `${text.slice(0, max)}…` : text;
}
