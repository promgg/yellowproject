'use strict';

/* lp_leaderboard NUI — contract with client/cl_main.lua:
   incoming: { action:'open'|'update', data:{ isAdmin, categories:[{id,label,th,icon}],
                                              kill:{rows,you}, city:{rows,you},
                                              fish/mining/planting/lumber:{rows,you} } }
             { action:'close' }
   outgoing: close
   หมายเหตุ: ไม่มีปุ่ม refresh/reset ใน UI — server live-push อัปเดตให้อัตโนมัติระหว่างเปิด UI ค้าง
   ล้างสถิติทำผ่านคำสั่งแอดมิน /lbreset <category> เท่านั้น (ไม่มีปุ่มในหน้าจอ)
   หมายเหตุ: สลับแท็บหมวดทำ local ล้วน (ไม่เรียก server) — data ทุกหมวดมาพร้อมกัน
   fish/mining/planting/lumber เป็น "gather job" หน้าตาเดียวกันหมด (SCORE + count) ดู GATHER_CATS */

var _res = (function () { try { return window.GetParentResourceName(); } catch (e) { return 'lp_leaderboard'; } })();
function post(name, body) {
  try {
    fetch('https://' + _res + '/' + name, {
      method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {})
    }).catch(function () {});
  } catch (e) {}
}

var root = document.getElementById('root');
var state = { data: null, active: null };

/* ── icons ── */
var IC = {
  target: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/><line x1="12" y1="1" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="1" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="23" y2="12"/></svg>',
  flag:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 22V4c4-2 8 2 12 0v10c-4 2-8-2-12 0"/><line x1="4" y1="22" x2="4" y2="14"/></svg>',
  skull:  '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C7 2 3 5.6 3 10c0 2.6 1.3 4.6 3 5.8V19a1 1 0 0 0 1 1h2v-2h2v2h2v-2h2v2h2a1 1 0 0 0 1-1v-3.2c1.7-1.2 3-3.2 3-5.8 0-4.4-4-8-9-8Zm-3 10a1.6 1.6 0 1 1 0-3.2 1.6 1.6 0 0 1 0 3.2Zm6 0a1.6 1.6 0 1 1 0-3.2 1.6 1.6 0 0 1 0 3.2Z"/></svg>',
  star:   '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l2.9 6.3 6.9.7-5.1 4.6 1.4 6.8L12 17.8 5.9 20.4l1.4-6.8L2.2 9l6.9-.7L12 2z"/></svg>',
  person: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg>',
  shield: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l8 3v6c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V5z"/></svg>',
  pic:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M4 19l5-4 3 2 4-4 4 4"/></svg>',
  enter:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>',
  fish:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s4-5 11-5 9 5 9 5-2 5-9 5S2 12 2 12Z"/><path d="M22 12l3-3v6l-3-3Z" fill="currentColor" stroke="none"/><circle cx="16.5" cy="10.5" r="1" fill="currentColor" stroke="none"/></svg>',
  mining: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 3c4.5 0 9 3 12 6-4-1-8.5 0-11.5 3C6.5 9 5.5 6 9 3Z"/><path d="M11.5 8.5 4 20"/></svg>',
  plant:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21V10"/><path d="M12 10C12 6 9 4 5 4c0 4.5 2.3 7 7 7Z"/><path d="M12 13c0-4 3-6 7-6 0 4.5-2.3 7-7 7Z"/></svg>',
  axe:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 3.5c3.5.5 6 3 6.5 6.5-3-1-6.5-.5-8.5 1.5-1-3 .5-6.5 2-8Z"/><path d="M13 8.5 3.5 18l1 1.5L14 10"/></svg>',
  briefcase: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 12h18"/></svg>'
};
function iconFor(name) { return IC[name] || IC.star; }

/* meta ของแทบรวม (group) — label/icon; server ส่ง Config.Groups มาใน payload.groups
   ถ้าไม่มี ก็ fallback มาที่นี่ (กันพัง) */
var GROUPS_FALLBACK = { jobs: { label: 'JOBS', icon: 'briefcase' } };

/* ── category render configs ── */
var GRID_7 = '48px 50px 1fr 122px 84px 74px 78px'; /* 4 คงที่ + 3 คอลัมน์สถิติ */
var GRID_6 = '48px 50px 1fr 122px 100px 100px';    /* 4 คงที่ + 2 คอลัมน์สถิติ */

