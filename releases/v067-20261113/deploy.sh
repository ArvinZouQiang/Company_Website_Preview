#!/usr/bin/env bash
set -euo pipefail

site=/var/www/yowonewlife
base=https://arvinzouqiang.github.io/Company_Website_Preview/releases/v067-20261113
old_html=fbe1bc035cadbf2e2764523a9de5bbec989aaa2768ff9bda69b32a9d538c456f
old_css=5169088ddecb2312ccbc4e9a9afee3853d795cc1c8e860dd42fd3d282df1da5d
new_html=c40e3db7a01f63189a4eb3adbc02d1d2b5d006e1e606f9166476d1c9e8128be2
new_css=8050fbea228c0f54d9c64cc7d11472a34a5af421dd8c4f71810d283fdb090303
hash() { sha256sum "$1" | cut -d ' ' -f 1; }

test "$(id -u)" = 0 || { echo 'Please run as root.'; exit 1; }
test -f "$site/index.html"
test -f "$site/styles.css"
current_html=$(hash "$site/index.html")
current_css=$(hash "$site/styles.css")
if [ "$current_html" = "$new_html" ] && [ "$current_css" = "$new_css" ]; then
  echo 'ALREADY_DEPLOYED_V067'
  exit 0
fi
if [ "$current_html" != "$old_html" ] || [ "$current_css" != "$old_css" ]; then
  echo 'STOP: current website differs from the verified baseline. No files changed.'
  exit 1
fi

work=$(mktemp -d /tmp/yowo-v067.XXXXXX)
for file in index.html styles.css; do
  curl --fail --show-error --location --connect-timeout 15 --max-time 90 --retry 2 \
    "$base/$file" -o "$work/$file"
done
test "$(hash "$work/index.html")" = "$new_html"
test "$(hash "$work/styles.css")" = "$new_css"

mkdir -p /root/site-backups
backup=$(mktemp -d /root/site-backups/v067.XXXXXX)
cp -p "$site/index.html" "$backup/index.html"
cp -p "$site/styles.css" "$backup/styles.css"
echo "BACKUP=$backup"
changed=0
rollback() {
  if [ "$changed" = 1 ]; then
    cp -p "$backup/index.html" "$site/index.html"
    cp -p "$backup/styles.css" "$site/styles.css"
    echo 'ROLLED_BACK: verification failed; previous files restored.' >&2
  fi
}
trap rollback EXIT

install -m 644 "$work/index.html" "$site/.index-v067.tmp"
install -m 644 "$work/styles.css" "$site/.styles-v067.tmp"
changed=1
mv -f "$site/.styles-v067.tmp" "$site/styles.css"
mv -f "$site/.index-v067.tmp" "$site/index.html"
for domain in yowonewlife.com www.yowonewlife.com; do
  curl --fail --silent --show-error --resolve "$domain:443:127.0.0.1" \
    --connect-timeout 5 --max-time 15 "https://$domain/?release=v067" -o "$work/check.html"
  test "$(hash "$work/check.html")" = "$new_html"
done
curl --fail --silent --show-error --resolve yowonewlife.com:443:127.0.0.1 \
  --connect-timeout 5 --max-time 15 'https://yowonewlife.com/styles.css?v=065' -o "$work/check.css"
test "$(hash "$work/check.css")" = "$new_css"
changed=0
echo 'DEPLOYED_V067'
echo 'Only index.html and styles.css updated. Assets, nginx and TLS unchanged.'
