/* =========================================================================
   bcc-stables — NUI ใหม่ (vanilla) แทน Vue app เดิม
   หน้าจอเดียว: ม้า 3D โชว์ผ่านจอโปร่ง, panel stats ซ้าย/saddlebag ขวา,
   แถบล่าง (action-bar-wrap) สลับ 3 โหมด: main (actions) / shop (ซื้อม้า) / tack (แต่งอาน)
   ปุ่ม action = ไอคอนล้วน (hover โชว์ชื่อ, คลิก→ผลเด้ง pNotify ผ่าน client callback)
   ส่ง "คำขอ" ผ่าน RegisterNUICallback เดิมของ client/main.lua เท่านั้น
   ========================================================================= */

const RES = (window.GetParentResourceName && GetParentResourceName()) || 'bcc-stables';
function nui(name, payload) {
  return fetch(`https://${RES}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload || {}),
  }).catch(() => {});
}
// แจ้งเตือน = pNotify ฝั่งเกม (ผ่าน client callback stableNotify) แทน toast ใน NUI
function notify(text, kind) { nui('stableNotify', { text: text, kind: kind || 'info' }); }

/* ===================== state ===================== */
let DATA = { shopData: [], compData: {}, translations: {}, currencyType: 2, location: '', healPrice: 500, healCurrencyLabel: '$' };
let myHorses = [];
let selIdx = 0;
let mode = 'main';        // 'main' | 'shop' | 'tack'
let shopSelKey = null;    // "<breedIdx>|<model>"
let tackCat = null;
let tackPending = {};      // { <category>: hash } เลือกยังไม่บันทึก (คิดราคา)

/* ปุ่ม main mode (แถบล่าง) — ไอคอนล้วน ชื่อโชว์ตอน hover / ผลเด้ง pNotify ตอนคลิก
   แต่งอาน + ปล่อยม้า ย้ายไปอยู่ panel ขวาข้างปุ่มเปิดกระเป๋าแล้ว (เป็นของเฉพาะตัวม้านั้น) */
const ACTIONS = [
  { key: 'summon',  ico: 'fa-horse-head',    name: 'เรียกม้า' },
  { key: 'return',  ico: 'fa-warehouse',     name: 'ส่งม้ากลับโรงม้า' },
  { key: 'heal',    ico: 'fa-kit-medical',   name: 'รักษาม้า' },
  { key: 'setmain', ico: 'fa-star',          name: 'ตั้งเป็นม้าตัวหลัก' },
  { key: 'shop',    ico: 'fa-cart-shopping', name: 'ซื้อม้า' },
];

/* 4 สถิติสายพันธุ์ (จาก config/horses.lua) — ไม่รวม health/stamina แล้ว (แยกไปโชว์เป็นสภาพจริง) */
const STATS = [
  { key: 'speed',        ico: 'fa-gauge-high',    label: 'ความเร็ว' },
  { key: 'acceleration', ico: 'fa-forward',       label: 'อัตราเร่ง' },
  { key: 'agility',      ico: 'fa-wind',          label: 'ความคล่องตัว' },
  { key: 'courage',      ico: 'fa-shield-halved', label: 'ความกล้าหาญ' },
];
const STAT_MAX = 10;
/* สภาพปัจจุบัน HP/สเตมิน่า (0-100 จริงจาก DB — ปุ่มรักษาม้าทำให้ขึ้นจริง) */
const CONDITIONS = [
  { key: 'health',  ico: 'fa-heart', label: 'พลังชีวิต', color: '#e05a5a' },
  { key: 'stamina', ico: 'fa-bolt',  label: 'สเตมิน่า',  color: '#5ac0e0' },
];
const TACK_CATS = ['Saddles', 'Saddlecloths', 'Stirrups', 'SaddleBags', 'Manes', 'Tails',
  'SaddleHorns', 'Bedrolls', 'Masks', 'Mustaches', 'Holsters', 'Bridles', 'Horseshoes'];

/* ===================== elements ===================== */
const root = document.getElementById('stable-root');
const el = (id) => document.getElementById(id);

// tooltip ลอย (hover ปุ่มไอคอน) — เบา ไม่ยิง pNotify กันสแปม
const tip = document.createElement('div');
tip.id = 'hover-tip'; tip.className = 'hidden';
document.body.appendChild(tip);
function showTip(text, x, y) { tip.textContent = text; tip.style.left = x + 'px'; tip.style.top = (y - 40) + 'px'; tip.classList.remove('hidden'); }
function hideTip() { tip.classList.add('hidden'); }

/* ===================== helpers ===================== */
function t(key, fb) { return (DATA.translations && DATA.translations[key]) || fb || key; }
function genderLabel(g) { return g === 'male' ? 'เพศผู้' : g === 'female' ? 'เพศเมีย' : 'ไม่ทราบเพศ'; }
function currentHorse() { return myHorses[selIdx] || null; }
// currencyType=1 (ทองอย่างเดียว) โชว์ทอง, นอกนั้นจ่ายเงินสดเสมอ (ตัดสินใจแล้วว่าจ่ายสดพอ ไม่มีปุ่มสลับ)
function priceText(cash, gold) {
  if (DATA.currencyType === 1) return `${gold} ทอง`;
  return `$${cash}`;
}

/* ===================== header / stats / saddlebag ===================== */
function renderHeader() {
  const h = currentHorse();
  if (!h) { el('horse-name').textContent = t('noPersonalHorse', 'ไม่มีม้า'); el('horse-meta').textContent = ''; return; }
  el('horse-name').textContent = h.name || '—';
  const parts = [];
  if (h.breedLabel) parts.push(h.breedLabel);
  parts.push(genderLabel(h.gender));
  parts.push(`ความผูกพัน Lv. ${h.bondLevel != null ? h.bondLevel : 1}`);
  parts.push(`XP ${h.xp != null ? h.xp : 0}`);
  el('horse-meta').textContent = parts.join(' • ');
}
function statValue(h, key) {
  if (h && h.stats && typeof h.stats[key] === 'number') return h.stats[key];
  return 4; // ไม่ได้กำหนดใน config → ค่าเริ่มต้น 4/10
}
function renderStats() {
  const h = currentHorse();
  el('stat-rows').innerHTML = STATS.map((s) => {
    const v = Math.max(0, Math.min(STAT_MAX, statValue(h, s.key)));
    const segs = Array.from({ length: STAT_MAX }, (_, i) => `<span class="stat-seg${i < v ? ' on' : ''}"></span>`).join('');
    return `<div class="stat-row"><span class="stat-ico"><i class="fa-solid ${s.ico}"></i></span><span class="stat-label">${s.label}</span><span class="stat-bar">${segs}</span><span class="stat-num">${v} / ${STAT_MAX}</span></div>`;
  }).join('');
}
// สภาพปัจจุบัน HP/สเตมิน่า (0-100 จริง) — แถบ % จริง รักษาแล้วอัปเดต
function renderCondition() {
  const h = currentHorse();
  el('cond-rows').innerHTML = CONDITIONS.map((c) => {
    const raw = (h && typeof h[c.key] === 'number') ? h[c.key] : 0;
    const pct = Math.max(0, Math.min(100, raw));
    return `<div class="cond-row">
        <i class="fa-solid ${c.ico} cond-ico" style="color:${c.color}"></i>
        <div class="cond-bar"><div class="cond-fill" style="width:${pct}%;background:${c.color}"></div></div>
        <span class="cond-num">${Math.round(pct)}</span>
      </div>`;
  }).join('');
}
function renderSaddlebag() {
  const h = currentHorse();
  el('sb-slot-count').textContent = (h && h.slots != null) ? h.slots : 0;
}
function renderMineInfo() { renderHeader(); renderStats(); renderCondition(); renderSaddlebag(); }

// พรีวิวม้าตัวที่ selIdx (main mode)
function previewCurrent() {
  const h = currentHorse();
  renderMineInfo();
  if (!h) return;
  nui('loadMyHorse', { HorseId: h.id, HorseComp: h.components || '{}', HorseModel: h.model, HorseGender: h.gender });
}
function selectHorseIndex(idx) {
  if (!myHorses.length) return;
  selIdx = (idx + myHorses.length) % myHorses.length;
  previewCurrent();
}

/* ===================== ACTION BAR — render per mode ===================== */
function iconBtn(cls, dataAttrs, ico, tipText) {
  return `<button class="${cls}" ${dataAttrs} data-tip="${tipText || ''}" type="button"><span class="ab-ico"><i class="fa-solid ${ico}"></i></span></button>`;
}

function renderBar() {
  const bar = el('action-bar');
  if (mode === 'main') {
    bar.innerHTML = ACTIONS.map((a) => {
      const tipText = a.key === 'heal' ? `${a.name} (${DATA.healCurrencyLabel}${DATA.healPrice})` : a.name;
      return iconBtn('action-btn', `data-act="${a.key}"`, a.ico, tipText);
    }).join('');
    bar.querySelectorAll('.action-btn').forEach((b) => b.addEventListener('click', () => onAction(b.dataset.act)));
  } else if (mode === 'shop') {
    const cards = [];
    DATA.shopData.forEach((breed, bi) => {
      const colors = breed.colors || {};
      Object.keys(colors).forEach((model) => {
        const c = colors[model]; const key = `${bi}|${model}`;
        cards.push(`<button class="shop-slot${shopSelKey === key ? ' active' : ''}" data-key="${key}" data-model="${model}" data-tip="${breed.breed} • ${c.color || ''}" type="button">
            <span class="ss-breed">${breed.breed}</span><span class="ss-color">${c.color || ''}</span><span class="ss-price">${priceText(c.cashPrice, c.goldPrice)}</span>
          </button>`);
      });
    });
    bar.innerHTML = cards.join('') || '<span class="bar-empty">ไม่มีม้าให้ซื้อ</span>';
    bar.querySelectorAll('.shop-slot').forEach((s) => s.addEventListener('click', () => openShopSlot(s.dataset.key, s.dataset.model)));
  } else if (mode === 'tack') {
    if (!tackCat) { bar.innerHTML = '<span class="bar-empty">เลือกหมวดอุปกรณ์ด้านบน</span>'; return; }
    const opts = DATA.compData[tackCat] || [];
    const rows = [`<button class="tack-slot${tackPending[tackCat] === 0 ? ' active' : ''}" data-id="-1" data-hash="" data-tip="ถอดออก" type="button"><span class="ab-ico"><i class="fa-solid fa-xmark"></i></span><span class="ts-label">ถอด</span></button>`];
    opts.forEach((o, i) => {
      const active = tackPending[tackCat] === o.hash;
      rows.push(`<button class="tack-slot${active ? ' active' : ''}" data-id="${i}" data-hash="${o.hash}" data-tip="#${i + 1} ${priceText(o.cashPrice, o.goldPrice)}" type="button"><span class="ts-label">#${i + 1}</span><span class="ts-price">${priceText(o.cashPrice, o.goldPrice)}</span></button>`);
    });
    bar.innerHTML = rows.join('');
    bar.querySelectorAll('.tack-slot').forEach((s) => s.addEventListener('click', () => onTackPick(s.dataset.id, s.dataset.hash)));
  }
  // hover tooltip (ทุกโหมด)
  bar.querySelectorAll('[data-tip]').forEach((b) => {
    b.addEventListener('mouseenter', (e) => { const r = b.getBoundingClientRect(); if (b.dataset.tip) showTip(b.dataset.tip, r.left + r.width / 2, r.top); });
    b.addEventListener('mouseleave', hideTip);
  });
}