/* หมวด "gather job" (fish/mining/planting/lumber/hunting) หน้าตาเดียวกันหมด: SCORE + count */
var GATHER_CATS = { fish: true, mining: true, planting: true, lumber: true, hunting: true };
function gatherCols(countIcon, countLabel) {
  return [
    { t: '#',          cls: '', ic: null },
    { t: 'PIC',        cls: '', ic: 'pic' },
    { t: 'NAME',       cls: '', ic: 'person' },
    { t: 'BADGE',      cls: '', ic: 'shield' },
    { t: 'SCORE',      cls: 'center', ic: 'star' },
    { t: countLabel,   cls: 'center', ic: countIcon }
  ];
}

var CATS = {
  kill: {
    icon: 'target',
    grid: GRID_7,
    cols: [
      { t: '#',      cls: '', ic: null },
      { t: 'PIC',    cls: '', ic: 'pic' },
      { t: 'NAME',   cls: '', ic: 'person' },
      { t: 'BADGE',  cls: '', ic: 'shield' },
      { t: 'SCORE',  cls: 'center', ic: 'star' },
      { t: 'KILLS',  cls: 'center', ic: 'target' },
      { t: 'DEATHS', cls: 'center', ic: 'skull' }
    ]
  },
  city: {
    icon: 'flag',
    grid: GRID_7,
    cols: [
      { t: '#',     cls: '', ic: null },
      { t: 'ตรา',   cls: '', ic: 'pic' },
      { t: 'เมือง',  cls: '', ic: 'flag' },
      { t: 'เข้า',   cls: 'center', ic: 'enter' },
      { t: 'ชนะ',    cls: 'center', ic: 'star' },
      { t: 'แพ้',    cls: 'center', ic: 'skull' },
      { t: 'ชนะ%',   cls: 'center', ic: 'shield' }
    ]
  },
  fish:     { icon: 'fish',   grid: GRID_6, countIcon: 'fish',   countLabel: 'CATCHES',  cols: gatherCols('fish', 'CATCHES') },
  mining:   { icon: 'mining', grid: GRID_6, countIcon: 'mining', countLabel: 'DIGS',     cols: gatherCols('mining', 'DIGS') },
  planting: { icon: 'plant',  grid: GRID_6, countIcon: 'plant',  countLabel: 'HARVESTS', cols: gatherCols('plant', 'HARVESTS') },
  lumber:   { icon: 'axe',    grid: GRID_6, countIcon: 'axe',    countLabel: 'CHOPS',    cols: gatherCols('axe', 'CHOPS') },
  hunting:  { icon: 'skull',  grid: GRID_6, countIcon: 'skull',  countLabel: 'SKINS',    cols: gatherCols('skull', 'SKINS') }
};

function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html !== undefined) e.innerHTML = html; return e; }
function initial(name) { var s = (name || '?').trim(); return s ? s.charAt(0).toUpperCase() : '?'; }
/* รีสตาร์ท CSS animation บน element เดิม (innerHTML เปลี่ยนแต่ node เดิม ไม่ trigger เอง) —
   ใช้กับ .lb__you ทุกครั้งที่ render ใหม่ (สลับแท็บ/live-push) ให้กระพริบบอกว่าอัปเดตแล้ว */
function pulse(target) {
  target.classList.remove('flash');
  void target.offsetWidth; // force reflow
  target.classList.add('flash');
}

/* ── grouping helpers (ยุบหมวดที่มี group เดียวกันเป็นแทบเดียว + sub-pill ข้างใน) ── */
function cats() { return (state.data && state.data.categories) || []; }
function groupMeta(gid) {
  var g = (state.data && state.data.groups && state.data.groups[gid]) || GROUPS_FALLBACK[gid] || {};
  return { label: g.label || gid.toUpperCase(), icon: g.icon || 'star' };
}
function subCatsOfGroup(gid) { return cats().filter(function (c) { return c.group === gid; }); }
function groupOfActive() {
  var arr = cats();
  for (var i = 0; i < arr.length; i++) if (arr[i].id === state.active) return arr[i].group || null;
  return null;
}
function shortLabel(label) { return String(label || '').replace(/\s*RANK$/i, '').trim() || label; }

/* ── tab row เดียว (ไม่มีแถวที่สอง — ความสูงคงที่ทุกแท็บ ไม่ดัน .lb__you) ──
   ปกติ group โผล่เป็น 1 ปุ่มรวม (เช่น "JOBS") กดแล้ว "คลี่" เป็นอาชีพย่อยแทนที่ปุ่มเดิม
   ในแถวเดียวกัน — สลับ KILL/CITY เมื่อไรก็ยุบกลับเป็นปุ่มรวมอัตโนมัติ (ไม่มี state ค้าง) */
