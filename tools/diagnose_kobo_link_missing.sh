#!/usr/bin/env bash
set -u

printf '\n=== CARE-AI / Kobo link-missing diagnostic ===\n'
printf 'Timestamp: %s\n' "$(date -Iseconds)"
printf 'Working dir: %s\n' "$(pwd)"

printf '\n--- Docker containers ---\n'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

printf '\n--- Host /etc/hosts Kobo entries ---\n'
grep -n 'kobo.local' /etc/hosts || true

printf '\n--- Host-level HTTP checks ---\n'
for host in kf.kobo.local kc.kobo.local ee.kobo.local; do
  printf '\n[%s]\n' "$host"
  curl -I --max-time 10 "http://${host}" || true
done

printf '\n--- KPI container DNS and HTTP checks ---\n'
docker exec kobofe-kpi-1 python - <<'PY' || true
import socket
import urllib.request

for host in ['kf.kobo.local', 'kc.kobo.local', 'ee.kobo.local']:
    print(f'\n[{host}]')
    try:
        print('DNS:', socket.gethostbyname_ex(host))
    except Exception as e:
        print('DNS_ERROR:', repr(e))
    try:
        req = urllib.request.Request(f'http://{host}', method='HEAD')
        with urllib.request.urlopen(req, timeout=10) as r:
            print('HTTP:', r.status, r.reason)
            print('URL:', r.geturl())
    except Exception as e:
        print('HTTP_ERROR:', repr(e))
PY

printf '\n--- Environment values likely relevant to Enketo / domains ---\n'
if [ -d upstream/kobo-env/envfiles ]; then
  find upstream/kobo-env/envfiles -maxdepth 1 -type f -print | sort | while read -r file; do
    printf '\n# %s\n' "$file"
    grep -Ei 'enketo|kobo|domain|host|url|protocol' "$file" || true
  done
else
  printf 'No upstream/kobo-env/envfiles directory found.\n'
fi

printf '\n--- Recent KPI logs: enketo/link/error hints ---\n'
docker logs --since=30m kobofe-kpi-1 2>&1 | grep -Ei 'enketo|link|deploy|deployment|error|exception|failed|traceback' | tail -120 || true

printf '\n--- Recent worker logs: enketo/link/error hints ---\n'
for c in kobofe-worker-1 kobofe-worker_kobocat-1 kobofe-worker_low_priority-1 kobofe-worker_long_running_tasks-1 kobofe-beat-1; do
  printf '\n# %s\n' "$c"
  docker logs --since=30m "$c" 2>&1 | grep -Ei 'enketo|link|deploy|deployment|error|exception|failed|traceback' | tail -80 || true
done

printf '\n--- Recent Enketo logs ---\n'
docker logs --since=30m kobofe-enketo_express-1 2>&1 | tail -160 || true

printf '\n=== End diagnostic ===\n'
