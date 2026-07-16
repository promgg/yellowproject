/* =========================================================================
   bcc-stables — NUI logic.
   Visual layout ported from ui/mockup.js/mockup.html (list-panel / preview-
   stage / detail-panel / shortcut-bar / mode-switcher, 3rd "tack" mode added).
   Every RegisterNUICallback call, payload shape, and message-listener
   contract is preserved 1:1 from the previous working app.js — verified
   against client/main.lua's RegisterNUICallback list. No callback names
   were invented; see report for the two intentional small UX additions
   (gender toggle on purchase, live tack total) called out separately.
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
let shopGender = 'male';  // เพศตอนซื้อม้า (เพิ่มจาก mockup — server รองรับอยู่แล้ว ไม่แตะ client/server lua)
let tackCat = null;
let tackPending = {};     // { <category>: hash } เลือกยังไม่บันทึก (คิดราคา)

/* 4 สถิติสายพันธุ์ (จาก config/horses.lua) — ไม่รวม health/stamina (แยกไปโชว์เป็นสภาพจริง) */
const STATS = [
  { key: 'speed',        ico: 'fa-gauge-high',    label: 'ความเร็ว' },
  { key: 'acceleration', ico: 'fa-forward',       label: 'อัตราเร่ง' },
  { key: 'agility',      ico: 'fa-wind',          label: 'ความคล่องตัว' },
  { key: 'courage',      ico: 'fa-shield-halved', label: 'ความกล้าหาญ' },
];
const STAT_MAX = 10;
const CONDITIONS = ['health', 'stamina'];
const TACK_CATS = ['Saddles', 'Saddlecloths', 'Stirrups', 'SaddleBags', 'Manes', 'Tails',
  'SaddleHorns', 'Bedrolls', 'Masks', 'Mustaches', 'Holsters', 'Bridles', 'Horseshoes'];

/* ===================== elements ===================== */
const root = document.getElementById('stable-root');
const el = (id) => document.getElementById(id);

// tooltip ลอย (hover) — เบา ไม่ยิง pNotify กันสแปม
const tip = document.createElement('div');
tip.id = 'hover-tip'; tip.className = 'hidden';
document.body.appendChild(tip);
function showTip(text, x, y) { tip.textContent = text; tip.style.left = x + 'px'; tip.style.top = (y - 34) + 'px'; tip.classList.remove('hidden'); }
function hideTip() { tip.classList.add('hidden'); }
function wireTip(node, text) {
  if (!text) return;
  node.addEventListener('mouseenter', () => { const r = node.getBoundingClientRect(); showTip(text, r.left + r.width / 2, r.top); });
  node.addEventListener('mouseleave', hideTip);
}

/* ===================== helpers ===================== */
function t(key, fb) { return (DATA.translations && DATA.translations[key]) || fb || key; }
function genderLabel(g) { return g === 'male' ? 'เพศผู้' : g === 'female' ? 'เพศเมีย' : 'ไม่ทราบเพศ'; }
function currentHorse() { return myHorses[selIdx] || null; }
// currencyType=1 (ทองอย่างเดียว) โชว์ทอง, นอกนั้นจ่ายเงินสดเสมอ
function priceText(cash, gold) {
  if (DATA.currencyType === 1) return `${gold} ทอง`;
  return `$${cash}`;
}
function statValue(statsObj, key) {
  if (statsObj && typeof statsObj[key] === 'number') return statsObj[key];
  return 4; // ไม่ได้กำหนดใน config → ค่าเริ่มต้น 4/10
}
function statDots(value) {
  const v = Math.max(0, Math.min(STAT_MAX, value));
  return Array.from({ length: STAT_MAX }, (_, i) => `<b class="${i < v ? 'on' : ''}"></b>`).join('');
}
function statGridMarkup(statsObj) {
  return STATS.map((s) => {
    const v = statValue(statsObj, s.key);
    return `<div class="stat-item"><i class="fa-solid ${s.ico}"></i><span>${s.label}</span><strong>${v}/${STAT_MAX}</strong><div class="stat-dots">${statDots(v)}</div></div>`;
  }).join('');
}

