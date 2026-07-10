'use strict';

/* lp_battlepass NUI — reskinned to lp_welfarelogin (ล็อคอินรายวัน) design language.
   message contract (from client/cl_main.lua) — UNCHANGED:
     incoming: { enable:true, data:{ level, xp, maxXp, maxLevel, claimed, claimedVIP,
                                     rewards, rewards2, vip, season, dailyXp, dailyCap } }
     outgoing callbacks: quit, reward {level}, rewardVIP {level}, claimAllReward, refresh
     incoming close: { enable:false }
   NUI คำนวณ state (current/completed/locked) เองจาก level + claimed csv (server-authoritative
   ยังตรวจสิทธิ์ซ้ำทุกครั้ง) */

var _resourceName = (function () {
  try { return window.GetParentResourceName(); } catch (e) { return 'lp_battlepass'; }
})();

var root    = document.getElementById('root');
var stdRow  = document.getElementById('std-cards');
var vipRow  = document.getElementById('vip-cards');

var TRACK_W = 488;
var state   = { data: null };

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

/* ── helpers ── */
function claimedSet(str) {
  var set = {};
  if (!str) return set;
  String(str).split(',').forEach(function (s) {
    var n = parseInt(s, 10);
    if (!isNaN(n)) set[n] = true;
  });
  return set;
}
/* Lua array (index 1..30) → json.encode เป็น JS array (index 0..29) → เลเวล = index+1
   รองรับทั้ง array และ object (string key) กัน edge case */
function toEntries(rewards) {
  var out = [];
  if (!rewards) return out;
  if (Array.isArray(rewards)) {
    rewards.forEach(function (r, i) { if (r) out.push({ lvl: i + 1, r: r }); });
  } else {
    Object.keys(rewards).forEach(function (k) { out.push({ lvl: Number(k), r: rewards[k] }); });
    out.sort(function (a, b) { return a.lvl - b.lvl; });
  }
  return out;
}
function qtyOf(r) {
  if (r.amount != null) return r.amount;
  var m = /x\s*(\d+)/i.exec(r.desc || '');
  return m ? m[1] : null;
}

