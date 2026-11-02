// 站点全局配置：改这一个文件就能换掉站点的身份信息
export const site = {
  /** 名字，出现在头部、页脚和主页大标题 */
  name: 'witguang',
  /** 名字上方的小字，像一句开场白 */
  role: '你好，我是',
  /** 站点标题，用于 <title> 与 RSS */
  title: 'witguang · 个人网站',
  /** 默认 SEO 描述，也是页脚那句说明 */
  description: 'witguang 的个人网站，记录技术笔记、读书笔记和一些日常想法。',
  /** 主页大标题下的一句话 */
  tagline: '写代码，读书，把想清楚的事情记下来。',
  /** 主域名，结尾不要带斜杠 */
  url: 'https://www.witguang.com',
  /** 关于页开头的一段自我介绍 */
  intro:
    '我是 witguang。这里放技术笔记、读书笔记，和那些写下来才想清楚的事情。',
  email: 'guangwit@gmail.com',
  /** 可选的「坐标」「现在」：留空就不显示 */
  location: '',
  now: '',
  socials: [
    { label: 'GitHub', href: 'https://github.com/witguang', handle: 'witguang' },
    { label: 'X', href: 'https://x.com/wit_guang', handle: '@wit_guang' },
    { label: '邮件', href: 'mailto:guangwit@gmail.com', handle: 'guangwit@gmail.com' },
  ],
  nav: [
    { label: '文章', href: '/blog/' },
    { label: '想法', href: '/notes/' },
    { label: '项目', href: '/projects/' },
    { label: '关于', href: '/about/' },
  ],
} as const;
