#!/usr/bin/env bash
# 把一台全新的 Debian/Ubuntu 变成「能自动更新」的站点机器。幂等，可以重复执行。
#
# 新机器，一条命令：
#   ssh root@43.128.75.128 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh
#
# 装好之后，日常更新也是一条命令：
#   ssh root@43.128.75.128 witguang-update
#
# 参数：
#   --domain   主域名（默认 www.witguang.com）
#   --apex     裸域，301 到主域名（默认 witguang.com，传 none 关掉）
#   --path     站点目录（默认 /var/www/witguang/current，是一个 git 检出）
#   --repo     GitHub 仓库（默认 witguang/website）
#   --tls      origin（默认，Cloudflare 源站证书）| http
#   --cert / --key  源站证书路径
set -euo pipefail

DOMAIN="www.witguang.com"
APEX="witguang.com"
DIR="/var/www/witguang/current"
REPO="witguang/website"
BRANCH="gh-pages"
TLS="origin"
CERT="/etc/ssl/witguang/origin.pem"
KEY="/etc/ssl/witguang/origin.key"

while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --apex)   APEX="$2"; shift 2 ;;
    --path)   DIR="$2"; shift 2 ;;
    --repo)   REPO="$2"; shift 2 ;;
    --tls)    TLS="$2"; shift 2 ;;
    --cert)   CERT="$2"; shift 2 ;;
    --key)    KEY="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 1 ;;
  esac
done

[ "$(id -u)" = "0" ] || { echo "需要 root 权限运行" >&2; exit 1; }

say() { printf '\n\033[36m→ %s\033[0m\n' "$*"; }
warn() { printf '\033[33m  %s\033[0m\n' "$*"; }

say "装 nginx / git"
if ! command -v nginx >/dev/null || ! command -v git >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq nginx git curl ca-certificates >/dev/null
fi
echo "  $(nginx -v 2>&1) · $(git --version)"

say "装更新脚本 /usr/local/bin/witguang-update"
mkdir -p /etc/witguang
cat > /etc/witguang/config <<EOF
REPO=$REPO
BRANCH=$BRANCH
DIR=$DIR
EOF

cat > /usr/local/bin/witguang-update <<'UPDATER'
#!/usr/bin/env bash
# 拉取 GitHub Actions 构建好的静态站并切换过去。
#   witguang-update            更新到最新
#   witguang-update rollback   退回上一个版本
#   witguang-update status      看当前版本 / 自检
set -euo pipefail

[ -f /etc/witguang/config ] && . /etc/witguang/config
REPO="${REPO:-witguang/website}"
BRANCH="${BRANCH:-gh-pages}"
DIR="${DIR:-/var/www/witguang/current}"
DEPTH=20
URL="https://github.com/${REPO}.git"

# 同一个时间只允许一个更新在跑
exec 9>/var/lock/witguang-update.lock
flock -n 9 || { echo "另一个更新正在运行，跳过"; exit 0; }

status() {
  if [ ! -d "$DIR/.git" ]; then echo "还没有检出：$DIR"; return 1; fi
  echo "目录   $DIR"
  echo "仓库   $REPO@$BRANCH"
  echo "版本   $(git -C "$DIR" rev-parse --short HEAD)  ·  $(git -C "$DIR" log -1 --format='%cd' --date=format:'%Y-%m-%d %H:%M')"
  echo "提交   $(git -C "$DIR" log -1 --format=%s)"
  echo -n "自检   "
  curl -fsS --max-time 5 http://127.0.0.1/version.json 2>/dev/null || echo "（nginx 没响应，检查 systemctl status nginx）"
}

update() {
  mkdir -p "$(dirname "$DIR")"

  if [ ! -d "$DIR/.git" ]; then
    echo "→ 首次检出 $URL ($BRANCH)"
    rm -rf "$DIR"
    git clone --depth=$DEPTH --branch "$BRANCH" "$URL" "$DIR"
  else
    echo "→ 拉取 $REPO@$BRANCH"
    git -C "$DIR" fetch --depth=$DEPTH origin "$BRANCH"
    git -C "$DIR" reset --hard "origin/$BRANCH"
    # 清掉上一版残留的文件（比如删掉的文章）
    git -C "$DIR" clean -fd
  fi

  echo "✓ 已更新到 $(git -C "$DIR" rev-parse --short HEAD)"
  echo "  $(git -C "$DIR" log -1 --format=%s)"
  echo -n "  自检 "
  curl -fsS --max-time 5 http://127.0.0.1/version.json 2>/dev/null || echo "nginx 未响应"
}

