# 维护手册

这个站是纯静态的：**内容是 Markdown 文件，没有数据库，没有后台**。所以「维护」只有三件事——改文件、跑构建、传上去。

```bash
npm run dev                              # 本地预览 http://localhost:4321
npm run build                            # 产出 dist/
.\deploy\deploy.ps1 -Server root@你的IP -Path /var/www/witguang   # 上传
```

---

## 1. 想改什么，改哪里

| 我想改…… | 改这个文件 | 说明 |
| --- | --- | --- |
| 写一篇新文章 | `src/content/blog/<slug>.md` | 新建文件即可，文件名就是网址 |
| 改文章标题 / 日期 / 标签 | 同一个 `.md` 顶部 frontmatter | 改完重跑构建 |
| 删一篇文章 | 删掉那个 `.md` | 同时清理不再引用的图片 |
| 写一条想法 | `src/content/notes/<日期>-<slug>.md` | 短内容，不单独成页 |
| 加 / 改 / 删项目 | `src/data/projects.ts` | 一个数组，直接编辑 |
| 改名字、简介、邮箱、导航、社交链接 | `src/site.config.ts` | 全站唯一来源 |
| 改颜色 / 字体 / 间距 | `src/styles/global.css` 顶部的 CSS 变量 | 日间和夜间两套 |
| 改首屏那句话的排版 | `src/pages/index.astro` | 首屏结构 + 样式都在这个文件 |
| 换 favicon | `public/favicon.svg` | 同名替换 |
| 换分享缩略图 | `public/og-default.svg` | 上线前建议换 1200×630 PNG |
| 关掉 / 调整 ASCII 海 | `src/pages/index.astro` + `src/lib/ocean.ts` | 见第 8 节 |
| 改域名 | `astro.config.mjs` 的 `site` | 影响 canonical / sitemap / RSS |

---

## 2. 写一篇新文章

新建 `src/content/blog/my-new-post.md`：

```markdown
---
title: 文章标题
description: 一句话摘要，会显示在列表和搜索结果里
pubDate: 2026-11-03
tags: [写作, 方法]
draft: false
---

正文从这里开始。用 Markdown 写。
```

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `title` | ✅ | 标题 |
| `description` | ✅ | 摘要，列表页和 RSS 用 |
| `pubDate` | ✅ | `YYYY-MM-DD` 或完整 ISO 时间，决定排序和显示 |
| `updatedDate` | | 有值时会显示「更新于」 |
| `tags` | | 数组，不写就是空。会自动生成标签页 |
| `draft` | | `true` 时**只在本地 dev 可见**，构建时被排除 |

**文件名 = 网址**：`my-new-post.md` → `/blog/my-new-post/`。
建议用英文小写加连字符，中文文件名能跑但网址会被百分号编码，不好看也不好分享。

常见写法：

```markdown
## 二级标题会出现在右侧目录里

```bash
# 代码块自带语法高亮，跟随日间 / 夜间主题
npm run build
```

> 引用

![图片说明](/images/screenshot.png)

[站内链接](/blog/another-post/) · [外链](https://www.witguang.com)
```

### 插图

1. 把图片放 `public/images/`（这个目录原样发布）
2. 用绝对路径引用：`![说明](/images/文件名.png)`

图片不要超过 1~2 MB，先压缩再放进去。

### 草稿的正确用法

写一半就 `draft: true`，这样线上不会有这篇，本地 `npm run dev` 依然能预览。写完改回 `false` 再部署。

---

## 3. 编辑和删除

**编辑**：直接用编辑器改 `.md`，保存后本地页面会自动刷新。
改 `pubDate` 会让文章跳到列表前面——如果只是修错别字，别动日期，要动就加 `updatedDate`。

**删除**：删掉 `src/content/blog/xxx.md`，然后 `npm run build` 一次确认没报错。
同时删掉 `public/images/` 里只有这篇文章在用的图。

⚠️ 两种会「删不干净」的情况：