/* ===================== MAIN mode: owned horses ===================== */
function renderOwnedList() {
  const list = el('owned-list');
  if (!myHorses.length) {
    list.innerHTML = '<div class="card-empty">ยังไม่มีม้าในโรงม้า</div>';
    return;
  }
  list.innerHTML = myHorses.map((h, i) => `
    <button class="horse-card${i === selIdx ? ' active' : ''}${h.dead ? ' dead' : ''}" type="button" data-index="${i}">
      <span class="horse-thumb"><i class="fa-solid fa-horse-head"></i></span>
      <span>
        <strong>${h.name || '—'}</strong>
        <small>${h.breedLabel || ''}</small>
        <span class="card-meta"><span>ผูกพัน Lv.${h.bondLevel != null ? h.bondLevel : 1}</span><span>${h.slots != null ? h.slots : 0} ช่อง</span></span>
      </span>
      ${Number(h.selected) === 1 ? '<em class="selected-pin">ม้าหลัก</em>' : ''}
    </button>`).join('');
  list.querySelectorAll('[data-index]').forEach((b) => b.addEventListener('click', () => selectHorseIndex(Number(b.dataset.index))));
}
function renderMainPreview() {
  const h = currentHorse();
  el('preview-index').textContent = myHorses.length ? String(selIdx + 1).padStart(2, '0') : '00';
  el('preview-total').textContent = `/ ${String(myHorses.length).padStart(2, '0')}`;

  if (!h) {
    el('preview-breed').textContent = '';
    el('preview-name').textContent = t('noPersonalHorse', 'ไม่มีม้า');
    el('preview-subtitle').textContent = '';
    el('bond-label').textContent = '—';
    el('slot-label').textContent = '—';
    el('cond-health-bar').style.width = '0%'; el('cond-health-num').textContent = '0%';
    el('cond-stamina-bar').style.width = '0%'; el('cond-stamina-num').textContent = '0%';
    el('owned-stats').innerHTML = '';
    setMainActionsEnabled(false);
    return;
  }
  el('preview-breed').textContent = (h.breedLabel || '').toUpperCase();
  el('preview-name').textContent = h.name || '—';
  el('preview-subtitle').textContent = [h.colorLabel, genderLabel(h.gender)].filter(Boolean).join(' · ');
  el('bond-label').textContent = `ระดับ ${h.bondLevel != null ? h.bondLevel : 1}`;
  el('slot-label').textContent = `${h.slots != null ? h.slots : 0} ช่อง`;

  const hp = Math.max(0, Math.min(100, typeof h.health === 'number' ? h.health : 0));
  const st = Math.max(0, Math.min(100, typeof h.stamina === 'number' ? h.stamina : 0));
  el('cond-health-bar').style.width = hp + '%'; el('cond-health-num').textContent = Math.round(hp) + '%';
  el('cond-stamina-bar').style.width = st + '%'; el('cond-stamina-num').textContent = Math.round(st) + '%';

  el('owned-stats').innerHTML = statGridMarkup(h.stats);
  el('heal-label').textContent = `รักษาม้า · ${DATA.healCurrencyLabel}${DATA.healPrice}`;
  setMainActionsEnabled(true);
}
function setMainActionsEnabled(enabled) {
  ['btn-summon', 'btn-cargo', 'btn-tack', 'btn-return', 'btn-setmain', 'btn-heal', 'btn-release'].forEach((id) => { el(id).disabled = !enabled; });
}
function renderOwnedCount() {
  el('tab-count-main').textContent = String(myHorses.length);
  el('owned-count').textContent = `${myHorses.length} ตัว`;
}
function previewCurrent() {
  renderOwnedList();
  renderMainPreview();
  const h = currentHorse();
  if (!h) return;
  nui('loadMyHorse', { HorseId: h.id, HorseComp: h.components || '{}', HorseModel: h.model, HorseGender: h.gender });
}
function selectHorseIndex(idx) {
  if (!myHorses.length) return;
  selIdx = (idx + myHorses.length) % myHorses.length;
  previewCurrent();
}

