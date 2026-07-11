var _resourceName = (function () {
  try { return window.GetParentResourceName(); } catch (e) { return 'lp_welfarelogin'; }
})();

var root          = document.getElementById('root');
var dailyCards    = document.getElementById('daily-cards');   // Row 1 = FREE track
var rewardCards   = document.getElementById('reward-cards');  // Row 2 = VIP track
var scoreSlots    = document.getElementById('score-slots');
var scoreLineFill = document.getElementById('score-line-fill');

var TRACK_W = 488;
var isVip   = false;

/* ── POST to Lua ── */
function post(name, data) {
  try {
    fetch('https://' + _resourceName + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {})
    }).catch(function () {});
  } catch (e) {}
}

/* ── custom scrollbar sync ── */
function initScrollbar(container, track) {
  var thumb = track.querySelector('.scroll-thumb');
  function update() {
    var sw = container.scrollWidth, cw = container.clientWidth;
    if (sw <= cw) { thumb.style.width = TRACK_W + 'px'; thumb.style.left = '0px'; }
    else {
      var tw = Math.max(30, (cw / sw) * TRACK_W);
      var tl = (container.scrollLeft / (sw - cw)) * (TRACK_W - tw);
      thumb.style.width = tw + 'px';
      thumb.style.left  = tl + 'px';
    }
  }
  container.addEventListener('scroll', update);
  thumb.addEventListener('mousedown', function (e) {
    e.preventDefault();
    var startX = e.clientX, startSL = container.scrollLeft;
    var sw = container.scrollWidth, cw = container.clientWidth;
    var tw = parseFloat(thumb.style.width) || TRACK_W;
    function onMove(mv) {
      var ratio = (mv.clientX - startX) / (TRACK_W - tw);
      container.scrollLeft = startSL + ratio * (sw - cw);
    }
    function onUp() {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    }
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  });
  update();
  return update;
}
var updateTopScroll, updateBotScroll, scrollSyncWired = false, scrollLock = false;

/* ── scroll คู่แบบ lp_battlepass — เลื่อนแถวหนึ่ง อีกแถวเลื่อนตาม (การ์ดวันเดียวกันอยู่ตำแหน่งเดียวกัน) ── */
function onScrollSync(from, to) {
  if (scrollLock) return;
  scrollLock = true;
  to.scrollLeft = from.scrollLeft;
  scrollLock = false;
}

function enableWheelScroll(container) {
  container.addEventListener('wheel', function (e) {
    e.preventDefault();
    container.scrollLeft += e.deltaY || e.deltaX;
  }, { passive: false });
}

/* ── SVG icons ── */
var LOCK_SVG = [
  '<svg width="18" height="20" viewBox="0 0 18 20" fill="none">',
  '<defs><linearGradient id="lg-lock" x1="9" y1="3" x2="9" y2="17" gradientUnits="userSpaceOnUse">',
  '<stop stop-color="#9C9C9C"/><stop offset="1" stop-color="#9C9C9C" stop-opacity="0.5"/></linearGradient></defs>',
  '<path fill-rule="evenodd" clip-rule="evenodd" fill="url(#lg-lock)" d="',
  'M5 7.2C5 6.08609 5.42143 5.0178 6.17157 4.23015C6.92172 3.4425 7.93913 3 9 3',
  'C10.0609 3 11.0783 3.4425 11.8284 4.23015C12.5786 5.0178 13 6.08609 13 7.2',
  'H13.6667C14.0203 7.2 14.3594 7.3475 14.6095 7.61005C14.8595 7.8726 15 8.2287 15 8.6',
  'V15.6C15 15.9713 14.8595 16.3274 14.6095 16.5899C14.3594 16.8525 14.0203 17 13.6667 17',
  'H4.33333C3.97971 17 3.64057 16.8525 3.39052 16.5899C3.14048 16.3274 3 15.9713 3 15.6',
  'V8.6C3 8.2287 3.14048 7.8726 3.39052 7.61005C3.64057 7.3475 3.97971 7.2 4.33333 7.2H5Z',
  'M9 4.4C9.70724 4.4 10.3855 4.695 10.8856 5.2201C11.3857 5.7452 11.6667 6.45739 11.6667 7.2',
  'H6.33333C6.33333 6.45739 6.61428 5.7452 7.11438 5.2201C7.61448 4.695 8.29276 4.4 9 4.4Z',
  'M10.3333 11.4C10.3333 11.6457 10.2717 11.8872 10.1547 12.1C10.0377 12.3128 9.86935 12.4895',
  ' 9.66667 12.6124V13.5C9.66667 13.6857 9.59643 13.8637 9.4714 13.995',
  'C9.34638 14.1263 9.17681 14.2 9 14.2C8.82319 14.2 8.65362 14.1263 8.5286 13.995',
  'C8.40357 13.8637 8.33333 13.6857 8.33333 13.5V12.6124',
  'C8.07916 12.4583 7.88052 12.2204 7.76821 11.9357C7.65589 11.651 7.63619 11.3353',
  ' 7.71216 11.0376C7.78812 10.74 7.95551 10.4769 8.18836 10.2893',
  'C8.4212 10.1017 8.7065 10 9 10C9.35362 10 9.69276 10.1475 9.94281 10.4101',
  'C10.1929 10.6726 10.3333 11.0287 10.3333 11.4Z"/></svg>'
].join('');