/* ===================== mode-context (row above bar) ===================== */
function renderContext() {
  const ctx = el('mode-context');
  if (mode === 'shop') {
    const info = shopSelKey ? findShopColor(shopSelKey) : null;
    if (info && info.cfg) {
      ctx.innerHTML = `<span class="ctx-name">${info.breed.breed} • ${info.cfg.color || ''}</span>
        <span class="ctx-price">${priceText(info.cfg.cashPrice, info.cfg.goldPrice)}</span>
        <button id="ctx-buy" type="button">ซื้อม้า</button>`;
      el('ctx-buy').addEventListener('click', onBuy);
    } else {
      ctx.innerHTML = '<span class="ctx-hint">เลือกม้าจากแถบด้านล่างเพื่อดูตัวอย่าง</span>';
    }
    ctx.classList.remove('hidden');
  } else if (mode === 'tack') {
    const chips = TACK_CATS.filter((cat) => Array.isArray(DATA.compData[cat]) && DATA.compData[cat].length)
      .map((cat) => `<button class="tack-chip${tackCat === cat ? ' active' : ''}" data-cat="${cat}" type="button">${t(cat, cat)}</button>`).join('');
    ctx.innerHTML = `<div class="tack-chips">${chips}</div><button id="ctx-tack-save" type="button">บันทึก</button>`;
    ctx.querySelectorAll('.tack-chip').forEach((c) => c.addEventListener('click', () => { tackCat = c.dataset.cat; renderContext(); renderBar(); }));
    el('ctx-tack-save').addEventListener('click', onTackSave);
    ctx.classList.remove('hidden');
  } else {
    ctx.classList.add('hidden');
    ctx.innerHTML = '';
  }
}