function renderNav() {
  var nav = document.getElementById('nav');
  nav.innerHTML = '';
  var seen = {};
  cats().forEach(function (c) {
    if (c.group) {
      if (seen[c.group]) return;            // group ประมวลผลครั้งเดียว
      seen[c.group] = true;
      var gid = c.group;
      var subs = subCatsOfGroup(gid);
      if (groupOfActive() === gid) {
        // คลี่: โชว์อาชีพย่อยทั้งหมดเป็น cluster ในแถวเดียวกัน (ไม่เพิ่มแถว)
        var cluster = el('div', 'nav-group');
        var gm = groupMeta(gid);
        cluster.appendChild(el('span', 'nav-group__ic', iconFor(gm.icon)));
        subs.forEach(function (sc) {
          var sitem = el('button', 'nav-item nav-item--sub' + (sc.id === state.active ? ' active' : ''));
          sitem.innerHTML = '<span class="ic">' + iconFor((CATS[sc.id] && CATS[sc.id].icon) || 'star') + '</span>' + shortLabel(sc.label);
          sitem.addEventListener('click', function () { state.active = sc.id; render(); });
          cluster.appendChild(sitem);
        });
        nav.appendChild(cluster);
      } else {
        // ยุบ: ปุ่มรวม 1 อัน — กดแล้วเข้าอาชีพแรกที่เปิด
        var gmeta = groupMeta(gid);
        var item = el('button', 'nav-item');
        item.innerHTML = '<span class="ic">' + iconFor(gmeta.icon) + '</span>' + gmeta.label;
        item.addEventListener('click', function () {
          if (subs[0]) state.active = subs[0].id;
          render();
        });
        nav.appendChild(item);
      }
    } else {
      var active2 = (c.id === state.active);
      var item2 = el('button', 'nav-item' + (active2 ? ' active' : ''));
      item2.innerHTML = '<span class="ic">' + iconFor((CATS[c.id] && CATS[c.id].icon) || 'star') + '</span>' + (c.label || c.id);
      item2.addEventListener('click', function () { state.active = c.id; render(); });
      nav.appendChild(item2);
    }
  });
}

/* ── YOUR RANKING banner ── */
function badgePill(b) {
  if (!b) return '';
  return '<span class="badge" style="color:' + b.color + '">' + b.name + '</span>';
}
function renderYou() {
  var box = document.getElementById('you');
  var you = (state.data[state.active] || {}).you;
  if (!you) { box.classList.add('hidden'); return; }
  box.classList.remove('hidden');

  if (state.active === 'kill') {
    box.innerHTML =
      '<div class="you__badge"><div class="lbl">YOUR RANKING</div><div class="num">#' + you.rank + '</div></div>' +
      '<div class="you__pic">' + initial(you.name) + '</div>' +
      '<div class="you__info"><div class="you__name">' + esc(you.name) + '</div>' +
        '<div class="you__sub">' + badgePill(you.badge) + '</div></div>' +
      '<div class="you__stats">' +
        youStat('star', 'SCORE', you.score, 'stat-gold') +
        youStat('target', 'KILLS', you.kills, 'stat-green') +
        youStat('skull', 'DEATHS', you.deaths, 'stat-red') +
      '</div>';
  } else if (GATHER_CATS[state.active]) {
    var gc = CATS[state.active];
    box.innerHTML =
      '<div class="you__badge"><div class="lbl">YOUR RANKING</div><div class="num">#' + you.rank + '</div></div>' +
      '<div class="you__pic">' + initial(you.name) + '</div>' +
      '<div class="you__info"><div class="you__name">' + esc(you.name) + '</div>' +
        '<div class="you__sub">' + badgePill(you.badge) + '</div></div>' +
      '<div class="you__stats">' +
        youStat('star', 'SCORE', you.score, 'stat-gold') +
        youStat(gc.countIcon, gc.countLabel, you.count, 'stat-green') +
      '</div>';
  } else {
    box.innerHTML =
      '<div class="you__badge"><div class="lbl">YOUR CITY</div><div class="num">#' + you.rank + '</div></div>' +
      '<div class="you__pic">' + iconFor('flag') + '</div>' +
      '<div class="you__info"><div class="you__name">' + esc(you.label) + '</div>' +
        '<div class="you__sub"></div></div>' +
      '<div class="you__stats">' +
        youStat('enter', 'เข้า', you.entries, '') +
        youStat('star', 'ชนะ', you.wins, 'stat-green') +
        youStat('skull', 'แพ้', you.losses, 'stat-red') +
      '</div>';
  }
  pulse(box); // กระพริบบอกว่าอัปเดตแล้ว (ทั้งตอนสลับแท็บและตอน server live-push ค่าใหม่มา)
}
function youStat(ic, label, val, cls) {
  return '<div class="you__stat"><div class="k">' + iconFor(ic) + label + '</div>' +
         '<div class="v ' + (cls || '') + '">' + val + '</div></div>';
}