var CHECK_SVG = [
  '<svg width="18" height="18" viewBox="0 0 18 18" fill="none">',
  '<defs><linearGradient id="lg-check" x1="9" y1="2.25" x2="9" y2="15.75" gradientUnits="userSpaceOnUse">',
  '<stop stop-color="#F0CA78"/><stop offset="0.322" stop-color="#FCE7AA"/>',
  '<stop offset="0.644" stop-color="#D7A757"/><stop offset="1" stop-color="#BE893B"/></linearGradient></defs>',
  '<path fill-rule="evenodd" clip-rule="evenodd" fill="url(#lg-check)" d="',
  'M9 15.75C9.88642 15.75 10.7642 15.5754 11.5831 15.2362C12.4021 14.897 13.1462 14.3998',
  ' 13.773 13.773C14.3998 13.1462 14.897 12.4021 15.2362 11.5831',
  'C15.5754 10.7642 15.75 9.88642 15.75 9C15.75 8.11358 15.5754 7.23583 15.2362 6.41689',
  'C14.897 5.59794 14.3998 4.85382 13.773 4.22703C13.1462 3.60023 12.4021 3.10303',
  ' 11.5831 2.76381C10.7642 2.42459 9.88642 2.25 9 2.25',
  'C7.20979 2.25 5.4929 2.96116 4.22703 4.22703C2.96116 5.4929 2.25 7.20979 2.25 9',
  'C2.25 10.7902 2.96116 12.5071 4.22703 13.773C5.4929 15.0388 7.20979 15.75 9 15.75Z',
  'M8.826 11.73L12.576 7.23L11.424 6.27L8.199 10.1393L6.53025 8.46975',
  'L5.46975 9.53025L7.71975 11.7802L8.30025 12.3608L8.826 11.73Z"/></svg>'
].join('');

/* ── build a card row; track ∈ 'free'|'vip' ── */
function buildCards(container, cards, track) {
  container.innerHTML = '';
  cards.forEach(function (c, i) {
    var isLast = (i === cards.length - 1);
    var card = document.createElement('div');
    card.className = 'card state-' + (c.state || 'locked') + (isLast ? ' card-last' : '');

    var num = document.createElement('div');
    num.className = 'card-num';
    num.textContent = c.num !== undefined ? c.num : (i + 1);
    card.appendChild(num);

    var img = document.createElement('img');
    img.className = 'card-img';
    img.alt = '';
    if (c.img) {
      img.src = 'nui://vorp_inventory/html/img/items/' + c.img + '.png';
      img.onerror = function () {
        this.onerror = null;
        this.src = (c.state === 'current' || c.state === 'completed')
          ? 'assets/item-active.png'
          : (isLast ? 'assets/item-last.png' : 'assets/item-dimmed.png');
      };
    } else {
      var active = (c.state === 'current' || c.state === 'completed');
      img.src = active ? 'assets/item-active.png'
              : isLast ? 'assets/item-last.png'
              : 'assets/item-dimmed.png';
    }
    card.appendChild(img);

    var label = document.createElement('div');
    label.className = 'card-label';
    label.textContent = c.label || '';
    card.appendChild(label);

    /* claimable → click to claim */
    if (c.state === 'current') {
      card.addEventListener('click', function () {
        post('claim', { track: track, day: c.num });
      });
    }

    container.appendChild(card);
  });
}

/* ── score bar slots ── */
function buildScoreSlots(slots, onlineHours, onlineMax) {
  scoreSlots.innerHTML = '';
  slots.forEach(function (s) {
    var slot = document.createElement('div');
    slot.className = 'score-slot state-' + (s.state || 'locked');

    var box = document.createElement('div');
    box.className = 'slot-box';
    var img = document.createElement('img');
    img.src = s.img ? 'nui://vorp_inventory/html/img/items/' + s.img + '.png' : 'assets/item-placeholder.png';
    img.onerror = function () { this.onerror = null; this.src = 'assets/item-placeholder.png'; };
    img.alt = '';
    box.appendChild(img);

    var icon = document.createElement('div');
    icon.className = 'slot-icon';
    icon.innerHTML = (s.state === 'done') ? CHECK_SVG : LOCK_SVG;
    box.appendChild(icon);
    slot.appendChild(box);

    var dotWrap = document.createElement('div');
    dotWrap.className = 'slot-dot-wrap';
    var dot = document.createElement('div');
    dot.className = 'slot-dot';
    dotWrap.appendChild(dot);
    var lbl = document.createElement('div');
    lbl.className = 'slot-label';
    lbl.textContent = (s.hours || 0) + ' HR';
    dotWrap.appendChild(lbl);
    slot.appendChild(dotWrap);

    scoreSlots.appendChild(slot);
  });

  var max = onlineMax || 6;
  var pct = Math.min(100, Math.max(0, ((onlineHours || 0) / max) * 100));
  scoreLineFill.style.width = pct + '%';
}