/* ===================== mode switching ===================== */
function setMode(m) {
  mode = m;
  hideRelease();
  const main = (m === 'main');
  // panels/selector/rotate เฉพาะ main mode
  el('stat-panel').classList.toggle('hidden', !main);
  el('saddlebag-panel').classList.toggle('hidden', !main);
  el('sel-prev').classList.toggle('hidden', !main);
  el('sel-next').classList.toggle('hidden', !main);
  el('btn-back').textContent = main ? '‹ ย้อนกลับ' : '‹ กลับ';
  if (m === 'main') previewCurrent();
  else if (m === 'shop') { shopSelKey = null; }
  else if (m === 'tack') { const cats = TACK_CATS.filter((c) => Array.isArray(DATA.compData[c]) && DATA.compData[c].length); tackCat = cats[0] || null; }
  renderContext();
  renderBar();
}

/* ===================== action handlers ===================== */
function onAction(key) {
  const h = currentHorse();
  switch (key) {
    case 'summon': nui('summonHorse', {}); notify('กำลังเรียกม้า...'); break;
    case 'return': nui('returnHorse', {}); notify('ส่งม้ากลับโรงม้าแล้ว'); break;
    case 'shop': setMode('shop'); break;
    case 'heal':
      if (!h) return; nui('healHorse', { horseId: h.id }); break; // ผลเด้ง pNotify จาก server (Core.NotifyRightTip)
    case 'setmain':
      if (!h) return;
      nui('selectHorse', { horseId: h.id });
      myHorses.forEach((x) => (x.selected = 0)); h.selected = 1;
      notify('ตั้งเป็นม้าตัวหลักแล้ว', 'success');
      break;
  }
}

