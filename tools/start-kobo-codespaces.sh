#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/Care-AI/upstream/kobo-docker

docker compose \
  -f docker-compose.yml \
  -f docker-compose.codespaces-hosts.yml \
  up -d

echo "Kobo started with persistent Codespaces host aliases."
echo ""
echo "Testing internal reachability from KPI..."

cd /workspaces/Care-AI

echo "KPI to KOBOFORM:"
docker exec kobofe-kpi-1 python -c "import urllib.request; print(urllib.request.urlopen('http://kf.docker.internal', timeout=8).status)"

echo "KPI to KOBOCAT:"
docker exec kobofe-kpi-1 python -c "import urllib.request; print(urllib.request.urlopen('http://kc.docker.internal', timeout=8).status)"

echo "KPI to ENKETO:"
docker exec kobofe-kpi-1 python -c "import urllib.request; print(urllib.request.urlopen('http://ee.docker.internal', timeout=8).status)"
