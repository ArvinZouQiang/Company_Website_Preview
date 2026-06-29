#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="/var/www/yowonewlife"
CONF_DIR="/etc/nginx/conf.d"
BACKUP="/root/nginx-backup-$(date +%Y%m%d-%H%M%S)"

echo "[1/5] Check website files"
test -f "$SITE_DIR/index.html"
test -f "$SITE_DIR/styles.css"
test -f "$SITE_DIR/script.js"

echo "[2/5] Backup current nginx configs"
mkdir -p "$BACKUP"
cp -a /etc/nginx/nginx.conf "$BACKUP/" 2>/dev/null || true
cp -a "$CONF_DIR" "$BACKUP/" 2>/dev/null || true
cp -a /etc/nginx/sites-enabled "$BACKUP/" 2>/dev/null || true
cp -a /etc/nginx/sites-available "$BACKUP/" 2>/dev/null || true

echo "[3/5] Disable old default or wordpress configs"
mkdir -p "$CONF_DIR"
find "$CONF_DIR" -maxdepth 1 -type f -name "*.conf" -exec mv {} "$BACKUP/" \;
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/yowonewlife

echo "[4/5] Write official website nginx config"
cat >"$CONF_DIR/00-yowonewlife.conf" <<'EOF'
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
EOF

echo "[5/5] Test and reload nginx"
nginx -t
systemctl reload nginx
echo "FIXED"