/* ── open / render ── */
function render(data) {
  isVip = !!data.isVip;
  buildCards(dailyCards,  data.dayCards || [], 'free');
  buildCards(rewardCards, data.vipCards || [], 'vip');

  if (!updateTopScroll) {
    enableWheelScroll(dailyCards);
    enableWheelScroll(rewardCards);
    updateTopScroll = initScrollbar(dailyCards,  document.getElementById('scroll-track-top'));
    updateBotScroll = initScrollbar(rewardCards, document.getElementById('scroll-track-bot'));
  }
  if (!scrollSyncWired) {
    scrollSyncWired = true;
    dailyCards.addEventListener('scroll', function () { onScrollSync(dailyCards, rewardCards); });
    rewardCards.addEventListener('scroll', function () { onScrollSync(rewardCards, dailyCards); });
  }
  if (updateTopScroll) {
    updateTopScroll();
    updateBotScroll();
  }

  buildScoreSlots(data.onlineSlots || [], data.onlineHours || 0, data.onlineMax || 6);
}

/* RedM/CEF บางครั้งวาดเฟรมแรกของ NUI ไม่สมบูรณ์ตอนเพิ่งเปิด (เห็นชัดที่ #score-bar
   ใหญ่/ล้นกว่าปกติ) แล้วกลับมาถูกขนาดเองพอมี DOM reflow (เช่นตอนผู้เล่น scroll การ์ด)
   บังคับ reflow ทันทีหลัง render แทนที่จะรอผู้เล่นบังเอิญ scroll ไปเจอเอง */
function forceReflow() {
  document.documentElement.style.display = 'none';
  void document.documentElement.offsetHeight; // sync reflow
  document.documentElement.style.display = '';

  dailyCards.scrollLeft += 1;  dailyCards.scrollLeft -= 1;
  rewardCards.scrollLeft += 1; rewardCards.scrollLeft -= 1;
  window.dispatchEvent(new Event('resize'));
}

function open(data) {
  render(data);
  root.classList.remove('hidden');
  requestAnimationFrame(function () { requestAnimationFrame(forceReflow); });
}
function close()     { root.classList.add('hidden'); post('close'); }

/* ── message bus ── */
window.addEventListener('message', function (ev) {
  var d = ev.data;
  if (!d || !d.action) return;
  if (d.action === 'open')  open(d);
  if (d.action === 'close') root.classList.add('hidden');
});

/* ── close controls ── */
document.getElementById('close-btn').addEventListener('click', close);
document.addEventListener('keydown', function (e) {
  if ((e.key === 'Escape' || e.key === 'Backspace') && !root.classList.contains('hidden')) {
    close();
  }
});

/* ══════════════════════════════════════════════════════════════
   DEV helpers (browser console): test(currentDay, onlineHrs, vip)
   ══════════════════════════════════════════════════════════════ */
var LABELS = [
  'ขนมปัง','น้ำ','ยารักษา','เงิน $50','ขนมปัง','สเต๊กพาย','ทองคำแท่ง','น้ำ','ยารักษา','เงิน $75',
  'ขนมปัง','สตูว์เนื้อ','ยารักษา','ทองคำแท่ง','เงิน $100','ขนมปัง','น้ำ','สเต๊กพาย','ยารักษา','เงิน $125',
  'ทองคำแท่ง','สตูว์เนื้อ','ขนมปัง','ยารักษา','เงิน $150','สเต๊กพาย','น้ำ','ทองคำแท่ง','เงิน $200','ทองคำแท่ง x3'
];
window.test = function (currentDay, onlineHrs, vip) {
  currentDay = currentDay || 1;
  onlineHrs  = (onlineHrs !== undefined) ? onlineHrs : (currentDay - 1) * 0.4;
  vip = !!vip;
  var dayCards = [], vipCards = [];
  for (var i = 1; i <= 30; i++) {
    dayCards.push({ num: i, label: LABELS[i - 1], state: i < currentDay ? 'completed' : (i === currentDay ? 'current' : 'locked') });
    vipCards.push({ num: i, label: LABELS[i - 1], state: i < currentDay ? 'completed' : (i <= currentDay ? (vip ? 'current' : 'locked') : 'locked'), vip: true });
  }
  var done = Math.floor(onlineHrs);
  var onlineSlots = [1, 2, 3, 4, 5, 6].map(function (h) { return { hours: h, state: h <= done ? 'done' : 'locked' }; });
  open({ dayCards: dayCards, vipCards: vipCards, onlineSlots: onlineSlots, onlineHours: onlineHrs, onlineMax: 6, isVip: vip });
  console.log('[welfare] day=' + currentDay + ' online=' + onlineHrs + 'h vip=' + vip);
};

/* preview overlay + auto-open in plain browser (no NUI parent) */
(function () {
  var inNui = false;
  try { inNui = (typeof window.GetParentResourceName === 'function'); } catch (e) {}
  if (!inNui) {
    var ov = document.getElementById('preview-overlay');
    if (ov) ov.style.display = 'block';
    window.test(3, 2.5, true);
  }
})();
