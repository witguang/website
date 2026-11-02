---
title: 静态站的 Nginx 配置：我踩过的五个点
description: 从 try_files 到缓存策略、从 404 到 Cloudflare 回源，一份能直接用的静态站配置和它背后的原因。
pubDate: 2026-10-05
tags: ['部署', 'Nginx']
---

静态站部署听起来没什么可配的：把 `dist/` 扔进目录，指向它，完事。但真到上线那一步，我在这五个地方各卡过一次。

## 一、try_files 的写法

Astro 默认按目录输出，`/blog/foo/` 对应 `blog/foo/index.html`。如果只写 `try_files $uri =404`，访问 `/blog/foo/` 会 404，因为文件系统里没有叫 `foo` 的文件。

正确的写法是让 `$uri/` 去找目录下的索引：

```nginx
location / {
    try_files $uri $uri/ =404;
}

index index.html;
```

## 二、404 要单独指定

`=404` 会返回 Nginx 自带的错误页，跟站点风格完全不搭。想用自己做的 404 页面：

```nginx
error_page 404 /404.html;
location = /404.html {
    internal;
}
```

`internal` 这句别省，否则别人可以直接访问 `/404.html`，搜索引擎也可能把它当正文收录。

## 三、带哈希的资源要长缓存

Astro 会把 JS/CSS 输出到 `_astro/` 下，文件名带内容哈希。这类文件可以放心缓存一年：

```nginx
location /_astro/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

但 HTML 不能这么干，否则改完文章用户看不到。静态站最省心的策略是：**HTML 不缓存或短缓存，带哈希的资源长缓存。**

## 四、Cloudflare 代理后要开 Full (strict)

这是我吃亏最多的一次。域名挂了 Cloudflare 的小云朵（代理模式）后，如果 SSL/TLS 模式选了 Flexible，Cloudflare 用 HTTP 回源，而源站又强制跳 HTTPS，就会无限重定向，浏览器报 `ERR_TOO_MANY_REDIRECTS`。

正确做法是让源站也有证书（`certbot --nginx` 一行就够），Cloudflare 侧设成 **Full (strict)**。这时日志里看到的全是 Cloudflare 的 IP，想拿真实 IP 需要装 `ngx_http_realip_module` 并信任 Cloudflare 的网段。

## 五、gzip 默认只压一部分类型

Nginx 默认的 `gzip_types` 不包含 `application/json` 和 `image/svg+xml`，RSS 和 sitemap 这类 XML 反而默认有。我习惯显式列全：

```nginx
gzip on;
gzip_comp_level 5;
gzip_min_length 1024;
gzip_types text/plain text/css application/javascript application/json
           application/xml image/svg+xml;
gzip_vary on;
```

## 完整的一段

把上面拼起来，一个静态站的 server 块大概长这样（证书路径由 certbot 自动写入）：

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/site;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /_astro/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    error_page 404 /404.html;
    location = /404.html { internal; }
}
```

配置改完记得 `nginx -t` 再 `systemctl reload nginx`。直接 reload 一个语法错误的配置，站点会立刻挂掉，而这时候你往往正在 SSH 外面。
