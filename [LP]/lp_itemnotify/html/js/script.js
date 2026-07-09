(function () {
  'use strict';

  var MAX_ON_SCREEN = 4;
  var DISPLAY_MS = 4000;
  var EXIT_MS = 300;

  var imgPath = 'nui://vorp_inventory/html/img/items/';
  var FALLBACK_ICON_SVG = 'data:image/svg+xml;utf8,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="%23f0ca78" stroke-width="1.5">' +
    '<path d="M4 7l8-4 8 4v10l-8 4-8-4V7z"/><path d="M4 7l8 4 8-4M12 11v10"/></svg>'
  );

  var stackEl = document.getElementById('stack');
  var queue = [];
  var shown = 0;

  function buildToast(image, label, name, qtyText) {
    var el = document.createElement('div');
    el.className = 'toast';

    var iconBox = document.createElement('div');
    iconBox.className = 'toast-icon-box';
    var img = document.createElement('img');
    img.src = image ? (imgPath + image + '.png') : FALLBACK_ICON_SVG;
    img.onerror = function () { img.onerror = null; img.src = FALLBACK_ICON_SVG; };
    iconBox.appendChild(img);

    var body = document.createElement('div');
    body.className = 'toast-body';
    var labelEl = document.createElement('div');
    labelEl.className = 'toast-label';
    labelEl.textContent = label || '';
    var nameEl = document.createElement('div');
    nameEl.className = 'toast-name';
    nameEl.textContent = name || '';
    body.appendChild(labelEl);
    body.appendChild(nameEl);

    var qty = document.createElement('div');
    qty.className = 'toast-qty';
    qty.textContent = qtyText || '';

    el.appendChild(iconBox);
    el.appendChild(body);
    el.appendChild(qty);
    return el;
  }

  function processQueue() {
    if (queue.length === 0 || shown >= MAX_ON_SCREEN) return;
    var item = queue.shift();
    shown++;
    var el = buildToast(item.image, item.label, item.name, item.qtyText);
    stackEl.appendChild(el);
    setTimeout(function () {
      el.classList.add('exit');
      setTimeout(function () {
        if (el.parentNode) el.parentNode.removeChild(el);
        shown--;
        processQueue();
      }, EXIT_MS);
    }, item.duration || DISPLAY_MS);
  }

  function show(data) {
    queue.push({
      image: data.image,
      label: data.label,
      name: data.name,
      qtyText: data.qtyText,
      duration: data.duration,
    });
    processQueue();
  }

  window.addEventListener('message', function (ev) {
    var d = ev.data || {};
    if (d.action === 'lp_itemnotify:init') {
      if (typeof d.imgPath === 'string' && d.imgPath) imgPath = d.imgPath;
    } else if (d.action === 'lp_itemnotify:show') {
      show(d);
    }
  });

  // ── Mock for browser dev (no game backend) ────────────────────────────
  if (typeof GetParentResourceName !== 'function') {
    window.__lpItemnotifyMock = {
      add: function (name, qty) {
        show({ image: null, label: 'ADDED', name: name || 'Legendary Muskie', qtyText: '+ ' + (qty || 1) });
      },
      remove: function (name, qty) {
        show({ image: null, label: 'REMOVED', name: name || 'Fish Bait', qtyText: '- ' + (qty || 1) });
      },
    };
  }
})();
