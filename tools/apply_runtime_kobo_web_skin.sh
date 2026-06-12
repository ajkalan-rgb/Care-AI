#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-apply}"
ROOT="$(git rev-parse --show-toplevel)"
ASSET_DIR="$ROOT/kobo-web-skin/static"
KPI_CONTAINER="kobofe-kpi-1"
NGINX_CONTAINER="kobofe-nginx-1"
REMOTE_SKIN_DIR="/srv/static/care-ai-skin"

if ! docker ps --format '{{.Names}}' | grep -qx "$KPI_CONTAINER"; then
  echo "ERROR: $KPI_CONTAINER is not running. Start Kobo first."
  exit 1
fi

mkdir -p "$ASSET_DIR"

if [ "$MODE" = "rollback" ]; then
  docker exec -u root "$KPI_CONTAINER" python - <<'PY'
from pathlib import Path
restored = []
for backup in Path('/srv/src/kpi').rglob('*.care-ai-bak'):
    original = Path(str(backup).replace('.care-ai-bak', ''))
    original.write_text(backup.read_text(errors='ignore'))
    restored.append(str(original))
print('Restored:', restored)
PY
  docker restart "$KPI_CONTAINER" "$NGINX_CONTAINER" >/dev/null
  echo "Rolled back CARE-AI runtime skin."
  exit 0
fi

cp -f "$ROOT/branding/processed/child-care-thrive-favicon.png" "$ASSET_DIR/favicon.png"
cp -f "$ROOT/branding/processed/child-care-thrive-app-icon.png" "$ASSET_DIR/apple-touch-icon.png"
cp -f "$ROOT/branding/processed/care-ai-header-logo.png" "$ASSET_DIR/care-ai-header-logo.png"
cp -f "$ROOT/branding/processed/care-ai-login-logo.png" "$ASSET_DIR/care-ai-login-logo.png"
cp -f "$ROOT/branding/processed/hspn-ribbon-logo-transparent.png" "$ASSET_DIR/hspn-ribbon-logo-transparent.png"

cat > "$ASSET_DIR/care-ai-web.css" <<'CSS'
:root {
  --care-ai-blue: #006FE6;
  --care-ai-navy: #001F5B;
  --care-ai-red: #E60000;
  --care-ai-soft-blue: #EAF4FF;
  --care-ai-grey: #6B7280;
}

#care-ai-brand-strip {
  position: sticky;
  top: 0;
  z-index: 99999;
  min-height: 54px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 8px 18px;
  background: linear-gradient(90deg, var(--care-ai-navy), var(--care-ai-blue));
  color: #fff;
  box-shadow: 0 4px 16px rgba(0, 31, 91, 0.22);
  font-family: Inter, Arial, sans-serif;
}

#care-ai-brand-strip .care-ai-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

#care-ai-brand-strip img.care-ai-logo {
  height: 38px;
  width: auto;
  display: block;
  background: rgba(255,255,255,0.96);
  border-radius: 10px;
  padding: 4px 8px;
}

#care-ai-brand-strip .care-ai-title {
  font-weight: 800;
  letter-spacing: 0.01em;
  font-size: 15px;
  line-height: 1.15;
}

#care-ai-brand-strip .care-ai-subtitle {
  font-size: 11px;
  opacity: 0.9;
  line-height: 1.2;
}

#care-ai-brand-strip .care-ai-powered {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  white-space: nowrap;
  opacity: 0.95;
}

#care-ai-brand-strip .care-ai-powered img {
  height: 34px;
  width: auto;
  background: #fff;
  border-radius: 999px;
  padding: 3px;
}

a[href*="kobotoolbox.org"], a[href*="KoboToolbox"] {
  color: var(--care-ai-blue) !important;
}

button, .k-button, .btn, [role="button"] {
  border-radius: 10px;
}
CSS

