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

## 9. 版本管理

源码在 `github.com/witguang/website`（公开仓库）。**本地仓库是唯一副本**，每次改完记得推：

```bash
git add -A
git commit -m "新增：xxx"
git push
```

推送会同时触发构建（见第 10 节），所以 `git push` 之后等 Actions 跑完，再去服务器更新即可。

`.gitignore` 保证这些东西不会进仓库：`node_modules/`、`dist/`、`preview/`、`.codex-home/`、`_draft-*.md`。

> 想把草稿留在本地不公开：文件名加 `_draft-` 前缀，它会被忽略。
> 注意仓库是公开的，`src/` 下所有已提交的内容都能被看到。

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

### 10.1.1 本地推送需要走代理

`git` 不读 Windows 的「Internet 选项」代理，直连 github.com 会超时。本仓库已经设好：

```powershell
git config http.proxy http://127.0.0.1:10808
git config https.proxy http://127.0.0.1:10808
```

（代理端口换成你自己的；只影响这个仓库，不动全局配置。）

### 10.2 前提：能免密登录

第一次需要把本机公钥装上，三个 IP 一起做（每个 IP 输一次密码）：

```powershell
foreach ($ip in "43.128.75.128","150.158.10.211","204.44.121.119") {
  type "$env:USERPROFILE\.ssh\id_ed25519.pub" |
    ssh -o StrictHostKeyChecking=accept-new "root@$ip" `
      "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && echo OK"
}
```

之后 `ssh root@IP "echo ok"` 不再问密码。想确认哪台通：

```powershell
foreach ($ip in "43.128.75.128","150.158.10.211","204.44.121.119") {
  "{0,-16} {1}" -f $ip, (try { ssh -o BatchMode=yes -o ConnectTimeout=6 "root@$ip" "echo 通" 2>&1 } catch { "不通" })
}
```

### 10.3 新机器：一条命令


```powershell
ssh root@43.128.75.128 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh
```

它做四件事：

1. 装 `nginx` + `git`
2. 写 `/etc/witguang/config` 和 `/usr/local/bin/witguang-update`
3. 首次 `git clone` 站点（`gh-pages` 分支）
4. 写 nginx 配置并 reload

**幂等**，重复跑只会覆盖配置，不会弄丢站点。

### 10.4 日常：推送 → 更新

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

### 10.5 回滚

```powershell
ssh root@43.128.75.128 witguang-update rollback
```

退到上一个 `gh-pages` 提交。因为 `git clone --depth=20`，最多能退 19 个版本；要更久远的，先在服务器上 `git -C /var/www/witguang/current fetch --unshallow`。

> 真实事故里，"改 DNS 指向另一台"通常比回滚更快——见第 11 节。

### 10.6 证书与回源：源站不需要证书

最终架构是 **EdgeOne 在前面终止 TLS，回源走 HTTP**，所以源站上**没有证书**，也不用续期。

```
浏览器 --HTTPS--> EdgeOne(自动证书) --HTTP:80--> 源站 nginx
```

这也是为什么之前纠结的「Cloudflare 源站证书」被弃用：EdgeOne 不信任 Cloudflare 的私有 CA。
只有当你想绕过 CDN 直连源站时才需要证书，那时签 Let's Encrypt（DNS-01，不需要域名指向）。

> HTTP 回源意味着 EdgeOne 到新加坡源站这一段是明文。静态公开内容无所谓；
> 以后要放私密内容，再给源站上证书并把回源协议改成 HTTPS。

### 10.7 装在「已经跑着别的站」的机器上

`43.128.75.128` 就是这种情况：它有 `grok / sms / todo / tools / files` 等一堆子站在跑，
`/etc/nginx/conf.d/` 一域名一个文件，证书在 `/etc/nginx/ssl/`。

脚本默认**只加自己一份，不动别人**：

- 配置写到 `/etc/nginx/conf.d/witguang.conf`，同名文件先备份成 `.bak-<时间戳>`
- **不删** `sites-enabled/default`（那是其它站的兜底）
- 站点目录 `/var/www/witguang/current` 独立

配置文件名冲突就换：`--name witguang-main`。

---

## 11. 上线：EdgeOne 接入

### 11.0 现状与取舍

- 域名 `witguang.com` 的 NS 在 Cloudflare
- EdgeOne 上已有站点，`dsh.witguang.com` 在跑（CNAME → `dsh.witguang.com.eo.dnse0.com`）
- **不做 ICP 备案** → 加速区域只能选「全球可用区（不含中国大陆）」，大陆用户走海外节点

不做备案的后果要清楚：**大陆用户不会就近接入国内节点**，延迟和走 Cloudflare 差不多。
EdgeOne 在这里的价值是「稳定、有 SLA、和现有站点统一」，不是「大陆加速」。
真要大陆加速，只能备案。

### 11.1 源站

| 项 | 值 |
| --- | --- |
| 源站地址 | `43.128.75.128`（新加坡） |
| 端口 | `80` |
| 回源协议 | **HTTP** |
| 回源 Host | 跟随加速域名（`www.witguang.com`） |

源站 nginx 已就绪：`www` 返回 200，裸域 301 到 www。

### 11.2 在 EdgeOne 加加速域名

控制台 → 站点 `witguang.com` → 域名管理 → 添加域名：

- `www.witguang.com`（主站）
- `witguang.com`（裸域，源站会 301 到 www）

加速区域选「全球可用区（不含中国大陆）」，证书用「免费证书」自动签发。
添加后会给出 CNAME，形如 `www.witguang.com.eo.dnse0.com`（以控制台显示为准）。

### 11.3 DNS：CNAME 到 EdgeOne，**必须是灰云**

| 类型 | 名称 | 内容 | 代理 |
| --- | --- | --- | --- |
| CNAME | `www` | `<控制台给的 CNAME>` | **仅 DNS（灰云）** |
| CNAME | `@` | `<控制台给的 CNAME>` | **仅 DNS（灰云）** |

为什么必须灰云：橙云会让 Cloudflare 也参与代理，变成「CF → EO → 源站」双重 CDN，
回源 IP 混乱、缓存打架、TLS 链出错。**前面已经有 EdgeOne，Cloudflare 就只当 DNS 用。**

Cloudflare 支持根域 CNAME 打平（CNAME flattening），所以 `@` 填 CNAME 没问题。

### 11.4 验证

```powershell
# 1. DNS 是否指到 EdgeOne
Resolve-DnsName www.witguang.com | Select-Object Type,NameHost,IPAddress

