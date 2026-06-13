#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/Care-AI

echo "=== CARE-AI Kobo Codespaces startup ==="

if [ -f "upstream/kobo-docker/docker-compose.yml" ]; then
  echo "Found Kobo docker-compose.yml. Starting through docker compose..."

  cat > upstream/kobo-docker/docker-compose.codespaces-hosts.yml <<'YAML'
services:
  nginx:
    networks:
      default:
        aliases:
          - kf.docker.internal
          - kc.docker.internal
          - ee.docker.internal
          - kf.kobo.local
          - kc.kobo.local
          - ee.kobo.local
YAML

  cd upstream/kobo-docker
  docker compose \
    -f docker-compose.yml \
    -f docker-compose.codespaces-hosts.yml \
    up -d

  cd /workspaces/Care-AI
else
  echo "No upstream/kobo-docker/docker-compose.yml found."
  echo "Starting existing kobofe containers instead..."

  docker start $(docker ps -a --format '{{.Names}}' | grep '^kobofe-' || true) >/dev/null || true
fi

echo ""
echo "=== Fix Codespace browser hostnames ==="
sudo sh -c '
awk "
  !/kf\.kobo\.local/ &&
  !/kc\.kobo\.local/ &&
  !/ee\.kobo\.local/
" /etc/hosts > /tmp/hosts.clean

cat /tmp/hosts.clean > /etc/hosts
cat >> /etc/hosts <<EOF
127.0.0.1 kf.kobo.local kc.kobo.local ee.kobo.local
EOF
'

echo ""
echo "=== Find nginx IP reachable from KPI ==="
GOOD_IP=""

for ip in $(docker inspect kobofe-nginx-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}'); do
  echo "Testing nginx IP: $ip"
  if docker exec kobofe-kpi-1 python -c "import socket; socket.create_connection(('$ip',80),3).close()" 2>/dev/null; then
    GOOD_IP="$ip"
    break
  fi
done

if [ -z "$GOOD_IP" ]; then
  echo "Could not find nginx IP reachable from KPI."
  exit 1
fi

echo "Using reachable nginx IP: $GOOD_IP"

echo ""
echo "=== Fix app container host mappings ==="
for c in \
  kobofe-kpi-1 \
  kobofe-worker-1 \
  kobofe-worker_long_running_tasks-1 \
  kobofe-worker_low_priority-1 \
  kobofe-worker_kobocat-1 \
  kobofe-enketo_express-1
do
  echo "Fixing $c"

  docker exec -i -u root "$c" sh <<INNER
awk '
  !/kf\\.kobo\\.local/ &&
  !/kc\\.kobo\\.local/ &&
  !/ee\\.kobo\\.local/ &&
  !/kf\\.docker\\.internal/ &&
  !/kc\\.docker\\.internal/ &&
  !/ee\\.docker\\.internal/
' /etc/hosts > /tmp/hosts.clean

cat /tmp/hosts.clean > /etc/hosts
echo "$GOOD_IP kf.kobo.local kc.kobo.local ee.kobo.local kf.docker.internal kc.docker.internal ee.docker.internal" >> /etc/hosts
INNER
done

echo ""
echo "=== Fix Codespaces forwarded browser host ==="
/workspaces/Care-AI/tools/fix-kobo-forwarded-host.sh

echo ""
echo "=== Reload nginx ==="
docker exec -u root kobofe-nginx-1 nginx -t
docker exec -u root kobofe-nginx-1 nginx -s reload || docker restart kobofe-nginx-1

echo ""
echo "=== Test entry points ==="
curl -I http://kf.kobo.local | head -5
curl -I http://kc.kobo.local | head -7
curl -I http://ee.kobo.local | head -5

echo ""
echo "=== Test internal KPI connectivity ==="
docker exec kobofe-kpi-1 python -c "import socket; socket.create_connection(('kf.docker.internal',80),5).close(); print('KPI to KOBOFORM: OK')"
docker exec kobofe-kpi-1 python -c "import socket; socket.create_connection(('kc.docker.internal',80),5).close(); print('KPI to KOBOCAT: OK')"
docker exec kobofe-kpi-1 python -c "import socket; socket.create_connection(('ee.docker.internal',80),5).close(); print('KPI to ENKETO: OK')"

echo ""
echo "Kobo Codespaces startup complete."