/* ===================== SHOP mode ===================== */
function shopEntries() {
  const out = [];
  (DATA.shopData || []).forEach((breed, bi) => {
    const colors = breed.colors || {};
    Object.keys(colors).forEach((model) => out.push({ bi, model, breed, cfg: colors[model] }));
  });
  return out;
}
function findShopColor(key) {
  const [bi, model] = key.split('|');
  const breed = DATA.shopData[Number(bi)];
  if (!breed) return null;
  return { breed, model, cfg: (breed.colors || {})[model] };
}
function renderShopList() {
  const list = el('shop-list');
  const entries = shopEntries();
  el('tab-count-shop').textContent = String(entries.length);
  if (!entries.length) { list.innerHTML = '<div class="card-empty">ไม่มีม้าให้ซื้อ</div>'; return; }
  list.innerHTML = entries.map(({ bi, model, breed, cfg }) => {
    const key = `${bi}|${model}`;
    return `<button class="horse-card${shopSelKey === key ? ' active' : ''}" type="button" data-key="${key}" data-model="${model}">
      <span class="horse-thumb"><i class="fa-solid fa-horse"></i></span>
      <span>
        <strong>${breed.breed}</strong>
        <small>${cfg.color || ''}</small>
        <span class="card-meta"><span>${cfg.invLimit != null ? cfg.invLimit + ' ช่อง' : ''}</span><span class="card-price">${priceText(cfg.cashPrice, cfg.goldPrice)}</span></span>
      </span>
    </button>`;
  }).join('');
  list.querySelectorAll('[data-key]').forEach((b) => b.addEventListener('click', () => openShopSlot(b.dataset.key, b.dataset.model)));
}
function renderShopPreview() {
  const info = shopSelKey ? findShopColor(shopSelKey) : null;
  if (!info || !info.cfg) {
    el('preview-breed').textContent = '';
    el('preview-name').textContent = 'เลือกม้าจากรายการ';
    el('preview-subtitle').textContent = '';
    el('preview-index').textContent = '00'; el('preview-total').textContent = '/ 00';
    el('shop-price').textContent = '—';
    el('shop-slots').textContent = '—';
    el('shop-color').textContent = '—';
    el('shop-stats').innerHTML = '';
    el('buy-label').textContent = 'เลือกม้าจากรายการ';
    el('btn-buy').disabled = true;
    return;
  }
  const { breed, cfg } = info;
  const entries = shopEntries();
  const idx = entries.findIndex((e) => `${e.bi}|${e.model}` === shopSelKey);
  el('preview-breed').textContent = (breed.breed || '').toUpperCase();
  el('preview-name').textContent = cfg.color || breed.breed;
  el('preview-subtitle').textContent = priceText(cfg.cashPrice, cfg.goldPrice);
  el('preview-index').textContent = String(idx + 1).padStart(2, '0');
  el('preview-total').textContent = `/ ${String(entries.length).padStart(2, '0')}`;

  el('shop-price').textContent = priceText(cfg.cashPrice, cfg.goldPrice);
  el('shop-slots').textContent = cfg.invLimit != null ? `${cfg.invLimit} ช่อง` : '—';
  el('shop-color').textContent = cfg.color || '—';
  el('shop-stats').innerHTML = statGridMarkup(cfg.stats);
  el('buy-label').textContent = DATA.currencyType === 1
    ? `ซื้อด้วยทอง · ${cfg.goldPrice} ทอง`
    : `ซื้อด้วยเงินสด · $${cfg.cashPrice}`;
  el('btn-buy').disabled = false;
}
function openShopSlot(key, model) {
  shopSelKey = key;
  nui('loadHorse', { horseModel: model });
  renderShopList();
  renderShopPreview();
}
function onBuy() {
  if (!shopSelKey) { notify('เลือกม้าก่อน', 'warning'); return; }
  const info = findShopColor(shopSelKey);
  if (!info || !info.cfg) return;
  const isCash = DATA.currencyType !== 1;
  nui('BuyHorse', { ModelH: info.model, IsCash: isCash, gender: shopGender, captured: 0, cashPrice: info.cfg.cashPrice, goldPrice: info.cfg.goldPrice });
}