/* ── columns ── */
function renderCols() {
  var cols = document.getElementById('cols');
  cols.innerHTML = '';
  cols.style.gridTemplateColumns = CATS[state.active].grid;
  CATS[state.active].cols.forEach(function (c) {
    var d = el('div', 'col' + (c.cls ? ' ' + c.cls : ''));
    d.innerHTML = (c.ic ? '<span class="ic">' + iconFor(c.ic) + '</span>' : '') + c.t;
    cols.appendChild(d);
  });
}

/* ── rows ── */
function renderRows() {
  var wrap = document.getElementById('rows');
  var empty = document.getElementById('empty');
  var rows = (state.data[state.active] || {}).rows || [];
  wrap.innerHTML = '';
  empty.classList.toggle('hidden', rows.length > 0);
  var myRank = ((state.data[state.active] || {}).you || {}).rank;

  rows.forEach(function (r, idx) {
    var isMe = (myRank !== undefined && r.rank === myRank && r.rank !== '-');
    var row = el('div', 'row rank-' + r.rank + (isMe ? ' me' : ''));
    row.style.gridTemplateColumns = CATS[state.active].grid;
    row.style.setProperty('--i', Math.min(idx, 12)); /* เรียงเข้าทีละแถว, cap ไว้กันลิสต์ยาว (TopN 50) รอนาน */
    if (state.active === 'kill') {
      row.innerHTML =
        '<div class="rank">' + r.rank + '</div>' +
        '<div><div class="pic">' + initial(r.name) + '</div></div>' +
        '<div class="name">' + esc(r.name) + '</div>' +
        '<div>' + badgePill(r.badge) + '</div>' +
        '<div class="score">' + r.score + '</div>' +
        '<div class="green">' + r.kills + '</div>' +
        '<div class="red">' + r.deaths + '</div>';
    } else if (GATHER_CATS[state.active]) {
      row.innerHTML =
        '<div class="rank">' + r.rank + '</div>' +
        '<div><div class="pic">' + initial(r.name) + '</div></div>' +
        '<div class="name">' + esc(r.name) + '</div>' +
        '<div>' + badgePill(r.badge) + '</div>' +
        '<div class="score">' + r.score + '</div>' +
        '<div class="green">' + r.count + '</div>';
    } else {
      row.innerHTML =
        '<div class="rank">' + r.rank + '</div>' +
        '<div><div class="pic">' + iconFor('flag') + '</div></div>' +
        '<div class="name">' + esc(r.label) + '</div>' +
        '<div class="num">' + r.entries + '</div>' +
        '<div class="green">' + r.wins + '</div>' +
        '<div class="red">' + r.losses + '</div>' +
        '<div class="num">' + r.winrate + '%</div>';
    }
    wrap.appendChild(row);
  });
}

function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
  return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]; }); }

/* ── master render ── */
function render() {
  if (!state.data) return;
  if (!state.active || !CATS[state.active]) {
    state.active = (state.data.categories && state.data.categories[0] && state.data.categories[0].id) || 'kill';
  }
  renderNav();
  renderYou();
  renderCols();
  renderRows();
}

/* ── open / close ── */
function open(data) { state.data = data; if (!state.active) state.active = null; root.classList.remove('hidden'); render(); }
function update(data) { state.data = data; render(); }
function close() {
  if (root.classList.contains('hidden') || root.classList.contains('closing')) return;
  root.classList.add('closing'); // trigger lbPanelOut แล้วค่อยซ่อนจริงหลังอนิเมชันจบ (กันโดนตัดหัวด้วน)
  setTimeout(function () {
    root.classList.remove('closing');
    root.classList.add('hidden');
    post('close', {});
  }, 160);
}