- 别的文章还在链到那篇 → 会变成死链，构建**不会**报错，需要自己搜一下
- 文章网址变了（改了文件名）→ 旧链接 404。真要改，就在新地址放一篇内容相同、`title` 写「已迁移」的短文，或者接受这个代价

**删除一条想法**：同样删 `src/content/notes/xxx.md`。
**删除一个项目**：编辑 `src/data/projects.ts`，删掉对应的 `{ ... }` 对象（注意逗号）。
**清空所有项目**：把数组写成 `export const projects: Project[] = [];`，主页的「在做的事」区块会自动消失。

---

## 4. 写想法

`src/content/notes/2026-11-03-some-thought.md`：

```markdown
---
date: 2026-11-03
kind: 一句话
tags: [随想]
---

工具应该让人忘掉工具本身。
```

| 字段 | 说明 |
| --- | --- |
| `date` | 排序用，最新的在上面 |
| `kind` | 只能是 `一句话` / `一段话` / `小故事`，决定列表里的标签样式 |
| `title` | 可选，只有「小故事」建议写 |
| `tags` | 同文章 |

文件名里的前 10 位是日期，后面是短别名，合起来就是这条想法的锚点：
`#2026-11-03-some-thought`，可以单独分享。

想法按日期倒序排在 `/notes/`，主页显示最近 4 条。**不进 RSS**（想过，觉得太吵）。

---

## 5. 改个人信息

`src/site.config.ts`：

```ts
export const site = {
  name: 'witguang',
  role: '你好，我是',
  title: 'witguang · 个人网站',
  description: '……',
  tagline: '……',        // 首屏那句介绍
  intro: '……',          // 主页「关于我」那一段
  email: 'guangwit@gmail.com',
  url: 'https://www.witguang.com',
  location: '',           // 留空则不显示「坐标」这一行
  now: '',                // 留空则不显示「现在」这一行
  socials: [ ... ],
  nav: [ ... ],
};
```

`location` 和 `now` 留空就会自动从首屏消失，不用改模板。

社交链接的 `handle` 是显示文字，`href` 是跳转地址。删掉一条就少一行。

---

## 6. 改配色

`src/styles/global.css` 开头两个块，同一个变量名两套值：

```css
[data-theme='light'] {
  --bg: #faf8f4;        /* 背景 */
  --text: #16181d;      /* 正文 */
  --text-mute: #6a6f78; /* 次要文字，已校验对背景 4.7:1 */
  --accent: #b23a26;    /* 点缀色 */
}

[data-theme='dark'] {
  --bg: #07080a;
  --accent: #5eead4;
}
```

改完用浏览器开发者工具确认对比度：正文至少 4.5:1，大标题至少 3:1。
浅色主题的 `--text-mute` 别再调浅了，`#7b8089` 就不达标。

---

## 7. 本地检查清单

发之前跑一遍：

```bash
npm run dev      # 点一遍导航、文章、想法、标签、404
npm run build    # 有报错会打印 文件:行号
npm run preview  # 用 dist/ 起本地服务器，验证构建产物
```

构建失败最常见的原因：

| 报错 | 原因 |
| --- | --- |
| `Invalid Character` / YAML 相关 | frontmatter 缩进用了 Tab 或中文冒号，改用两个空格和英文 `:` |
| `pubDate` 类型错误 | 日期写成了 `2026/11/03`，要 `2026-11-03` |
| `Could not find` | import 路径大小写不对（Linux 区分大小写，Windows 不区分） |
| 页面 404 | 文件名和链接不一致，或者忘了 `npm run build` |

---

## 8. ASCII 海

三档关法，按需选：

| 想要 | 怎么做 |
| --- | --- |
| 只关主页 | 删 `src/pages/index.astro` 里的 `<OceanBackdrop />` 和 `.hero-veil`，再去掉 `.hero--ocean` 那段样式 |
| 主页留着但不自动游 | 把 `src/lib/ocean.ts` 里 `const playing = stored !== 'pause';` 改成 `const playing = false;` |
| 彻底删掉 | 删 `src/pages/sharks.astro`、`src/components/OceanBackdrop.astro`、`src/components/OceanCanvas.astro`、`src/lib/ocean.ts`、`src/ascii-sharks/`，再删页脚那行 `<li><a href="/sharks/">鲨鱼</a></li>` |

