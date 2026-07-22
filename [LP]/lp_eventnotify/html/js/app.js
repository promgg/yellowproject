/* ============================================================
   lp_eventnotify — badge แจ้งกิจกรรมมุมขวาบน (Plaque ธีมมืด-ทอง)
   Message contract (เดิม):
     { action:'show'|'update', events:[...] } / { action:'hide' }
   event: { id, icon, label, seconds } หรือ { id, icon, label, mode:'progress', current, total }
   เสริม (optional): people (string เช่น "8/10"), leader { name, score, color }
   ============================================================ */
(function () {
  'use strict';

  var IS_BROWSER = (typeof window.GetParentResourceName === 'undefined');
  var root  = document.getElementById('root');
  var rowEl = document.getElementById('row');

  var ICON_MAP = {
    'hot-time':    'assets/icon_hot-time.png',
    'deathmatch':  'assets/icon_deathmatch.png',
    'golden-time': 'assets/icon_golden-time.png'
  };
  var DEFAULT_ICON = 'assets/icon_hot-time.png';
  var I_PPL = '<svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M2 15a6 6 0 0112 0z"/></svg>';

  function resolveIcon(key) {
    if (!key) return DEFAULT_ICON;
    if (key.indexOf('/') !== -1 || key.indexOf('nui://') === 0) return key;
    return ICON_MAP[String(key).toLowerCase()] || DEFAULT_ICON;
  }
  function esc(s) {
    return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
  function formatTime(total) {
    total = Math.max(0, Math.floor(total));
    var h = Math.floor(total / 3600), m = Math.floor((total % 3600) / 60), s = total % 60;
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    return (h > 0 ? pad(h) + ':' : '') + pad(m) + ':' + pad(s);
  }

  var badges = []; // [{ id, remaining, el, timerSpan, mode }]
  var ticker = null;

  function metaHtml(ev) {
    var s = '';
    if (ev.people) s += '<span class="badge-sep"></span><span class="badge-chip ppl">' + I_PPL + esc(ev.people) + '</span>';
    if (ev.leader && ev.leader.name !== undefined) {
      var col = ev.leader.color || '#d9b779';
      s += '<span class="badge-sep"></span><span class="badge-chip leader"><span class="dot" style="background:' + col + ';color:' + col + '"></span>' +
           esc(ev.leader.name) + (ev.leader.score !== undefined ? ' ' + esc(ev.leader.score) : '') + '</span>';
    }
    return s;
  }

  function createBadge(ev) {
    var badge = document.createElement('div');
    badge.className = 'badge';
    if (ev.leader && ev.leader.color) badge.style.setProperty('--accent', ev.leader.color);

    var isProgress = (ev.mode === 'progress');
    var secs = isProgress ? 0 : Math.max(0, Number(ev.seconds) || 0);
    var valInner = isProgress
      ? '[' + (Number(ev.current) || 0) + '/' + (Number(ev.total) || 0) + ']'
      : '<span class="eye">Ends in</span><span class="v">' + formatTime(secs) + '</span>';

    badge.innerHTML =
      '<div class="badge-icon"><img alt="" src="' + esc(resolveIcon(ev.icon)) + '"></div>' +
      '<div class="badge-body">' +
        '<div class="badge-label">' + esc(ev.label) + '</div>' +
        '<div class="badge-meta"><span class="badge-val">' + valInner + '</span>' + metaHtml(ev) + '</div>' +
      '</div>';

    var img = badge.querySelector('img');
    img.onerror = function () { if (img.src.indexOf(DEFAULT_ICON) === -1) img.src = DEFAULT_ICON; };

    if (isProgress) return { id: ev.id, mode: 'progress', el: badge };

    var vEl = badge.querySelector('.badge-val .v');
    if (secs <= 60) badge.classList.add('is-low');
    return { id: ev.id, remaining: secs, el: badge, timerSpan: vEl };
  }

  function tick() {
    var hasTimer = false;
    for (var i = badges.length - 1; i >= 0; i--) {
      var b = badges[i];
      if (b.mode === 'progress') continue;
      hasTimer = true;
      b.remaining -= 1;
      if (b.remaining <= 0) {
        if (b.timerSpan) b.timerSpan.textContent = formatTime(0);
        if (b.el.parentNode) b.el.parentNode.removeChild(b.el);
        badges.splice(i, 1);
      } else {
        if (b.timerSpan) b.timerSpan.textContent = formatTime(b.remaining);
        b.el.classList.toggle('is-low', b.remaining <= 60);
      }
    }
    if (!hasTimer) stopTicker();
  }
  function startTicker() { if (!ticker) ticker = setInterval(tick, 1000); }
  function stopTicker() { if (ticker) { clearInterval(ticker); ticker = null; } }

  function buildList(events) {
    rowEl.innerHTML = '';
    badges = [];
    if (!events || !events.length) { stopTicker(); return; }
    var frag = document.createDocumentFragment();
    for (var i = 0; i < events.length; i++) {
      var b = createBadge(events[i]);
      if (b.mode !== 'progress' && b.remaining <= 0) continue;
      badges.push(b);
      frag.appendChild(b.el);
    }
    rowEl.appendChild(frag);
    if (badges.some(function (b) { return b.mode !== 'progress'; })) startTicker(); else stopTicker();
  }

  function show(events) { if (events) buildList(events); root.classList.remove('hidden'); }
  function hide() { root.classList.add('hidden'); stopTicker(); }

  window.addEventListener('message', function (ev) {
    var data = ev.data;
    if (!data || !data.action) return;
    switch (data.action) {
      case 'show': case 'open': show(data.events || data.items); break;
      case 'update': buildList(data.events || data.items); break;
      case 'hide': case 'close': hide(); break;
    }
  });

  /* ---------------- DEV ONLY (browser preview) ---------------- */
  if (IS_BROWSER) {
    show([
      { id: 'grave',  icon: 'hot-time',    label: 'VLT GRAVE',    mode: 'progress', current: 7, total: 10 },
      { id: 'hot',    icon: 'hot-time',    label: 'HOT TIME',     seconds: 1240 },
      { id: 'gold',   icon: 'golden-time', label: 'GOLDEN TIME',  seconds: 47 },
      { id: 'dm',     icon: 'deathmatch',  label: 'สมบัติแห่งสัญญา', seconds: 300, people: '24/60', leader: { name: 'วาเลนไทน์', score: 12, color: '#e0503f' } }
    ]);
  }
})();