rollback() {
  [ -d "$DIR/.git" ] || { echo "还没有检出，没法回滚"; exit 1; }
  local prev
  prev=$(git -C "$DIR" rev-parse --short HEAD)
  git -C "$DIR" reset --hard HEAD~1
  echo "✓ 已回滚 $prev → $(git -C "$DIR" rev-parse --short HEAD)"
}

case "${1:-update}" in
  update)   update ;;
  rollback) rollback ;;
  status)   status ;;
  *) echo "用法：witguang-update [update|rollback|status]" >&2; exit 1 ;;
esac
UPDATER
chmod +x /usr/local/bin/witguang-update
ln -sfn /usr/local/bin/witguang-update /usr/local/bin/witguang-deploy

say "首次同步 $REPO@$BRANCH"
if ! /usr/local/bin/witguang-update; then
  warn "拉取失败——仓库里可能还没有 gh-pages 分支（GitHub Actions 还没跑过）。"
  warn "先放一个占位页，等 Actions 完成后执行 witguang-update 即可。"
  mkdir -p "$DIR"
  printf '<!doctype html><meta charset="utf-8"><title>witguang</title><p>等待首次发布。\n' > "$DIR/index.html"
fi

# ── TLS ───────────────────────────────────────────────────
USE_TLS=0
if [ "$TLS" = "origin" ]; then
  if [ -f "$CERT" ] && [ -f "$KEY" ]; then
    USE_TLS=1
  else
    warn "没找到源站证书：$CERT / $KEY"
    warn "从 Cloudflare 导出后放上去，再重跑本脚本即可切换到 HTTPS。本次先配 HTTP。"
  fi
fi

say "写 nginx 配置（TLS=$([ "$USE_TLS" = 1 ] && echo origin || echo off)）"
CONF=/etc/nginx/sites-available/witguang
BODY=$(cat <<EOF
    root $DIR;
    index index.html;
    charset utf-8;

    location /_astro/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        try_files \$uri =404;
    }

    location ~* \.(?:svg|png|jpe?g|webp|avif|gif|ico|woff2?)\$ {
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
        try_files \$uri =404;
    }

    location = /version.json {
        add_header Cache-Control "no-store";
        try_files \$uri =404;
    }

    location / {
        try_files \$uri \$uri/ =404;
        add_header Cache-Control "no-cache";
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml application/javascript application/json application/xml image/svg+xml;

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
EOF
)

if [ "$USE_TLS" = 1 ]; then
  {
    echo "# 由 deploy/setup-vps.sh 生成，可重复执行覆盖"
    echo "server {"
    echo "    listen 80;"
    echo "    listen [::]:80;"
    echo "    server_name $DOMAIN${APEX:+ $APEX};"
    echo "    return 301 https://$DOMAIN\$request_uri;"
    echo "}"
    if [ -n "$APEX" ] && [ "$APEX" != "none" ]; then
      echo
      echo "server {"
      echo "    listen 443 ssl http2;"
      echo "    listen [::]:443 ssl http2;"
      echo "    server_name $APEX;"
      echo "    ssl_certificate     $CERT;"
      echo "    ssl_certificate_key $KEY;"
      echo "    return 301 https://$DOMAIN\$request_uri;"
      echo "}"
    fi
    echo
    echo "server {"
    echo "    listen 443 ssl http2;"
    echo "    listen [::]:443 ssl http2;"
    echo "    server_name $DOMAIN;"
    echo "    ssl_certificate     $CERT;"
    echo "    ssl_certificate_key $KEY;"
    echo "    ssl_protocols TLSv1.2 TLSv1.3;"
    echo "$BODY"
    echo '    add_header Strict-Transport-Security "max-age=31536000" always;'
    echo "}"
  } > "$CONF"
else
  {
    echo "# 由 deploy/setup-vps.sh 生成（纯 HTTP），可重复执行覆盖"
    echo "server {"
    echo "    listen 80;"
    echo "    listen [::]:80;"
    echo "    server_name $DOMAIN${APEX:+ $APEX};"
    echo "$BODY"
    echo "}"
  } > "$CONF"
fi

say "启用站点"
ln -sfn "$CONF" /etc/nginx/sites-enabled/witguang
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx >/dev/null 2>&1 || true
systemctl reload nginx

IP=$(curl -s --max-time 5 https://api.ipify.org || echo "本机IP")
say "就绪"
echo "  公网 IP   $IP"
echo "  站点目录  $DIR"
echo "  更新命令  witguang-update"
if [ "$USE_TLS" = 1 ]; then
  echo "  自检      curl -sS --resolve $DOMAIN:443:$IP https://$DOMAIN/version.json"
else
  echo "  自检      curl -sS http://$IP/version.json"
fi
