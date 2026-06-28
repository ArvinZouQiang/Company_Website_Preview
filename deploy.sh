#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="/var/www/yowonewlife"
BACKUP_DIR="/root/site-backups"
ZIP_URL_1="https://arvinzouqiang.github.io/Company_Website_Preview/site.zip"
ZIP_URL_2="https://codeload.github.com/ArvinZouQiang/Company_Website_Preview/zip/refs/heads/gh-pages"
WORK_DIR="/tmp/yowo-official-deploy"

echo "[1/7] Install required packages"
if command -v apt >/dev/null 2>&1; then
  apt update || true
  apt install -y nginx unzip curl
elif command -v yum >/dev/null 2>&1; then
  yum install -y nginx unzip curl
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx unzip curl
fi

echo "[2/7] Start nginx"
systemctl enable nginx || true
systemctl start nginx || true

echo "[3/7] Backup existing web root"
mkdir -p "$BACKUP_DIR"
if [ -d /var/www/html ]; then
  cp -a /var/www/html "$BACKUP_DIR/html-$(date +%Y%m%d-%H%M%S)" || true
fi

echo "[4/7] Prepare official website files"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ -d /tmp/Company_Website_Preview-gh-pages ] && [ -f /tmp/Company_Website_Preview-gh-pages/index.html ]; then
  cp -a /tmp/Company_Website_Preview-gh-pages/. "$WORK_DIR/"
else
  curl -L --http1.1 --retry 3 --connect-timeout 20 -o site.zip "$ZIP_URL_1" || \
  curl -L --http1.1 --retry 3 --connect-timeout 20 -o site.zip "$ZIP_URL_2"
  unzip -q site.zip
  if [ -d Company_Website_Preview-gh-pages ]; then
    cp -a Company_Website_Preview-gh-pages/. "$WORK_DIR/"
  elif [ -d Company_Website_Preview-gh-pages-gh-pages ]; then
    cp -a Company_Website_Preview-gh-pages-gh-pages/. "$WORK_DIR/"
  fi
fi

test -f "$WORK_DIR/index.html"
test -f "$WORK_DIR/styles.css"
test -f "$WORK_DIR/script.js"

echo "[5/7] Publish files"
mkdir -p "$SITE_DIR"
rm -rf "$SITE_DIR"/*
cp -a "$WORK_DIR"/. "$SITE_DIR"/
chown -R www-data:www-data "$SITE_DIR" 2>/dev/null || true

echo "[6/7] Configure nginx"
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cat >/etc/nginx/sites-available/yowonewlife <<'NGINXCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name yowonewlife.com www.yowonewlife.com 60.204.246.90;

    root /var/www/yowonewlife;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(?:css|js|png|jpg|jpeg|gif|webp|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public";
        try_files $uri =404;
    }
}
NGINXCONF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/yowonewlife /etc/nginx/sites-enabled/yowonewlife

echo "[7/7] Reload nginx"
nginx -t
systemctl reload nginx

echo "DONE"
echo "Open: http://60.204.246.90/"