/* lock icon (silver) — ใช้กับแถว Premium ตอนไม่มี vip_card */
var LOCK_SVG = [
  '<svg width="18" height="20" viewBox="0 0 18 20" fill="none">',
  '<defs><linearGradient id="lg-lock" x1="9" y1="3" x2="9" y2="17" gradientUnits="userSpaceOnUse">',
  '<stop stop-color="#D9C08A"/><stop offset="1" stop-color="#9C9C9C" stop-opacity="0.6"/></linearGradient></defs>',
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

/* ── build one track row ── */
function buildRow(container, entries, opts) {
  container.innerHTML = '';
  entries.forEach(function (e) {
    var lvl = e.lvl, r = e.r;

    var vipLocked = opts.premium && !opts.hasVip;
    var st;
    if (opts.claimed[lvl])      st = 'completed';
    else if (lvl <= opts.level) st = 'current';
    else                        st = 'locked';
    if (vipLocked) st = 'locked'; // ไม่มี VIP → ล็อกทั้งแถว

    var card = document.createElement('div');
    card.className = 'card state-' + st + (vipLocked ? ' vip-locked' : '');

    var num = document.createElement('div');
    num.className = 'card-num';
    num.textContent = 'LV ' + lvl;
    card.appendChild(num);

    var q = qtyOf(r);
    if (q != null) {
      var qty = document.createElement('div');
      qty.className = 'card-qty';
      qty.textContent = '×' + q;
      card.appendChild(qty);
    }

    var img = document.createElement('img');
    img.className = 'card-img';
    img.alt = '';
    var active = (st === 'current' || st === 'completed') && !vipLocked;
    if (r.item) {
      img.src = 'nui://vorp_inventory/html/img/items/' + r.item + '.png';
      img.onerror = function () {
        this.onerror = null;
        this.src = active ? 'assets/item-active.png' : 'assets/item-dimmed.png';
      };
    } else {
      img.src = active ? 'assets/item-active.png' : 'assets/item-dimmed.png';
    }
    card.appendChild(img);

    if (vipLocked) {
      var lock = document.createElement('div');
      lock.className = 'card-lock';
      lock.innerHTML = LOCK_SVG;
      card.appendChild(lock);
    }

    var label = document.createElement('div');
    label.className = 'card-label';
    label.textContent = r.title || r.item || '-';
    card.appendChild(label);

    /* claimable → คลิกที่การ์ดเพื่อรับ (แบบล็อคอินรายวัน) */
    if (st === 'current' && !vipLocked) {
      card.addEventListener('click', function () {
        post(opts.premium ? 'rewardVIP' : 'reward', { level: lvl });
        setTimeout(function () { post('refresh', {}); }, 250);
      });
    }

    container.appendChild(card);
  });
}

/* ── custom scrollbar ── */
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
var updateTop, updateBot, scrollWired = false, scrollLock = false;

function wireScroll() {
  if (scrollWired) return;
  scrollWired = true;
  updateTop = initScrollbar(stdRow, document.getElementById('scroll-track-top'));
  updateBot = initScrollbar(vipRow, document.getElementById('scroll-track-bot'));

  function onScroll(from, to) {
    if (!scrollLock) { scrollLock = true; to.scrollLeft = from.scrollLeft; scrollLock = false; }
    updateTop(); updateBot();
  }
  stdRow.addEventListener('scroll', function () { onScroll(stdRow, vipRow); });
  vipRow.addEventListener('scroll', function () { onScroll(vipRow, stdRow); });

  [stdRow, vipRow].forEach(function (c) {
    c.addEventListener('wheel', function (e) {
      e.preventDefault();
      c.scrollLeft += e.deltaY || e.deltaX;
    }, { passive: false });
  });
}

/* ── render ── */
function render() {
  var d = state.data;
  if (!d) return;

  var level    = parseInt(d.level, 10) || 1;
  var xp       = parseInt(d.xp, 10) || 0;
  var maxXp    = parseInt(d.maxXp, 10) || 100;
  var maxLevel = parseInt(d.maxLevel, 10) || 30;
  var hasVip   = d.vip === 'Y';

  document.getElementById('level').textContent  = level;
  document.getElementById('season').textContent = d.season || '-';

  if (level >= maxLevel) {
    document.getElementById('xp-text').textContent = 'MAX LEVEL';
    document.getElementById('xp-line-fill').style.width = '100%';
  } else {
    document.getElementById('xp-text').textContent = xp + ' / ' + maxXp + ' XP';
    document.getElementById('xp-line-fill').style.width = Math.min(100, (xp / maxXp) * 100) + '%';
  }
  document.getElementById('daily-text').textContent =
    (d.dailyCap != null) ? ('EXP วันนี้ ' + (d.dailyXp || 0) + ' / ' + d.dailyCap) : '';

  buildRow(stdRow, toEntries(d.rewards),  { premium: false, level: level, claimed: claimedSet(d.claimed),    hasVip: hasVip });
  buildRow(vipRow, toEntries(d.rewards2), { premium: true,  level: level, claimed: claimedSet(d.claimedVIP), hasVip: hasVip });

  wireScroll();
  if (updateTop) { updateTop(); updateBot(); }
}

/* RedM/CEF บางทีวาดเฟรมแรกไม่สมบูรณ์ตอนเพิ่งเปิด — บังคับ reflow ทันทีหลัง render */
function forceReflow() {
  document.documentElement.style.display = 'none';
  void document.documentElement.offsetHeight;
  document.documentElement.style.display = '';
  stdRow.scrollLeft += 1; stdRow.scrollLeft -= 1;
  vipRow.scrollLeft += 1; vipRow.scrollLeft -= 1;
  window.dispatchEvent(new Event('resize'));
}

function open(data) {
  state.data = data;
  render();
  root.classList.remove('hidden');
  requestAnimationFrame(function () { requestAnimationFrame(forceReflow); });
}
function close() { root.classList.add('hidden'); post('quit', {}); }

/* ── controls ── */
document.getElementById('close-btn').addEventListener('click', close);
document.getElementById('btn-claimall').addEventListener('click', function () {
  post('claimAllReward', {});
  setTimeout(function () { post('refresh', {}); }, 300);
});
document.addEventListener('keydown', function (e) {
  if ((e.key === 'Escape' || e.key === 'Backspace') && !root.classList.contains('hidden')) close();
});

/* ── message bus ── */
window.addEventListener('message', function (event) {
  var msg = event.data || {};
  if (msg.enable && msg.data) open(msg.data);
  else if (msg.enable === false) root.classList.add('hidden');
});

/* ══════════════════════════════════════════════════════════════
   DEV helper (browser preview): test(level, xp, vip)
   ส่ง array แบบเดียวกับที่ Lua json.encode ส่งจริง
   ══════════════════════════════════════════════════════════════ */
window.test = function (level, xp, vip) {
  level = level || 8; xp = (xp !== undefined) ? xp : 40; vip = !!vip;
  var stdNames = ['ตุ๋นซี่โครง','น้ำส้ม','เนื้อย่างสมุนไพร','Gun Oil','ผ้าพันแผลใหญ่','ยารักษาม้า','ยาชูกำลัง','Lock pick','มรกต','ยาแก้ปวด','กล่องเครื่องมือ','เพชร','แผ่นไม้','กล่องชุบเพื่อน','Blueprint Low','ทับทิม','เหล็ก','ระเบิดลากสาย','พลั่วหลุมศพ','ระเบิดลูกเล็ก','สมุดคัมภีร์','Gun Oil','Lock pick','พลั่วหลุมศพ','ยาแก้ปวด','ยาชูกำลัง','ทับทิม','เพชร','มรกต','กล่องชุบเพื่อน'];
  var vipNames = ['ซุปหางวัว','นํ้าเบอรี่','สตูเนื้อ','ผ้าพันแผลใหญ่','ยารักษาม้า','Lock pick','Gun Oil','ยาชูกำลัง','กล่องเครื่องมือ','แผ่นไม้','เพชร','กล่องชุบเพื่อน','มรกต','เหล็ก','ทับทิม','พลั่วหลุมศพ','Blueprint Low','ระเบิดลูกเล็ก','ระเบิดลากสาย','Gun Oil','ยาแก้ปวด','Blueprint Low','สมุดคัมภีร์','ยาชูกำลัง','กล่องเครื่องมือ','กล่องชุบเพื่อน','ไม้กางเขนทอง','Blueprint Low','สมุดคัมภีร์','กระเป๋าแมวสีดำ'];
  var stdItems = ['food_braised_ribs','food_orange_juice','food_herb_roasted_meat','oil_gun','bandage_xl','hr_medicine','stamina','lockpick','mat_emerald','painkiller','misc_toolbox','mat_diamond','met_wood_planks','aed','blueprint_low','mat_ruby','mat_iron','misc_trainbomb','tool_grave_shovel','small_bomb','buff_book_marksman','oil_gun','lockpick','tool_grave_shovel','painkiller','stamina','mat_ruby','mat_diamond','mat_emerald','aed'];
  var stdAmt = [5,10,5,1,5,3,2,2,2,2,1,2,5,1,1,2,5,1,2,1,1,3,3,3,5,5,5,5,5,1];
  var vipAmt = [10,15,10,10,5,5,5,5,1,10,5,1,5,15,5,5,1,2,2,8,10,1,1,10,2,2,1,2,1,1];
  var std = [], vipT = [];
  for (var i = 0; i < 30; i++) {
    std.push({ title: stdNames[i], item: stdItems[i], type: 'item', amount: stdAmt[i], desc: 'x' + stdAmt[i] });
    vipT.push({ title: vipNames[i], item: stdItems[i], type: 'item', amount: vipAmt[i], desc: 'x' + vipAmt[i] });
  }
  open({ level: level, xp: xp, maxXp: 100, maxLevel: 30, claimed: '1,2,3',
         claimedVIP: '1,2', rewards: std, rewards2: vipT, vip: vip ? 'Y' : 'N',
         season: '2026-07', dailyXp: 200, dailyCap: 300 });
  console.log('[bp] level=' + level + ' xp=' + xp + ' vip=' + vip);
};
(function () {
  var inNui = false;
  try { inNui = (typeof window.GetParentResourceName === 'function'); } catch (e) {}
  if (!inNui) window.test(8, 40, true);
})();
