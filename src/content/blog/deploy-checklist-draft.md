---
title: 上线清单（草稿）
description: 一篇还在写、只在本地可见的草稿，用来验证 draft 机制。
pubDate: 2026-11-01
tags: ['部署']
draft: true
---

这篇是草稿示例，`draft: true`。

- `npm run dev` 时它会出现在列表里，带一个「草稿」角标
- `npm run build` 时它不会进入产物，线上地址直接 404

写完之后把 `draft: true` 删掉，就会随下次部署一起上线。

## 待补

- DNS 切换前后的检查项
- 证书续期验证方式
- 回滚步骤