/* ===================== TACK mode ===================== */
function availableTackCats() { return TACK_CATS.filter((c) => Array.isArray(DATA.compData[c]) && DATA.compData[c].length); }
function computeTackTotal() {
  let cash = 0, gold = 0;
  Object.keys(tackPending).forEach((cat) => {
    const hash = tackPending[cat]; if (!hash) return;
    const opt = (DATA.compData[cat] || []).find((o) => o.hash === hash);
    if (opt) { cash += opt.cashPrice || 0; gold += opt.goldPrice || 0; }
  });
  return { cash, gold };
}
function renderTackCatList() {
  const list = el('tack-cat-list');
  const cats = availableTackCats();
  if (!cats.length) { list.innerHTML = '<div class="card-empty">ไม่มีอุปกรณ์ให้เลือก</div>'; return; }
  list.innerHTML = cats.map((cat) => {
    const count = (DATA.compData[cat] || []).length;
    return `<button class="horse-card${tackCat === cat ? ' active' : ''}" type="button" data-cat="${cat}">
      <span class="horse-thumb"><i class="fa-solid fa-layer-group"></i></span>
      <span><strong>${t(cat, cat)}</strong><small>${count} แบบ</small></span>
    </button>`;
  }).join('');
  list.querySelectorAll('[data-cat]').forEach((b) => b.addEventListener('click', () => { tackCat = b.dataset.cat; renderTackCatList(); renderTackOptions(); }));
  el('tack-cat-active-label').textContent = tackCat ? t(tackCat, tackCat) : '';
}
function renderTackOptions() {
  el('tack-cat-title').textContent = tackCat ? t(tackCat, tackCat) : 'เลือกหมวดด้านซ้าย';
  const box = el('tack-options');
  if (!tackCat) { box.innerHTML = ''; el('btn-tack-save').disabled = false; updateTackTotal(); return; }
  const opts = DATA.compData[tackCat] || [];
  const removeActive = tackPending[tackCat] === 0;
  const rows = [`<button class="tack-option${removeActive ? ' active' : ''}" type="button" data-id="-1" data-hash="">
      <i class="fa-solid fa-xmark"></i><span class="to-label">ถอดออก</span><span class="to-price"></span>
    </button>`];
  opts.forEach((o, i) => {
    const active = tackPending[tackCat] === o.hash;
    rows.push(`<button class="tack-option${active ? ' active' : ''}" type="button" data-id="${i}" data-hash="${o.hash}">
      <i class="fa-solid fa-check"></i><span class="to-label">แบบที่ ${i + 1}</span><span class="to-price">${priceText(o.cashPrice, o.goldPrice)}</span>
    </button>`);
  });
  box.innerHTML = rows.join('');
  box.querySelectorAll('[data-id]').forEach((b) => b.addEventListener('click', () => onTackPick(b.dataset.id, b.dataset.hash)));
  updateTackTotal();
}
function updateTackTotal() {
  const total = computeTackTotal();
  el('tack-total-price').textContent = priceText(total.cash, total.gold);
}
function onTackPick(id, hash) {
  if (!tackCat) return;
  nui(tackCat, { id: id, hash: hash });
  tackPending[tackCat] = (id === '-1') ? 0 : hash;
  renderTackOptions();
}
function onTackSave() {
  const total = computeTackTotal();
  nui('CloseStable', { MenuAction: 'save', cashPrice: total.cash, goldPrice: total.gold, currencyType: DATA.currencyType === 1 ? 1 : 0 });
  root.classList.add('hidden');
}

/* ===================== mode switching ===================== */
function setMode(m) {
  mode = m;
  hideRelease();
  root.dataset.mode = m;
  document.querySelectorAll('[data-mode-target]').forEach((b) => b.classList.toggle('active', b.dataset.modeTarget === m));

  if (m === 'main') {
    previewCurrent();
  } else if (m === 'shop') {
    shopSelKey = null;
    renderShopList();
    renderShopPreview();
  } else if (m === 'tack') {
    const cats = availableTackCats();
    tackCat = cats[0] || null;
    renderTackCatList();
    renderTackOptions();
  }
}
function backOrClose() { if (mode !== 'main') setMode('main'); else closeUI(); }

