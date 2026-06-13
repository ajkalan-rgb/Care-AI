(function () {
  function findLoginForm() {
    var forms = Array.prototype.slice.call(document.querySelectorAll('form'));
    return forms.find(function (form) {
      return form.querySelector('input[type="password"]') ||
             form.querySelector('input[name*="password"]') ||
             form.textContent.toLowerCase().includes('password');
    });
  }

  function applyMockupLayout() {
    document.title = 'Child-Care Thrive | CARE-AI';

    var form = findLoginForm();
    if (!form) return;

    if (document.getElementById('care-ai-login-panel')) return;

    var oldShell = form;
    for (var i = 0; i < 4; i++) {
      if (oldShell.parentElement && oldShell.parentElement !== document.body) {
        oldShell = oldShell.parentElement;
      }
    }
    oldShell.classList.add('care-ai-old-login-shell');

    form.querySelectorAll('img, svg').forEach(function (el) {
      el.remove();
    });

    var panel = document.createElement('div');
    panel.id = 'care-ai-login-panel';
    panel.innerHTML = '<div class="care-ai-panel-title">Login</div>';

    document.body.appendChild(panel);
    panel.appendChild(form);

    var links = panel.querySelectorAll('a');
    if (links.length) {
      var linkWrap = document.createElement('div');
      linkWrap.className = 'care-ai-links';
      links.forEach(function (a) {
        linkWrap.appendChild(a);
        linkWrap.appendChild(document.createTextNode('   '));
      });
      panel.appendChild(linkWrap);
    }

    var walker = document.createTreeWalker(panel, NodeFilter.SHOW_TEXT);
    var node;
    while ((node = walker.nextNode())) {
      node.nodeValue = node.nodeValue
        .replaceAll('KoboToolbox', 'Child-Care Thrive | CARE-AI')
        .replaceAll('KoBoToolbox', 'Child-Care Thrive | CARE-AI')
        .replaceAll('Kobo Toolbox', 'Child-Care Thrive | CARE-AI')
        .replaceAll('KoBo Toolbox', 'Child-Care Thrive | CARE-AI');
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyMockupLayout);
  } else {
    applyMockupLayout();
  }

  setTimeout(applyMockupLayout, 300);
  setTimeout(applyMockupLayout, 1000);
  setTimeout(applyMockupLayout, 2500);
})();



/* === CARE-AI PORTAL LOGOS SAME WORKING METHOD === */
(function () {
  function isLoginPage() {
    return window.location.pathname.indexOf('/accounts/login') !== -1;
  }

  function applyPortalLogos() {
    if (isLoginPage()) return;
    if (!document.body) return;

    document.title = 'Child-Care Thrive | CARE-AI';

    if (!document.getElementById('care-ai-portal-brand-logo')) {
      var brand = document.createElement('div');
      brand.id = 'care-ai-portal-brand-logo';
      brand.innerHTML = '<img src="/static/care-ai-skin/care-ai-header-logo-cropped.png?v=same-method-1" alt="Child-Care Thrive">';
      document.body.appendChild(brand);
    }

    if (!document.getElementById('care-ai-portal-hspn-sidebar-logo')) {
      var hspn = document.createElement('div');
      hspn.id = 'care-ai-portal-hspn-sidebar-logo';
      hspn.innerHTML = '<img src="/static/care-ai-skin/hspn-ribbon-logo-cropped.png?v=same-method-1" alt="HIV Survivors & Partners Network">';
      document.body.appendChild(hspn);
    }
  }

  applyPortalLogos();
  setTimeout(applyPortalLogos, 300);
  setTimeout(applyPortalLogos, 1000);
  setTimeout(applyPortalLogos, 2500);
})();
/* === /CARE-AI PORTAL LOGOS SAME WORKING METHOD === */

/* === CARE-AI HIDE HELP GITHUB === */
(function () {
  function isLoginPage() {
    return window.location.pathname.indexOf('/accounts/login') !== -1;
  }

  function hideHelpGithub() {
    if (isLoginPage()) return;

    var targets = Array.prototype.slice.call(document.querySelectorAll('a, button'));

    targets.forEach(function (el) {
      var haystack = [
        el.getAttribute('href') || '',
        el.getAttribute('title') || '',
        el.getAttribute('aria-label') || '',
        el.textContent || '',
        el.className || ''
      ].join(' ').toLowerCase();

      if (
        haystack.includes('github') ||
        haystack.includes('help') ||
        haystack.includes('support')
      ) {
        el.classList.add('care-ai-hide-help-github');

        var parent = el.parentElement;
        if (parent && parent.children.length === 1) {
          parent.classList.add('care-ai-hide-help-github');
        }
      }
    });
  }

  hideHelpGithub();
  setTimeout(hideHelpGithub, 500);
  setTimeout(hideHelpGithub, 1500);
  setTimeout(hideHelpGithub, 3000);
})();
/* === /CARE-AI HIDE HELP GITHUB === */