/* ปล่อยม้า — ต้องยืนยันผ่าน popup ก่อน (btn-release → โชว์ #release-confirm → rc-yes) */
function askRelease() {
  const h = currentHorse();
  if (!h) return;
  el('rc-name').textContent = h.name || '';
  el('release-confirm').classList.remove('hidden');
}
function hideRelease() { el('release-confirm').classList.add('hidden'); }
function doRelease() {
  const h = currentHorse();
  hideRelease();
  if (!h) return;
  nui('sellHorse', { horseId: h.id, captured: h.captured });
  myHorses.splice(selIdx, 1);
  if (selIdx >= myHorses.length) selIdx = Math.max(0, myHorses.length - 1);
  if (myHorses.length) previewCurrent(); else renderMineInfo();
  notify('ปล่อยม้าแล้ว', 'success');
}

/* ===================== shop ===================== */
function findShopColor(key) {
  const [bi, model] = key.split('|');
  const breed = DATA.shopData[Number(bi)];
  if (!breed) return null;
  return { breed, model, cfg: (breed.colors || {})[model] };
}
function openShopSlot(key, model) {
  shopSelKey = key;
  nui('loadHorse', { horseModel: model });
  renderBar(); renderContext();
}
function onBuy() {
  if (!shopSelKey) { notify('เลือกม้าก่อน', 'warning'); return; }
  const info = findShopColor(shopSelKey);
  if (!info || !info.cfg) return;
  const isCash = DATA.currencyType !== 1;
  nui('BuyHorse', { ModelH: info.model, IsCash: isCash, gender: 'male', captured: 0, cashPrice: info.cfg.cashPrice, goldPrice: info.cfg.goldPrice });
}

/* ===================== tack ===================== */
function onTackPick(id, hash) {
  nui(tackCat, { id: id, hash: hash });
  tackPending[tackCat] = (id === '-1') ? 0 : hash;
  renderBar();
}
function onTackSave() {
  let cash = 0, gold = 0;
  Object.keys(tackPending).forEach((cat) => {
    const hash = tackPending[cat]; if (!hash) return;
    const opt = (DATA.compData[cat] || []).find((o) => o.hash === hash);
    if (opt) { cash += opt.cashPrice || 0; gold += opt.goldPrice || 0; }
  });
  nui('CloseStable', { MenuAction: 'save', cashPrice: cash, goldPrice: gold, currencyType: DATA.currencyType === 1 ? 1 : 0 });
  root.classList.add('hidden');
}