/* ===================== release (sell) ===================== */
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
  renderOwnedCount();
  if (myHorses.length) previewCurrent(); else { renderOwnedList(); renderMainPreview(); }
  notify('ปล่อยม้าแล้ว', 'success');
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
  shopGender = 'male';
  el('shop-gender').querySelectorAll('button').forEach((b) => b.classList.toggle('active', b.dataset.gender === 'male'));
  el('stable-location').textContent = DATA.location || '';
  renderOwnedCount();
  el('tab-count-shop').textContent = String(shopEntries().length);
  setMode('main');
  root.classList.remove('hidden');
}
function closeUI() {
  root.classList.add('hidden');
  hideTip();
  nui('CloseStable', { MenuAction: 'cancel' });
}

/* ===================== events ===================== */
el('btn-close').addEventListener('click', backOrClose);
el('preview-prev').addEventListener('click', () => selectHorseIndex(selIdx - 1));
el('preview-next').addEventListener('click', () => selectHorseIndex(selIdx + 1));
document.querySelectorAll('[data-mode-target]').forEach((b) => b.addEventListener('click', () => setMode(b.dataset.modeTarget)));

el('btn-summon').addEventListener('click', () => { nui('summonHorse', {}); notify('กำลังเรียกม้า...'); });
el('btn-return').addEventListener('click', () => { nui('returnHorse', {}); notify('ส่งม้ากลับโรงม้าแล้ว'); });
el('btn-cargo').addEventListener('click', () => { const h = currentHorse(); if (h) nui('openCargo', { horseId: h.id }); });
el('btn-tack').addEventListener('click', () => setMode('tack'));
el('btn-heal').addEventListener('click', () => { const h = currentHorse(); if (h) nui('healHorse', { horseId: h.id }); });
el('btn-setmain').addEventListener('click', () => {
  const h = currentHorse(); if (!h) return;
  nui('selectHorse', { horseId: h.id });
  myHorses.forEach((x) => (x.selected = 0)); h.selected = 1;
  renderOwnedList();
  notify('ตั้งเป็นม้าตัวหลักแล้ว', 'success');
});
el('btn-release').addEventListener('click', askRelease);
el('rc-yes').addEventListener('click', doRelease);
el('rc-no').addEventListener('click', hideRelease);

el('btn-buy').addEventListener('click', onBuy);
el('shop-gender').querySelectorAll('button').forEach((b) => b.addEventListener('click', () => {
  shopGender = b.dataset.gender;
  el('shop-gender').querySelectorAll('button').forEach((x) => x.classList.toggle('active', x === b));
}));

el('btn-tack-save').addEventListener('click', onTackSave);

// กดค้างหมุนต่อเนื่อง — ยิง rotate ซ้ำทุก 90ms ระหว่างกด (client หมุน ~6°/ครั้ง → ~66°/วิ)
let rotTimer = null;
function startRotate(dir) { nui('rotate', { RotateHorse: dir }); clearInterval(rotTimer); rotTimer = setInterval(() => nui('rotate', { RotateHorse: dir }), 90); }
function stopRotate() { clearInterval(rotTimer); rotTimer = null; }
document.querySelectorAll('.rot-btn').forEach((b) => {
  b.addEventListener('mousedown', () => startRotate(b.dataset.dir));
  b.addEventListener('mouseup', stopRotate);
  b.addEventListener('mouseleave', stopRotate);
});