document.getElementById('btn-close').addEventListener('click', close);
document.addEventListener('keydown', function (e) {
  if ((e.key === 'Escape' || e.key === 'Backspace') && !root.classList.contains('hidden')) close();
});

window.addEventListener('message', function (ev) {
  var m = ev.data || {};
  if (m.action === 'open') open(m.data);
  else if (m.action === 'update') update(m.data);
  else if (m.action === 'close') root.classList.add('hidden');
});

/* ══ DEV preview: test() ══ */
window.test = function (admin) {
  var names = ['Jo Joo','MJDEV CGGG','Arthur M.','John Marston','Sadie A.','Dutch','Micah B.','Hosea','Charles S.','Lenny'];
  var kill = [], you;
  for (var i = 0; i < names.length; i++) {
    var kills = Math.max(0, 20 - i * 2), deaths = Math.floor(Math.random() * 8), score = kills;
    var badge = score >= 150 ? { name:'GOLD', color:'#f0ca78' } : score >= 50 ? { name:'SILVER', color:'#c7ccd1' } : { name:'BRONZE', color:'#c78b4b' };
    kill.push({ rank: i + 1, name: names[i], score: score, kills: kills, deaths: deaths, badge: badge });
  }
  you = { rank: 2, name: 'MJDEV CGGG', score: 18, kills: 18, deaths: 3, badge: { name:'SILVER', color:'#c7ccd1' } };
  var cities = [
    { rank:1, label:'Valentine', entries:14, wins:9, losses:5, winrate:64 },
    { rank:2, label:'Rhodes',    entries:12, wins:6, losses:6, winrate:50 },
    { rank:3, label:'Annesburg', entries:10, wins:3, losses:7, winrate:30 }
  ];
  function gatherBadge(score, scale) {
    for (var k = scale.length - 1; k >= 0; k--) if (score >= scale[k].min) return { name: scale[k].name, color: scale[k].color };
    return scale[0];
  }
  function makeGather(maxScore, divisor, scale) {
    var rows = [], youRow;
    for (var g = 0; g < names.length; g++) {
      var gScore = Math.max(0, maxScore - g * Math.round(maxScore / names.length));
      var gCount = Math.round(gScore / divisor);
      rows.push({ rank: g + 1, name: names[g], score: gScore, count: gCount, badge: gatherBadge(gScore, scale) });
    }
    youRow = { rank: 2, name: 'MJDEV CGGG', score: rows[1].score, count: rows[1].count, badge: rows[1].badge };
    return { rows: rows, you: youRow };
  }
  var badgeScale = [
    { min: 0,    name:'BRONZE',   color:'#c78b4b' },
    { min: 80,   name:'SILVER',   color:'#c7ccd1' },
    { min: 250,  name:'GOLD',     color:'#f0ca78' },
    { min: 600,  name:'PLATINUM', color:'#7fe0d4' },
    { min: 1200, name:'DIAMOND',  color:'#8ab6ff' }
  ];
  var fishBoard     = makeGather(1800, 3, badgeScale);
  var miningBoard   = makeGather(1300, 4, badgeScale);
  var plantingBoard = makeGather(1100, 5, badgeScale);
  var lumberBoard   = makeGather(1600, 3, badgeScale);

  open({ isAdmin: admin !== false,
    groups: { jobs: { label:'JOBS', icon:'briefcase' } },
    categories: [
      { id:'kill',     label:'KILL RANK',       th:'อันดับสังหาร' },
      { id:'city',     label:'CITY RANK',       th:'อันดับเมือง' },
      { id:'fish',     label:'FISH RANK',       th:'อันดับตกปลา',        group:'jobs' },
      { id:'mining',   label:'MINING RANK',     th:'อันดับขุดเหมืองทอง',  group:'jobs' },
      { id:'planting', label:'FARMING RANK',    th:'อันดับปลูกต้นไม้',    group:'jobs' },
      { id:'lumber',   label:'LUMBERJACK RANK', th:'อันดับตัดไม้',        group:'jobs' }
    ], kill: { rows: kill, you: you },
        city: { rows: cities, you: { rank:1, label:'Valentine', entries:14, wins:9, losses:5, winrate:64 } },
        fish: fishBoard, mining: miningBoard, planting: plantingBoard, lumber: lumberBoard });
  console.log('[lb] test rendered');
};
(function () {
  var inNui = false;
  try { inNui = (typeof window.GetParentResourceName === 'function'); } catch (e) {}
  if (!inNui) window.test(true);
})();