/* ===================== open / close ===================== */
function openUI(p) {
  DATA.shopData = Array.isArray(p.shopData) ? p.shopData : [];
  DATA.compData = p.compData || {};
  DATA.translations = p.translations || {};
  DATA.currencyType = (typeof p.currencyType === 'number') ? p.currencyType : 2;
  DATA.location = p.location || '';
  if (typeof p.healPrice === 'number') DATA.healPrice = p.healPrice;
  if (p.healCurrencyLabel) DATA.healCurrencyLabel = p.healCurrencyLabel;
  myHorses = Array.isArray(p.myHorsesData) ? p.myHorsesData.slice() : [];
  selIdx = myHorses.findIndex((h) => Number(h.selected) === 1);
  if (selIdx < 0) selIdx = 0;
  tackPending = {};
  el('top-datetime').textContent = DATA.location || '';
  setMode('main');
  root.classList.remove('hidden');
}
function closeUI() {
  root.classList.add('hidden');
  hideTip();
  nui('CloseStable', { MenuAction: 'cancel' });
}

/* ===================== events ===================== */
el('btn-back').addEventListener('click', () => { if (mode !== 'main') setMode('main'); else closeUI(); });
el('sel-prev').addEventListener('click', () => selectHorseIndex(selIdx - 1));
el('sel-next').addEventListener('click', () => selectHorseIndex(selIdx + 1));
el('btn-cargo').addEventListener('click', () => { const h = currentHorse(); if (h) nui('openCargo', { horseId: h.id }); });
el('btn-tack').addEventListener('click', () => setMode('tack'));
el('btn-release').addEventListener('click', askRelease);
el('rc-yes').addEventListener('click', doRelease);
el('rc-no').addEventListener('click', hideRelease);
// กดค้างหมุนต่อเนื่อง — ยิง rotate ซ้ำทุก 90ms ระหว่างกด (client หมุน ~6°/ครั้ง → ~66°/วิ)
let rotTimer = null;
function startRotate(dir) { nui('rotate', { RotateHorse: dir }); clearInterval(rotTimer); rotTimer = setInterval(() => nui('rotate', { RotateHorse: dir }), 90); }
function stopRotate() { clearInterval(rotTimer); rotTimer = null; }
document.querySelectorAll('.rot-btn').forEach((b) => {
  b.addEventListener('mousedown', () => startRotate(b.dataset.dir));
  b.addEventListener('mouseup', stopRotate);
  b.addEventListener('mouseleave', stopRotate);
});
el('ab-prev').addEventListener('click', () => { el('action-bar').scrollLeft -= 240; });
el('ab-next').addEventListener('click', () => { el('action-bar').scrollLeft += 240; });
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') { if (mode !== 'main') setMode('main'); else closeUI(); } });

window.addEventListener('message', (ev) => {
  const d = ev.data || {};
  if (d.action === 'show') openUI(d);
  else if (d.action === 'hide') { root.classList.add('hidden'); hideTip(); }
  else if (d.action === 'healed') {
    // server รักษาม้าสำเร็จ → อัปเดต HP/สเตมิน่าของม้าตัวนั้นในรายการเป็นเต็ม แล้ว re-render แถบสภาพ
    const h = myHorses.find((x) => Number(x.id) === Number(d.horseId));
    if (h) { h.health = 100; h.stamina = 100; h.dead = 0; h.writhe = 0; }
    if (mode === 'main') renderCondition();
  }
});

/* DEV mock */
if (window.location.protocol !== 'nui:' && window.location.protocol !== 'https:') {
  openUI({
    location: 'Valentine Stable', currencyType: 2, healPrice: 500,
    shopData: [{ breed: 'Morgan', colors: {
      'a_c_horse_morgan_bay': { color: 'Bay', cashPrice: 130, goldPrice: 6, invLimit: 30 },
      'a_c_horse_morgan_palomino': { color: 'Palomino', cashPrice: 150, goldPrice: 7, invLimit: 30 },
    } }],
    compData: { Saddles: [{ hash: '0x003897CA', cashPrice: 10, goldPrice: 1 }], Manes: [{ hash: '0xAA0217AB', cashPrice: 5, goldPrice: 1 }] },
    translations: { Saddles: 'อาน', Manes: 'แผงคอ' },
    myHorsesData: [
      { id: 1, name: 'DaGo', model: 'a_c_horse_morgan_bay', components: '{}', gender: 'male', xp: 2, health: 100, stamina: 100, selected: 1, captured: 0, breedLabel: 'Morgan', bondLevel: 1, slots: 30, stats: { health: 4, stamina: 4, speed: 4, acceleration: 4, agility: 4, courage: 4 } },
    ],
  });
}