// คีย์ลัด: A/D เปลี่ยนม้า (main mode), Q/E กดค้างหมุนม้า, ESC ย้อนกลับ/ปิด — ปิดขณะพิมพ์ในช่องค้นหา
let qDown = false, eDown = false;
document.addEventListener('keydown', (e) => {
  const tag = (document.activeElement && document.activeElement.tagName) || '';
  const typing = tag === 'INPUT' || tag === 'TEXTAREA';
  const k = e.key.toLowerCase();
  if (k === 'escape') { if (typing) document.activeElement.blur(); else backOrClose(); return; }
  if (typing) return;
  if (mode === 'main') {
    if (k === 'a') selectHorseIndex(selIdx - 1);
    if (k === 'd') selectHorseIndex(selIdx + 1);
  }
  if (k === 'q' && !qDown) { qDown = true; startRotate('left'); }
  if (k === 'e' && !eDown) { eDown = true; startRotate('right'); }
});
document.addEventListener('keyup', (e) => {
  const k = e.key.toLowerCase();
  if (k === 'q') { qDown = false; if (!eDown) stopRotate(); }
  if (k === 'e') { eDown = false; if (!qDown) stopRotate(); }
});

// ค้นหา (client-side filter, ไม่กระทบข้อมูลจริง)
el('owned-search').addEventListener('input', () => {
  const term = el('owned-search').value.trim().toLocaleLowerCase('th');
  el('owned-list').querySelectorAll('.horse-card[data-index]').forEach((card) => {
    const idx = Number(card.dataset.index);
    const h = myHorses[idx];
    const hay = `${h && h.name || ''} ${h && h.breedLabel || ''}`.toLocaleLowerCase('th');
    card.hidden = term && !hay.includes(term);
  });
});
el('shop-search').addEventListener('input', () => {
  const term = el('shop-search').value.trim().toLocaleLowerCase('th');
  el('shop-list').querySelectorAll('.horse-card[data-key]').forEach((card) => {
    card.hidden = term && !card.textContent.toLocaleLowerCase('th').includes(term);
  });
});

window.addEventListener('message', (ev) => {
  const d = ev.data || {};
  if (d.action === 'show') openUI(d);
  else if (d.action === 'hide') { root.classList.add('hidden'); hideTip(); }
  else if (d.action === 'healed') {
    // server รักษาม้าสำเร็จ → อัปเดต HP/สเตมิน่าของม้าตัวนั้นในรายการเป็นเต็ม แล้ว re-render
    const h = myHorses.find((x) => Number(x.id) === Number(d.horseId));
    if (h) { h.health = 100; h.stamina = 100; h.dead = 0; h.writhe = 0; }
    if (mode === 'main') renderMainPreview();
  }
});

/* DEV mock */
if (window.location.protocol !== 'nui:' && window.location.protocol !== 'https:') {
  openUI({
    location: 'Valentine Stable', currencyType: 2, healPrice: 500,
    shopData: [{ breed: 'Morgan', colors: {
      'a_c_horse_morgan_bay': { color: 'Bay', cashPrice: 130, goldPrice: 6, invLimit: 30 },
      'a_c_horse_morgan_palomino': { color: 'Palomino', cashPrice: 150, goldPrice: 7, invLimit: 30, stats: { speed: 7, acceleration: 6, agility: 8, courage: 5 } },
    } }],
    compData: { Saddles: [{ hash: '0x003897CA', cashPrice: 10, goldPrice: 1 }], Manes: [{ hash: '0xAA0217AB', cashPrice: 5, goldPrice: 1 }] },
    translations: { Saddles: 'อาน', Manes: 'แผงคอ' },
    myHorsesData: [
      { id: 1, name: 'DaGo', model: 'a_c_horse_morgan_bay', components: '{}', gender: 'male', xp: 2, health: 100, stamina: 100, selected: 1, captured: 0, breedLabel: 'Morgan', colorLabel: 'Bay', bondLevel: 1, slots: 30, stats: { speed: 4, acceleration: 4, agility: 4, courage: 4 } },
      { id: 2, name: 'Copper', model: 'a_c_horse_morgan_palomino', components: '{}', gender: 'female', xp: 40, health: 66, stamina: 54, selected: 0, captured: 0, breedLabel: 'Morgan', colorLabel: 'Palomino', bondLevel: 2, slots: 30, stats: { speed: 6, acceleration: 5, agility: 7, courage: 4 } },
    ],
  });
}