换鲨鱼：`src/pages/index.astro` 里 `<OceanBackdrop sharks="thresher,hammerhead,mako,nurse" />`，
可选 `classic` `hammerhead` `zebra` `tiger` `greathammer` `mako` `thresher` `nurse`，第一条最大。
不传就用默认四条。

这段引擎是别人的（stackedlol/ascii-sharks，MIT），我们改过 5 行让它能默认播放，改动记录在 `src/ascii-sharks/README.md`。升级上游时对着那张表改。

---

## 9. 版本管理（强烈建议现在就做）

现在这个目录**还不是 git 仓库**。内容和代码都是文件，git 就是最好的备份：

```bash
cd D:\orca\workspaces\website
git init
git add -A
git commit -m "初始版本：Astro 站点 + 文章 + 想法 + ASCII 海"
```

`.gitignore` 已经配好（`node_modules/`、`dist/`、`preview/`、`.env` 都不会进去）。

推到 GitHub 私有仓库：

```bash
git remote add origin git@github.com:witguang/website.git
git branch -M main
git push -u origin main
```

以后每次改完内容：

```bash
git add -A && git commit -m "新增：xxx" && git push
```

服务器上不放源码，所以**本地仓库 = 唯一副本**，记得推。

---

## 10. 部署：构建在 GitHub，机器只拉取

### 10.0 为什么这么改

```
本地 git push  →  GitHub Actions 构建  →  产出推到 gh-pages 分支
                                              ↓
                                     VPS: witguang-update（git pull）
```

好处：

- **VPS 不装 Node、不编译**，只需要 `git` + `nginx`，内存 256 MB 的小机器也够
- 每次构建环境一致（都是 ubuntu-latest + Node 20），不会出现"我电脑上能构建"
- 换机器就是重新 clone 一次，秒级，因为要传的只有几十 KB
- 回滚 = `git reset --hard HEAD~1`

### 10.1 仓库

源码在 `github.com/witguang/website`，`main` 是源码，`gh-pages` 是构建产物（**不要手改**）。

推送后 Actions 会自动跑 `.github/workflows/deploy.yml`：

```
取源码 → 装 Node → npm ci → npm run build → 把 dist/ 推到 gh-pages
```

看构建状态：`gh run list`，或者仓库页面的 Actions 标签。

> 仓库是公开的，意味着 `src/` 里的草稿也会被看到。要写不想公开的东西，文件名加 `_draft-` 前缀（已在 `.gitignore` 里）。

### 10.2 新机器：一条命令

```powershell
ssh root@43.128.75.128 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh
```

它做四件事：

1. 装 `nginx` + `git`
2. 写 `/etc/witguang/config` 和 `/usr/local/bin/witguang-update`
3. 首次 `git clone` 站点（`gh-pages` 分支）
4. 写 nginx 配置并 reload

**幂等**，重复跑只会覆盖配置，不会弄丢站点。

### 10.3 日常：推送 → 更新

本地：

```powershell
git add -A
git commit -m "新增：xxx"
git push
```

等 Actions 跑完（约 30 秒，`gh run watch` 可以盯着），然后在任意一台上：

```powershell
ssh root@43.128.75.128 witguang-update
```

输出：

```
→ 拉取 witguang/website@gh-pages
✓ 已更新到 3f9a1c2
  deploy: <sha>
  自检 {"site":"witguang","builtAt":"...","commit":"3f9a1c2"}
```

最后那行自检是脚本主动 `curl 127.0.0.1/version.json`——顺带验证了 nginx 是活的。

### 10.4 回滚

```powershell
ssh root@43.128.75.128 witguang-update rollback
```

退到上一个 `gh-pages` 提交。因为 `git clone --depth=20`，最多能退 19 个版本；要更久远的，先在服务器上 `git -C /var/www/witguang/current fetch --unshallow`。

> 真实事故里，"改 DNS 指向另一台"通常比回滚更快——见第 11 节。

