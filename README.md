# 个人网站

[![构建并发布](https://github.com/witguang/website/actions/workflows/deploy.yml/badge.svg)](https://github.com/witguang/website/actions/workflows/deploy.yml)

Astro 静态站：主页 + 博客 + 项目 + 关于。构建产物是纯静态文件，可托管在任意静态服务器或 Nginx 上。

> 日常维护（写文章、删内容、上传、回滚、排错）看 **[MAINTENANCE.md](MAINTENANCE.md)**，这份 README 只讲结构。

## 本地开发

```bash
npm install       # 首次
npm run dev       # http://localhost:4321，带热更新
npm run build     # 产物输出到 dist/
npm run preview   # 本地预览构建产物
```

## 我要改哪里

| 想改的东西 | 改这个文件 |
| --- | --- |
| 名字、简介、邮箱、社交链接、导航 | `src/site.config.ts` |
| 写新文章 | `src/content/blog/` 下新建 `.md` |
| 写一条想法 | `src/content/notes/` 下新建 `.md` |
| 项目清单 | `src/data/projects.ts` |
| ASCII 海的鲨鱼阵容 | `src/components/OceanCanvas.astro` 的 `sharks` 参数 |
| 关于页正文 | `src/pages/about.astro` |
| 配色、字体、间距 | `src/styles/global.css` |
| 站点域名（RSS / sitemap 用） | `astro.config.mjs` 里的 `site` |
| 标签的中文名 → 网址 | `src/lib/tags.ts` |

## 写文章

在 `src/content/blog/` 新建文件，文件名会成为网址：`my-post.md` → `/blog/my-post/`。

```markdown
---
title: 标题
description: 一句话摘要，会用作列表描述和 SEO 描述
pubDate: 2026-11-02
tags: ['随想', '写作']
featured: false   # 是否在主页「精选」出现
draft: false      # true 时只在本地可见，构建产物里没有
---

正文……
```

标签页会自动生成：`/tags/<slug>/`。中文标签的 slug 映射在 `src/lib/tags.ts`，没配的标签会得到一个稳定的短哈希地址。

## 写想法

「想法」是短内容流：一句话、一段话，或者一个比喻小故事，全部展示在 `/notes/` 一条时间线上，不单独成页。

在 `src/content/notes/` 新建 `.md`，**文件名就是这条想法的锚点**：`2026-11-02-explain-to-outsider.md` → `/notes/#2026-11-02-explain-to-outsider`。

```markdown
---
date: 2026-11-02
kind: 一句话        # 一句话 / 一段话 / 小故事
title: 只有小故事才需要标题
tags: ['思考']
draft: false
---

正文。一句话就写一句，一段话就写一段，不用凑长度。
```

`kind` 只影响列表里的分类标签和样式，不限制长度——但请诚实填，读者是照着这个预期点进来的。主页会显示最近 4 条，`/notes/` 显示全部。

## 日间 / 夜间主题

站点有两套主题，头部右上角的太阳 / 月亮按钮切换，默认日间，选择记在 `localStorage`（键名 `site-theme`）：

- **日间（light）**：暖白底 `#faf8f4`、朱红点缀 `#b23a26`、正文宋体、细分隔线
- **夜间（dark）**：近黑底 `#07080a`、青绿高亮 `#5eead4`、等宽标签、卡片微光

两套主题共用同一份 DOM，只是 `[data-theme='light'|'dark']` 下的 CSS 变量不同。首屏绘制前会由内联脚本套上已选主题，不会闪白再变黑；`?theme=dark` 或 `?theme=light` 可以直接指定并记住。

## 待办

- [x] 换成真实姓名、社交链接（witguang / guangwit@gmail.com）
- [ ] 确认简介与标签文案（`src/site.config.ts` 的 `role` / `tagline` / `intro`）
- [ ] 项目页现在是 4 个示例项目，需要换成真实的或清空
- [x] `astro.config.mjs` 的 `site` 已设为 `https://www.witguang.com`（裸域由 Nginx 301 过来）
- [ ] OG 图片：目前是 `public/og-default.svg`，多数社交平台不支持 SVG，上线前换成 1200×630 的 PNG
- [ ] （可选）首次访问跟随 `prefers-color-scheme`（现在固定默认日间）
- [ ] （可选）Giscus 评论、访问统计

## ASCII 海

`/sharks/` 是一片用字符画的海洋，来自 [stackedlol/ascii-sharks](https://github.com/stackedlol/ascii-sharks)（MIT）。源码以副本形式放在 `src/ascii-sharks/`，逻辑没改，见该目录下的 `README.md` 与 `LICENSE`。

- 两个组件，共用 `src/lib/ocean.ts` 的挂载逻辑（每块画布只挂一次，`pagehide` 统一销毁）：
  - `OceanBackdrop.astro`：铺满父容器的背景层，用在主页首屏
  - `OceanCanvas.astro`：带边框的独立一块，参数 `height` / `sharks` / `caption` / `href`，用在 `/sharks/`
- 主页首屏是一块固定深色的「舷窗」（`#06080b`），画布 `z-index: 0`、文字层 `z-index: 1`，中间那层 `linear-gradient` 压暗左侧和底部——鱼从右边亮处游过，不挡字。日间主题的点缀色换成暖橘 `#ff7a5c`，夜间用青绿 `#5eead4`
- 鲨鱼阵容用逗号分隔的 kind：`classic` `hammerhead` `zebra` `tiger` `greathammer` `mako` `thresher` `nurse`，第一条最大，依次递减
- **默认播放**，即使系统开了「减少动态效果」也照游（这是刻意的选择：静态的海看起来像坏了）。右下角有个小开关可以暂停，选择记在 `localStorage` 的 `ocean-motion`（`play` / `pause`），刷新后保持
- 引擎自带 `IntersectionObserver`：滚出视口自动暂停，不占 CPU
- 不想要首屏的海：删掉 `src/pages/index.astro` 里的 `<OceanBackdrop />` 和 `.hero-veil`，再把 `.hero--ocean` 那段样式去掉即可，`/sharks/` 不受影响

## 部署

构建在 GitHub 上做，机器只负责拉取——VPS 不装 Node、不编译。

```
本地 git push → GitHub Actions 构建 → 推到 gh-pages 分支
                                          ↓
                              VPS: witguang-update（git pull）
```

| 动作 | 命令 |
| --- | --- |
| 新机器初始化（装 nginx + 建检出 + 写配置） | `ssh root@IP 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh` |
| 日常更新 | `ssh root@IP witguang-update` |
| 回滚 | `ssh root@IP witguang-update rollback` |
| 看当前版本 | `ssh root@IP witguang-update status` |

- 工作流：`.github/workflows/deploy.yml`（push 到 `main` 触发）
- 构建指纹：`/version.json` 里有 `commit` 和 `builtAt`，用来核对线上是哪一版
- TLS 用 Cloudflare 源站证书（15 年，可提前铺到每台机器，切换无证书窗口）
- 站点目录就是一个 git 检出，删掉重来也只要两分钟

多机、换 DNS、备案注意事项见 [MAINTENANCE.md](MAINTENANCE.md) 第 10、11 节。