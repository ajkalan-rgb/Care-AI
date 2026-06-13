#!/usr/bin/env bash
set -euo pipefail

CONF="/etc/nginx/conf.d/default.conf"

docker cp "kobofe-nginx-1:$CONF" /tmp/kobo-nginx-default.conf

python - <<'PY'
from pathlib import Path

p = Path("/tmp/kobo-nginx-default.conf")
text = p.read_text()

if "return 204;" not in text:
    print("No return 204 found; forwarded host route already patched.")
else:
    patch = """proxy_set_header Host kf.kobo.local;
        proxy_set_header X-Forwarded-Host kf.kobo.local;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1;"""
    text = text.replace("return 204;", patch, 1)
    p.write_text(text)
    print("Patched nginx default forwarded route.")
PY

docker cp /tmp/kobo-nginx-default.conf "kobofe-nginx-1:$CONF"
docker exec -u root kobofe-nginx-1 nginx -t
docker exec -u root kobofe-nginx-1 nginx -s reload || docker restart kobofe-nginx-1