### 10.5 TLS：用 Cloudflare 源站证书

不依赖 ACME、不需要 DNS 指向就能签，所以**每一台机器都可以提前配好 HTTPS**，切换时不会出现证书窗口。

1. Cloudflare → SSL/TLS → Origin Server → Create Certificate
2. 主机名填 `witguang.com` + `*.witguang.com`，15 年
3. 传到机器上：

```bash
mkdir -p /etc/ssl/witguang
# 本地执行：
scp origin.pem root@IP:/etc/ssl/witguang/origin.pem
scp origin.key root@IP:/etc/ssl/witguang/origin.key
# 服务器执行：
chmod 600 /etc/ssl/witguang/origin.key
```

4. 重跑 `setup-vps.sh`，自动切到 TLS 配置
5. Cloudflare 的 SSL/TLS 模式选 **Full (strict)**，开 Always Use HTTPS

⚠️ 源站证书只有 Cloudflare 认，直接访问 IP 会报证书错误——这是预期的。

---

## 11. 多台机器 / 换 VPS

每台机器都是独立的 git 检出，没有任何需要同步的状态（没有数据库、没有上传目录）。

### 加一台

```powershell
# 1. 装好（一条命令）
ssh root@150.158.10.211 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh

# 2. 更新到最新
ssh root@150.158.10.211 witguang-update

# 3. 验证（不走 DNS，直接打这台机器）
curl.exe -sS --resolve www.witguang.com:443:150.158.10.211 https://www.witguang.com/version.json
```

### 切换流量

Cloudflare 里把 **`www` 和 `@` 两条 A 记录都改成新 IP**（只改 www 会让裸域指向旧机器）。

出问题就把 IP 改回去，旧机器上的文件还在，等于天然回滚。

### 三台一起保持最新

```powershell
foreach ($ip in "43.128.75.128","150.158.10.211","204.44.121.119") {
  ssh root@$ip witguang-update
}
```

或者给每台加一个定时器（可选）：

```bash
systemctl enable --now witguang-update.timer   # 每 5 分钟拉一次
```

### 中国大陆机器的注意点

`150.158.10.211` 属于大陆节点，**域名解析到大陆 IP 需要 ICP 备案**，否则服务商可能封 80/443。
没有备案就用海外那台当主站，大陆机器只做备用（切换前记得处理备案问题）。

### 检查某台在跑哪一版

```bash
ssh root@IP witguang-update status
```

或远程：

```bash
curl -sS --resolve www.witguang.com:443:IP https://www.witguang.com/version.json
```

### 删除一台机器上的站点

```bash
rm -rf /var/www/witguang /etc/nginx/sites-{available,enabled}/witguang /etc/witguang
rm -f /usr/local/bin/witguang-update /etc/systemd/system/witguang-update.*
systemctl reload nginx
```

先改 DNS，再删。

---
## 12. 备份

| 备份什么 | 怎么做 |
| --- | --- |
| 源码和内容 | `git push`（最重要，服务器上没有源码） |
| 构建产物 | 不用备份，随时能重新构建 |
| 服务器上的历史版本 | 脚本自动留 5 个 release |
| 图片 | 在 `public/images/` 里，跟着 git 走 |

---

## 13. 常见问题

| 现象 | 排查 |
| --- | --- |
| 部署成功但页面没变 | Cloudflare 缓存 → Purge；或本地 `curl -I https://域名/` 看 `cf-cache-status` |
| 403 Forbidden | `/var/www/witguang/current` 软链坏了，或 nginx `root` 指错 |
| 404 但文件在 | 路径大小写；或 `try_files` 少了 `$uri/` |
| 样式全丢 | `/_astro/` 路径 404，检查 `base` 配置和 nginx 的 `_astro` location |
| certbot 失败 | DNS 还是橙云，改成灰云再试 |
| 手机上横向滚动 | 新增内容撑破了容器，检查长代码块/长链接/表格 |
| 图片不显示 | 路径要以 `/` 开头（`/images/x.png`），不是相对路径 |