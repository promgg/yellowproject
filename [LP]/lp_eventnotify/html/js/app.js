/* ============================================================
   event_notify — NUI logic (UI only, no RedM resource)
   Event badge row with live client-side countdowns.

   Message contract (SendNUIMessage from a future client.lua):
     { action: 'show',   events: [...] }  -> render + reveal, start ticking
     { action: 'update', events: [...] }  -> replace the list
     { action: 'hide' }                   -> hide the whole row
   Each event: { id, icon, label, seconds }
     icon    : 'hot-time' | 'deathmatch' | 'golden-time'  (keys below),
               or a full path / nui:// url
     seconds : remaining time; counts down locally, 1s tick
   When a timer reaches 0 the badge auto-removes; when none remain the row hides.
   ============================================================ */

(function () {
  'use strict';

  var IS_BROWSER = (typeof window.GetParentResourceName === 'undefined');

  var root = document.getElementById('root');
  var rowEl = document.getElementById('row');

  var ICON_MAP = {
    'hot-time':    'assets/icon_hot-time.png',
    'deathmatch':  'assets/icon_deathmatch.png',
    'golden-time': 'assets/icon_golden-time.png'
  };
  var DEFAULT_ICON = 'assets/icon_hot-time.png';

  function resolveIcon(key) {
    if (!key) return DEFAULT_ICON;
    if (key.indexOf('/') !== -1 || key.indexOf('nui://') === 0) return key;
    return ICON_MAP[String(key).toLowerCase()] || DEFAULT_ICON;
  }

  function formatTime(total) {
    total = Math.max(0, Math.floor(total));
    var h = Math.floor(total / 3600);
    var m = Math.floor((total % 3600) / 60);
    var s = total % 60;
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    return pad(h) + ':' + pad(m) + ':' + pad(s);
  }

  // live state: [{ id, remaining, el, timerSpan }]
  var badges = [];
  var ticker = null;

  function createBadge(ev) {
    var badge = document.createElement('div');
    badge.className = 'badge';

    var iconWrap = document.createElement('div');
    iconWrap.className = 'badge-icon';
    var img = document.createElement('img');
    img.alt = ev.label || '';
    img.src = resolveIcon(ev.icon);
    img.onerror = function () { if (img.src.indexOf(DEFAULT_ICON) === -1) img.src = DEFAULT_ICON; };
    iconWrap.appendChild(img);
    badge.appendChild(iconWrap);

    var label = document.createElement('p');
    label.className = 'badge-label';
    label.textContent = ev.label || '';
    badge.appendChild(label);

    var timer = document.createElement('div');
    timer.className = 'badge-timer';
    var span = document.createElement('span');

    if (ev.mode === 'progress') {
      span.textContent = '[' + (Number(ev.current) || 0) + '/' + (Number(ev.total) || 0) + ']';
      timer.appendChild(span);
      badge.appendChild(timer);
      return { id: ev.id, mode: 'progress', el: badge, timerSpan: span };
    }

    var secs = Math.max(0, Number(ev.seconds) || 0);
    span.textContent = formatTime(secs);
    timer.appendChild(span);
    badge.appendChild(timer);

    return { id: ev.id, remaining: secs, el: badge, timerSpan: span };
  }

  function tick() {
    var hasTimer = false;
    for (var i = badges.length - 1; i >= 0; i--) {
      var b = badges[i];
      if (b.mode === 'progress') continue; // static — only changes via a fresh 'update' push
      hasTimer = true;
      b.remaining -= 1;
      if (b.remaining <= 0) {
        b.timerSpan.textContent = formatTime(0);
        if (b.el.parentNode) b.el.parentNode.removeChild(b.el);
        badges.splice(i, 1);
      } else {
        b.timerSpan.textContent = formatTime(b.remaining);
      }
    }
    if (!hasTimer) stopTicker();
  }

  function startTicker() {
    if (ticker) return;
    ticker = setInterval(tick, 1000);
  }
  function stopTicker() {
    if (ticker) { clearInterval(ticker); ticker = null; }
  }

  function buildList(events) {
    rowEl.innerHTML = '';
    badges = [];
    if (!events || !events.length) { stopTicker(); return; }
    var frag = document.createDocumentFragment();
    for (var i = 0; i < events.length; i++) {
      var b = createBadge(events[i]);
      if (b.remaining <= 0) continue; // skip already-ended events
      badges.push(b);
      frag.appendChild(b.el);
    }
    rowEl.appendChild(frag);
    if (badges.length) startTicker(); else stopTicker();
  }

  function show(events) {
    if (events) buildList(events);
    root.classList.remove('hidden');
  }
  function hide() {
    root.classList.add('hidden');
    stopTicker();
  }

  window.addEventListener('message', function (ev) {
    var data = ev.data;
    if (!data || !data.action) return;
    switch (data.action) {
      case 'show':
      case 'open':
        show(data.events || data.items);
        break;
      case 'update':
        buildList(data.events || data.items);
        break;
      case 'hide':
      case 'close':
        hide();
        break;
    }
  });

  /* ---------------- DEV ONLY (browser preview) ---------------- */
  if (IS_BROWSER) {
    var MOCK_DATA = [
      { id: 'hot',    icon: 'hot-time',    label: 'HOT TIME',    seconds: 3600 },
      { id: 'dm',     icon: 'deathmatch',  label: 'DEATHMACTH',  seconds: 3600 },
      { id: 'golden', icon: 'golden-time', label: 'GOLDEN TIME', seconds: 3600 },
      { id: 'vlt_grave', icon: 'hot-time', label: 'VLT GRAVE', mode: 'progress', current: 9, total: 10 }
    ];
    show(MOCK_DATA);
    // Uncomment to align against the in-game screenshot:
    // document.getElementById('preview-overlay').style.display = 'block';
  }
})();
