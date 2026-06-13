(function () {
  var BRAND_ID = 'care-ai-brand-strip';
  var TITLE = 'Child-Care Thrive | CARE-AI';

  function ensureFavicon() {
    var icon = document.querySelector('link[rel="icon"]') || document.createElement('link');
    icon.setAttribute('rel', 'icon');
    icon.setAttribute('href', '/static/care-ai-skin/favicon.png?v=final');
    document.head.appendChild(icon);

    var apple = document.querySelector('link[rel="apple-touch-icon"]') || document.createElement('link');
    apple.setAttribute('rel', 'apple-touch-icon');
    apple.setAttribute('href', '/static/care-ai-skin/apple-touch-icon.png?v=final');
    document.head.appendChild(apple);
  }

  function installBrandStrip() {
    document.title = TITLE;
    var old = document.querySelector('title');
    if (old) old.textContent = TITLE;
    ensureFavicon();

    if (!document.body || document.getElementById(BRAND_ID)) return;

    var strip = document.createElement('div');
    strip.id = BRAND_ID;
    strip.innerHTML =
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
      node.nodeValue = node.nodeValue
        .replaceAll('KoboToolbox', 'CARE-AI')
        .replaceAll('KoBoToolbox', 'CARE-AI')
        .replaceAll('Kobo Toolbox', 'CARE-AI')
        .replaceAll('KoBo Toolbox', 'CARE-AI');
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

  setTimeout(run, 500);
  setTimeout(run, 1500);
  setTimeout(run, 3500);
})();