# 2. 响应头里应该出现 EdgeOne 的标记
curl.exe -sSI https://www.witguang.com/ | Select-String 'eo-|server'

# 3. 版本是否与仓库一致
curl.exe -sS https://www.witguang.com/version.json

# 4. 裸域是否 301
curl.exe -sSI https://witguang.com/ | Select-String 'HTTP/|location'
```

### 11.5 多台机器（暂时只有一台在线上）

不备案的情况下，**大陆那台 `150.158.10.211` 不能对外提供 80/443**，只做备用。

以后再上机器：

```powershell
# 用 bash 的重定向，不要用 PowerShell 管道（会多塞一个 CR 进去）
& "C:\Program Files\Git\bin\bash.exe" -c `
  "ssh root@新IP 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh"

ssh root@新IP witguang-update
```

接到 EdgeOne 的「源站组」里，可以用规则引擎按地域分流（备案后再开国内源站）：

```
IF 客户端地理位置 = 中国大陆境内 → 源站 A（大陆）
ELSE                              → 源站 B（新加坡）
```

### 11.6 排错

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `git push` 卡住后超时 | 没走代理 | 见 10.1.1 |
| Actions 报 `Node.js is not supported by Astro` | CI 的 Node 版本低 | 工作流里已是 22，别动 |
| `witguang-update` 报 `couldn't find remote ref gh-pages` | 还没构建过 | `gh run list` 等第一次成功 |
| 访问域名 418 | 请求没匹配到加速域名 | 检查 EO 里域名状态、CNAME 是否正确 |
| 访问域名 404 但源站正常 | 回源 Host 不对 | 回源 Host 设为「跟随加速域名」 |
| 访问域名 5xx | 源站 80 不通 | `ssh root@IP curl -I -H 'Host: www.witguang.com' http://127.0.0.1/` |
| 证书报错 | 直连了源站 IP | 正常，源站没证书；走域名 |
| 更新后页面没变 | CDN 缓存 | EO 控制台刷新缓存 |
| 大陆机器拉取 GitHub 慢 | 网络 | 多试；或用另一台 `git bundle` 过去 |
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