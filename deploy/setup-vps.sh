#!/usr/bin/env bash
# 在一台 Debian/Ubuntu 上把站点跑起来。幂等，可重复执行。
#
# 新机器，一条命令：
#   ssh root@IP 'bash -s -- --domain www.witguang.com' < deploy/setup-vps.sh
#
# 装好之后，日常更新：
#   ssh root@IP witguang-update
#
# 默认行为是「只加自己的一份配置，不动别人的」：
#   - 配置写到 /etc/nginx/conf.d/<name>.conf
#   - 不删除 sites-enabled/default，不碰其他站点
#   - 同名文件已存在时先备份成 .bak-<时间戳>
#
# 参数：
#   --domain  主域名（默认 www.witguang.com）
#   --apex    裸域，301 到主域名（默认 witguang.com，传 none 关掉）
#   --path    站点目录（默认 /var/www/witguang/current，是一个 git 检出）
#   --repo    GitHub 仓库（默认 witguang/website）
#   --name    配置文件名（默认 witguang，写到 conf.d/<name>.conf）
#   --tls     证书模式：auto（默认，有证书就启用）| http | certbot
#   --cert / --key  证书路径（默认 /etc/nginx/ssl/<主域名>.pem 与 .key）
#   --clean-box     额外删除 sites-enabled/default（只对专用机器用）
set -euo pipefail

DOMAIN="www.witguang.com"
APEX="witguang.com"
DIR="/var/www/witguang/current"
REPO="witguang/website"
BRANCH="gh-pages"
NAME="witguang"
TLS="auto"
CERT=""
KEY=""
CLEAN_BOX=0

while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --apex)   APEX="$2"; shift 2 ;;
    --path)   DIR="$2"; shift 2 ;;
    --repo)   REPO="$2"; shift 2 ;;
    --name)   NAME="$2"; shift 2 ;;
    --tls)    TLS="$2"; shift 2 ;;
    --cert)   CERT="$2"; shift 2 ;;
    --key)    KEY="$2"; shift 2 ;;
    --clean-box) CLEAN_BOX=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
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

# ── 更新器 ────────────────────────────────────────────────
say "装更新脚本 /usr/local/bin/witguang-update"
mkdir -p /etc/witguang
cat > /etc/witguang/config <<EOF
REPO=$REPO
BRANCH=$BRANCH
DIR=$DIR
EOF

cat > /usr/local/bin/witguang-update <<'UPDATER'
#!/usr/bin/env bash
# 拉取 GitHub Actions 构建好的静态站。
#   witguang-update            更新到最新
#   witguang-update rollback   退回上一个版本
#   witguang-update status     看当前版本 / 自检
set -euo pipefail

[ -f /etc/witguang/config ] && . /etc/witguang/config
REPO="${REPO:-witguang/website}"
BRANCH="${BRANCH:-gh-pages}"
DIR="${DIR:-/var/www/witguang/current}"
DEPTH=20
URL="https://github.com/${REPO}.git"

exec 9>/var/lock/witguang-update.lock
flock -n 9 || { echo "另一个更新正在运行，跳过"; exit 0; }

status() {
  [ -d "$DIR/.git" ] || { echo "还没有检出：$DIR"; return 1; }
  echo "目录   $DIR"
  echo "仓库   $REPO@$BRANCH"
  echo "版本   $(git -C "$DIR" rev-parse --short HEAD)  ·  $(git -C "$DIR" log -1 --format='%cd' --date=format:'%Y-%m-%d %H:%M')"
  echo "提交   $(git -C "$DIR" log -1 --format=%s)"
  echo -n "自检   "
  curl -fsS --max-time 5 -H "Host: ${WITGUANG_HOST:-www.witguang.com}" http://127.0.0.1/version.json 2>/dev/null \
    || echo "（nginx 没响应，检查 systemctl status nginx）"
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
    git -C "$DIR" clean -fd
  fi
  echo "✓ 已更新到 $(git -C "$DIR" rev-parse --short HEAD)"
  echo "  $(git -C "$DIR" log -1 --format=%s)"
  echo -n "  自检 "
  curl -fsS --max-time 5 -H "Host: ${WITGUANG_HOST:-www.witguang.com}" http://127.0.0.1/version.json 2>/dev/null \
    || echo "nginx 未响应"
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
echo "WITGUANG_HOST=$DOMAIN" >> /etc/witguang/config

say "首次同步 $REPO@$BRANCH"
if ! /usr/local/bin/witguang-update; then
  warn "拉取失败——仓库里可能还没有 $BRANCH 分支（Actions 还没跑过）。"
  warn "先放占位页，等构建完成后执行 witguang-update。"
  mkdir -p "$DIR"
  printf '<!doctype html><meta charset="utf-8"><title>witguang</title><p>等待首次发布。\n' > "$DIR/index.html"
fi

# ── 证书 ──────────────────────────────────────────────────
[ -n "$CERT" ] || CERT="/etc/nginx/ssl/$DOMAIN.pem"
[ -n "$KEY" ]  || KEY="/etc/nginx/ssl/$DOMAIN.key"

USE_TLS=0
case "$TLS" in
  http) USE_TLS=0 ;;
  certbot) USE_TLS=0 ;;   # 交给 certbot --nginx 自己加 443
  auto|origin)
    if [ -f "$CERT" ] && [ -f "$KEY" ]; then
      USE_TLS=1
    else
      [ "$TLS" = "origin" ] && {
        warn "没找到证书：$CERT / $KEY"
        warn "从 Cloudflare 导出源站证书放到这两个路径，再重跑本脚本即可启用 HTTPS。"
      }
    fi
    ;;
  *) echo "未知 --tls 值：$TLS" >&2; exit 1 ;;