cat > "$ASSET_DIR/care-ai-web.js" <<'JS'
(function () {
  var BRAND_ID = 'care-ai-brand-strip';
  var TITLE = 'Child-Care Thrive | CARE-AI';

  function installBrandStrip() {
    document.title = TITLE;
    var old = document.querySelector('title');
    if (old) old.textContent = TITLE;

    if (!document.body || document.getElementById(BRAND_ID)) return;

    var strip = document.createElement('div');
    strip.id = BRAND_ID;
    strip.innerHTML = '' +
      '<div class="care-ai-left">' +
        '<img class="care-ai-logo" src="/static/care-ai-skin/care-ai-header-logo.png" alt="Child-Care Thrive">' +
        '<div>' +
          '<div class="care-ai-title">Child-Care Thrive | CARE-AI</div>' +
          '<div class="care-ai-subtitle">Data Collection for Better Child Health</div>' +
        '</div>' +
      '</div>' +
      '<div class="care-ai-powered">' +
        '<span>Powered by HIV Survivors &amp; Partners Network</span>' +
        '<img src="/static/care-ai-skin/hspn-ribbon-logo-transparent.png" alt="HSPN">' +
      '</div>';

    document.body.insertBefore(strip, document.body.firstChild);
  }

  function replaceVisibleKoboText() {
    if (!document.body) return;
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    var node;
    while ((node = walker.nextNode())) {
      if (!node.nodeValue) continue;
      if (node.nodeValue.indexOf('KoboToolbox') !== -1) {
        node.nodeValue = node.nodeValue.replaceAll('KoboToolbox', 'CARE-AI');
      }
    }
  }

  function run() {
    installBrandStrip();
    replaceVisibleKoboText();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run);
  } else {
    run();
  }
  setTimeout(run, 1200);
  setTimeout(run, 3000);
})();
JS

for container in "$KPI_CONTAINER" "$NGINX_CONTAINER"; do
  docker exec -u root "$container" mkdir -p "$REMOTE_SKIN_DIR"
  docker cp "$ASSET_DIR/." "${container}:${REMOTE_SKIN_DIR}/"
done

docker exec -u root "$KPI_CONTAINER" python - <<'PY'
from pathlib import Path

patch = '''
<!-- CARE-AI RUNTIME SKIN -->
<link rel="stylesheet" href="/static/care-ai-skin/care-ai-web.css?v=2">
<script defer src="/static/care-ai-skin/care-ai-web.js?v=2"></script>
<!-- /CARE-AI RUNTIME SKIN -->
'''

def backup_once(path: Path, text: str):
    backup = Path(str(path) + '.care-ai-bak')
    if not backup.exists():
        backup.write_text(text)
    return backup

def patch_index(path: Path):
    if not path.exists():
        raise SystemExit(f'ERROR: Expected template missing: {path}')
    text = path.read_text(errors='ignore')
    backup = backup_once(path, text)
    if 'CARE-AI RUNTIME SKIN' not in text:
        if '</head>' not in text:
            raise SystemExit(f'ERROR: No </head> in {path}')
        text = text.replace('</head>', patch + '\n  </head>')
    text = text.replace('<title>KoboToolbox </title>', '<title>Child-Care Thrive | CARE-AI</title>')
    text = text.replace('<title>KoboToolbox {% block title %}{% endblock %}</title>', '<title>Child-Care Thrive | CARE-AI {% block title %}{% endblock %}</title>')
    text = text.replace('KoboToolbox is a free toolkit for collecting and managing data in challenging environments and is the most widely-used tool in humanitarian emergencies', 'Child-Care Thrive is a CARE-AI powered child health screening and community data collection platform.')
    path.write_text(text)
    print('Patched index template:', path)
    print('Backup:', backup)


def patch_base_simple(path: Path):
    if not path.exists():
        print('Base simple template not found, skipped:', path)
        return
    text = path.read_text(errors='ignore')
    backup = backup_once(path, text)
    text = text.replace('<title>KoboToolbox {% block title %}{% endblock %}</title>', '<title>Child-Care Thrive | CARE-AI {% block title %}{% endblock %}</title>')
    path.write_text(text)
    print('Patched base_simple title:', path)
    print('Backup:', backup)

patch_index(Path('/srv/src/kpi/kpi/templates/index.html'))
patch_base_simple(Path('/srv/src/kpi/kpi/templates/base_simple.html'))
PY

docker restart "$KPI_CONTAINER" "$NGINX_CONTAINER" >/dev/null
sleep 20

echo 'Testing injected assets:'
curl -I --max-time 10 http://kf.kobo.local/static/care-ai-skin/care-ai-web.css || true
curl -I --max-time 10 http://kf.kobo.local/static/care-ai-skin/care-ai-web.js || true

echo 'Testing shell injection:'
curl -s http://kf.kobo.local | grep -E 'Child-Care Thrive|CARE-AI RUNTIME SKIN|care-ai-web' || true

echo 'Applied CARE-AI runtime web skin.'
echo 'Rollback: tools/apply_runtime_kobo_web_skin.sh rollback'
