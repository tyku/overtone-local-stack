#!/bin/sh
set -eu

wget -qO- http://127.0.0.1/nginx-health >/dev/null
test -s /usr/share/nginx/html/version.json
wget -qO- http://api:3000/api/health >/dev/null