esac

# ── nginx 配置（只加自己这一份）───────────────────────────
CONF="/etc/nginx/conf.d/$NAME.conf"
say "写 $CONF（TLS=$([ "$USE_TLS" = 1 ] && echo on || echo off)）"

if [ -f "$CONF" ]; then
  BAK="$CONF.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CONF" "$BAK"
  echo "  已备份旧配置 → $BAK"
fi

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

    location ~* \\.(?:svg|png|jpe?g|webp|avif|gif|ico|woff2?)\$ {
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

{
  echo "# $DOMAIN —— 由 deploy/setup-vps.sh 生成，可重复执行覆盖"
  echo "# 站点目录 $DIR（git 检出 $REPO@$BRANCH）"

  # 裸域：统一 301 到主域名，避免两个地址出两份内容
  if [ -n "$APEX" ] && [ "$APEX" != "none" ] && [ "$APEX" != "$DOMAIN" ]; then
    echo "server {"
    echo "    listen 80;"
    echo "    listen [::]:80;"
    echo "    server_name $APEX;"
    echo "    return 301 https://$DOMAIN\$request_uri;"
    echo "}"
    echo
  fi

  echo "server {"
  echo "    listen 80;"
  echo "    listen [::]:80;"
  echo "    server_name $DOMAIN;"
  if [ "$USE_TLS" = 1 ]; then
    echo "    return 301 https://$DOMAIN\$request_uri;"
  else
    echo "$BODY"
  fi
  echo "}"

  if [ "$USE_TLS" = 1 ]; then
    # 443 上的裸域也要显式接住，否则会落到别的站
    if [ -n "$APEX" ] && [ "$APEX" != "none" ] && [ "$APEX" != "$DOMAIN" ]; then
      echo
      echo "server {"
      echo "    listen 443 ssl;"
      echo "    listen [::]:443 ssl;"
      echo "    http2 on;"
      echo "    server_name $APEX;"
      echo "    ssl_certificate     $CERT;"
      echo "    ssl_certificate_key $KEY;"
      echo "    ssl_protocols TLSv1.2 TLSv1.3;"
      echo "    return 301 https://$DOMAIN\$request_uri;"
      echo "}"
    fi
    echo
    echo "server {"
    echo "    listen 443 ssl;"
    echo "    listen [::]:443 ssl;"
    echo "    http2 on;"
    echo "    server_name $DOMAIN;"
    echo "    ssl_certificate     $CERT;"
    echo "    ssl_certificate_key $KEY;"
    echo "    ssl_protocols TLSv1.2 TLSv1.3;"
    echo "$BODY"
    echo '    add_header Strict-Transport-Security "max-age=31536000" always;'
    echo "}"
  fi
} > "$CONF"

if [ "$CLEAN_BOX" = 1 ]; then
  say "清理默认站点（--clean-box）"
  rm -f /etc/nginx/sites-enabled/default
fi

say "校验并重载"
nginx -t
systemctl enable --now nginx >/dev/null 2>&1 || true
systemctl reload nginx

IP=$(curl -s --max-time 5 https://api.ipify.org || echo "本机IP")
say "就绪"
echo "  公网 IP   $IP"
echo "  站点目录  $DIR"
echo "  配置文件  $CONF"
echo "  更新命令  witguang-update"
sleep 1   # reload 是异步的，立刻 curl 可能还是旧 worker
echo -n "  自检      "
curl -fsS --max-time 5 -H "Host: $DOMAIN" "http://127.0.0.1/version.json" || echo "失败（看 nginx error.log）"
echo
