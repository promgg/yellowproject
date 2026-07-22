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
async function nui(name, payload) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(`https://${RES}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload || {}),
    signal: controller.signal,
    });
    const text = await response.text();
    if (!text) return { ok: response.ok };
    try { return JSON.parse(text); } catch (_) { return { ok: response.ok, value: text }; }
  } catch (_) {
    return { ok: false, reason: 'callback_failed' };
  } finally {
    clearTimeout(timeout);
  }
}
// แจ้งเตือน = pNotify ฝั่งเกม (ผ่าน client callback stableNotify) แทน toast ใน NUI
function notify(text, kind) { nui('stableNotify', { text: text, kind: kind || 'info' }); }

/* ===================== state ===================== */
let DATA = { shopData: [], compData: {}, translations: {}, currencyType: 0, location: '', healPrice: 500, healCurrencyLabel: '$', stableMeta: {}, activeHorseId: null, tackColorGroups: {} };
let myHorses = [];
let selIdx = 0;
let ownedStatusFilter = 'all';
let ownedRefreshPromise = null;
let ownedRefreshTimer = null;
let mode = 'main';        // 'main' | 'shop' | 'tack'
let shopSelKey = null;    // "<breedIdx>|<model>"
let shopGender = 'male';  // runtime contract ยังส่งค่าเดิม แต่ UI ไม่ให้เลือกเพศแล้ว
let shopBreedIdx = null;
let shopStep = 'breeds';  // 'breeds' | 'colors'
let tackCat = null;
let tackOptionIndex = 0;
let tackView = 'cats';    // drill-down: 'cats' (เลือกหมวด) | 'items' (เลือกแบบ+สี)
let tackCatIndex = 0;     // ไฮไลต์หมวด (คีย์บอร์ด ↑↓) ในหน้า cats
let tackModelIndex = 0;   // ไฮไลต์แบบ/รุ่นในหน้า items (-1 = ถอดออก)
let tackPending = {};     // { <category>: hash } เลือกยังไม่บันทึก (คิดราคา)
let tackInstalled = {};
let actionBusy = false;

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
function esc(value) { return String(value == null ? '' : value).replace(/[&<>'"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[c])); }
function genderLabel(g) { return g === 'male' ? 'เพศผู้' : g === 'female' ? 'เพศเมีย' : 'ไม่ทราบเพศ'; }
function currentHorse() { return myHorses[selIdx] || null; }
function sortOwnedHorses(horses) {
  return (horses || []).map((horse, index) => ({ horse, index }))
    .sort((a, b) => ((Number(b.horse.selected) === 1 ? 1 : 0) - (Number(a.horse.selected) === 1 ? 1 : 0)) || (a.index - b.index))
    .map((entry) => entry.horse);
}
function ownedStatusKey(horse) {
  if (Number(horse && horse.dead) === 1) return 'dead';
  if (Number(horse && horse.writhe) === 1) return 'injured';
  if (DATA.activeHorseId != null && Number(DATA.activeHorseId) === Number(horse && horse.id)) return 'active';
  return 'stable';
}
function replaceOwnedHorses(horses, preferredHorseId) {
  myHorses = sortOwnedHorses(Array.isArray(horses) ? horses.slice() : []);
  let nextIndex = preferredHorseId == null ? -1 : myHorses.findIndex((h) => Number(h.id) === Number(preferredHorseId));
  if (nextIndex < 0) nextIndex = myHorses.findIndex((h) => Number(h.selected) === 1);
  selIdx = nextIndex < 0 ? 0 : nextIndex;
}
// เซิร์ฟเวอร์นี้ใช้เงินสดเท่านั้น จึงไม่แสดงสกุลทองใน UX
function priceText(cash) { return `$${Number(cash || 0).toLocaleString('en-US')}`; }
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
  renderOwnedStatusTabs();
  if (!myHorses.length) {
    list.innerHTML = '<div class="card-empty"><i class="fa-solid fa-horse-head"></i><strong>ยังไม่มีม้าในคอก</strong><span>เลือกม้าตัวแรกของคุณจากร้านม้า</span><button id="empty-go-shop" type="button">ไปที่ร้านม้า</button></div>';
    el('empty-go-shop').addEventListener('click', () => setMode('shop'));
    return;
  }
  const term = el('owned-search').value.trim().toLocaleLowerCase('th');
  const visibleHorses = myHorses.map((h, i) => ({ h, i })).filter(({ h }) => {
    if (ownedStatusFilter !== 'all' && ownedStatusKey(h) !== ownedStatusFilter) return false;
    const haystack = `${h.name || ''} ${h.breedLabel || ''}`.toLocaleLowerCase('th');
    return !term || haystack.includes(term);
  });
  if (!visibleHorses.length) {
    list.innerHTML = '<div class="card-empty"><i class="fa-solid fa-filter-circle-xmark"></i><strong>ไม่พบม้าในรายการนี้</strong><span>ลองเลือกสถานะอื่นหรือล้างคำค้นหา</span></div>';
    return;
  }
  list.innerHTML = visibleHorses.map(({ h, i }) => `
    <button class="horse-card${i === selIdx ? ' active' : ''}${h.dead ? ' dead' : ''}" type="button" data-index="${i}">
      <span class="horse-thumb"><i class="fa-solid fa-horse-head"></i></span>
      <span>
        <strong>${esc(h.name || '—')}</strong>
        <small>${esc(h.breedLabel || '')}</small>
        <span class="card-meta"><span>ผูกพัน Lv.${h.bondLevel != null ? h.bondLevel : 1}</span><span>${h.slots != null ? h.slots : 0} ช่อง</span></span>
      </span>
      <span class="horse-state">${esc(horseState(h).label)}</span>
      ${Number(h.selected) === 1 ? '<em class="selected-pin">ม้าหลัก</em>' : ''}
    </button>`).join('');
  list.querySelectorAll('[data-index]').forEach((b) => b.addEventListener('click', () => selectHorseIndex(Number(b.dataset.index))));
}
function renderOwnedStatusTabs() {
  const counts = { all: myHorses.length, active: 0, stable: 0, injured: 0, dead: 0 };
  myHorses.forEach((horse) => { counts[ownedStatusKey(horse)] += 1; });
  Object.keys(counts).forEach((key) => {
    const count = el(`owned-status-${key}-count`);
    if (count) count.textContent = String(counts[key]);
  });
  document.querySelectorAll('[data-owned-status]').forEach((button) => {
    const key = button.dataset.ownedStatus;
    button.classList.toggle('active', key === ownedStatusFilter);
    button.disabled = key !== 'all' && counts[key] === 0;
  });
}
function renderMainPreview() {
  const h = currentHorse();

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
  applyHorseActions(h);
}
function setMainActionsEnabled(enabled) {
  ['btn-summon', 'btn-cargo', 'btn-tack', 'btn-setmain', 'btn-heal', 'btn-release', 'btn-rename'].forEach((id) => { el(id).disabled = !enabled; });
}
function horseState(h) {
  if (Number(h.dead) === 1) return { key: 'dead', label: 'เสียชีวิต' };
  if (Number(h.writhe) === 1) return { key: 'injured', label: 'บาดเจ็บ' };
  if (Number(DATA.activeHorseId) === Number(h.id)) return { key: 'active', label: 'ถูกเรียกอยู่' };
  if (Number(h.selected) === 1) return { key: 'primary', label: 'ม้าหลัก · อยู่ในคอก' };
  return { key: 'stable', label: 'อยู่ในคอก' };
}
function setPrimaryAction(title, subtitle, icon) {
  const button = el('btn-summon');
  button.querySelector('i:first-child').className = `fa-solid ${icon}`;
  button.querySelector('strong').textContent = title;
  button.querySelector('small').textContent = subtitle;
}
function applyHorseActions(h) {
  const state = horseState(h);
  const permanentDead = state.key === 'dead' && DATA.stableMeta.permanentDeath === true;
  const anotherActive = DATA.activeHorseId != null && Number(DATA.activeHorseId) !== Number(h.id);
  const needsHeal = Number(h.health) < 100 || Number(h.stamina) < 100 || state.key === 'injured' || (state.key === 'dead' && !permanentDead);
  el('main-status-dot').textContent = state.label;
  el('main-status-dot').classList.toggle('danger', state.key === 'dead' || state.key === 'injured');
  setMainActionsEnabled(true);
  el('btn-cargo').disabled = state.key === 'dead' || state.key === 'injured';
  // แต่งอานได้เฉพาะม้าที่อยู่ในคอก — ถ้าถูกเรียกออกมา (active) ต้องเก็บเข้าคอกก่อน
  el('btn-tack').disabled = state.key === 'dead' || state.key === 'injured' || state.key === 'active';
  el('btn-setmain').disabled = Number(h.selected) === 1 || state.key === 'dead' || state.key === 'injured';
  el('btn-setmain').querySelector('span').textContent = Number(h.selected) === 1 ? 'ม้าหลักปัจจุบัน' : 'ตั้งเป็นม้าหลัก';
  el('btn-heal').disabled = !needsHeal || permanentDead;
  el('btn-release').disabled = state.key === 'dead' || state.key === 'injured' || state.key === 'active';
  if (state.key === 'active') {
    setPrimaryAction('เก็บม้าเข้าคอก', 'บันทึกสถานะและส่งม้ากลับคอก', 'fa-arrow-right-to-bracket');
    el('btn-summon').disabled = false;
  } else {
    setPrimaryAction('เรียกม้าตัวนี้', anotherActive ? 'ต้องเก็บม้าที่ถูกเรียกอยู่ก่อน' : 'เรียกม้าออกจากคอกมายังจุดปลอดภัย', 'fa-horse-head');
    el('btn-summon').disabled = anotherActive || state.key === 'dead' || state.key === 'injured';
  }
}
function renderOwnedCount() {
  el('tab-count-main').textContent = String(myHorses.length);
  el('owned-count').textContent = `${myHorses.length} ตัว`;
}
async function refreshOwnedData(preferredHorseId, shouldPreview = true, forceFresh = false) {
  if (ownedRefreshPromise) {
    if (!forceFresh) return ownedRefreshPromise;
    try { await ownedRefreshPromise; } catch (_) { /* start a fresh authoritative request below */ }
  }
  const request = (async () => {
    const previousHorseId = currentHorse() && Number(currentHorse().id);
    const result = await nui('refreshHorseData', {});
    if (!result || result.ok !== true || !Array.isArray(result.myHorsesData)) return false;
    DATA.stableMeta = result.stableMeta || DATA.stableMeta;
    DATA.activeHorseId = result.activeHorseId == null ? null : Number(result.activeHorseId);
    replaceOwnedHorses(result.myHorsesData, preferredHorseId);
    renderOwnedCount();
    if (mode === 'main') {
      const currentHorseId = currentHorse() && Number(currentHorse().id);
      if (shouldPreview || previousHorseId !== currentHorseId) await previewCurrent();
      else { renderOwnedList(); renderMainPreview(); }
    }
    return true;
  })();
  ownedRefreshPromise = request;
  try {
    return await request;
  } finally {
    if (ownedRefreshPromise === request) ownedRefreshPromise = null;
  }
}
async function previewCurrent() {
  hideManage();
  renderOwnedList();
  renderMainPreview();
  const h = currentHorse();
  if (!h) return false;
  const result = await nui('loadMyHorse', { HorseId: h.id, HorseComp: h.components || '{}', HorseModel: h.model, HorseGender: h.gender });
  return result && result.ok !== false;
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
  const term = el('shop-search').value.trim().toLocaleLowerCase('th');
  const breeds = (DATA.shopData || []).map((breed, bi) => ({ breed, bi })).filter(({ breed }) => !term || String(breed.breed || '').toLocaleLowerCase('th').includes(term));
  el('shop-step-back').hidden = true;
  el('shop-search').parentElement.hidden = false;
  el('shop-step-label').textContent = 'สายพันธุ์';
  el('shop-step-title').textContent = shopBreedIdx != null && DATA.shopData[shopBreedIdx] ? DATA.shopData[shopBreedIdx].breed : 'เลือกสายพันธุ์';
  el('shop-step-count').textContent = `${breeds.length} รายการ`;
  list.innerHTML = breeds.length ? breeds.map(({ breed, bi }) => {
    const active = bi === shopBreedIdx;
    const colors = Object.keys(breed.colors || {});
    return `<button class="horse-card breed-card${active ? ' active' : ''}" type="button" data-breed-index="${bi}">
      <span class="horse-thumb"><i class="fa-solid fa-horse-head"></i></span>
      <span><strong>${esc(breed.breed || '—')}</strong><small>${colors.length} สี</small></span>
      <span class="horse-state">เลือก</span>
    </button>${active ? shopInlineCarousel(bi, breed) : ''}`;
  }).join('') : '<div class="card-empty">ไม่พบสายพันธุ์ที่ค้นหา</div>';
  list.querySelectorAll('[data-breed-index]').forEach((button) => button.addEventListener('click', () => {
    shopBreedIdx = Number(button.dataset.breedIndex);
    shopStep = 'colors';
    const colors = Object.keys((DATA.shopData[shopBreedIdx] || {}).colors || {});
    if (colors.length) openShopSlot(`${shopBreedIdx}|${colors[0]}`, colors[0]);
    else { shopSelKey = null; renderShopList(); renderShopPreview(); }
  }));
  const prev = el('shop-color-prev'); const next = el('shop-color-next');
  if (prev) prev.addEventListener('click', () => moveShopColor(-1));
  if (next) next.addEventListener('click', () => moveShopColor(1));
}
function shopInlineCarousel(bi, breed) {
  const colors = Object.keys(breed.colors || {});
  const currentIndex = shopSelKey && shopSelKey.startsWith(`${bi}|`) ? Math.max(0, colors.indexOf(shopSelKey.split('|')[1])) : 0;
  const cfg = colors.length ? breed.colors[colors[currentIndex]] : null;
  const currentLabel = cfg ? `${cfg.color || 'ไม่มีสี'} [${currentIndex + 1}/${colors.length}]` : 'ไม่มีสี [0/0]';
  return `<div class="inline-carousel shop-inline-carousel">
    <button id="shop-color-prev" class="tack-arrow" type="button" aria-label="สีก่อนหน้า"><i class="fa-solid fa-chevron-left"></i></button>
    <div class="tack-current-card"><strong>${esc(currentLabel)}</strong></div>
    <button id="shop-color-next" class="tack-arrow" type="button" aria-label="สีถัดไป"><i class="fa-solid fa-chevron-right"></i></button>
  </div>`;
}
function moveShopColor(direction) {
  if (shopBreedIdx == null) return;
  const colors = Object.keys((DATA.shopData[shopBreedIdx] || {}).colors || {});
  if (!colors.length) return;
  const current = shopSelKey && shopSelKey.startsWith(`${shopBreedIdx}|`) ? colors.indexOf(shopSelKey.split('|')[1]) : 0;
  const index = (current + direction + colors.length) % colors.length;
  openShopSlot(`${shopBreedIdx}|${colors[index]}`, colors[index]);
}
function renderShopPreview() {
  const info = shopSelKey ? findShopColor(shopSelKey) : null;
  if (!info || !info.cfg) {
    el('preview-breed').textContent = '';
    el('preview-name').textContent = 'เลือกม้าจากรายการ';
    el('preview-subtitle').textContent = '';
    el('shop-price').textContent = '—';
    el('shop-slots').textContent = '—';
    el('shop-color').textContent = '—';
    el('shop-stats').innerHTML = '';
    el('buy-label').textContent = 'เลือกม้าจากรายการ';
    el('btn-buy').disabled = true;
    return;
  }
  const { breed, cfg } = info;
  el('preview-breed').textContent = (breed.breed || '').toUpperCase();
  el('preview-name').textContent = cfg.color || breed.breed;
  el('preview-subtitle').textContent = priceText(cfg.cashPrice, cfg.goldPrice);
  el('shop-price').textContent = priceText(cfg.cashPrice);
  el('shop-slots').textContent = cfg.invLimit != null ? `${cfg.invLimit} ช่อง` : '—';
  el('shop-color').textContent = cfg.color || '—';
  el('shop-stats').innerHTML = statGridMarkup(cfg.stats);
  el('buy-label').textContent = priceText(cfg.cashPrice);
  const meta = DATA.stableMeta || {};
  const price = Number(cfg.cashPrice || 0);
  const balance = Number(meta.money || 0);
  const full = Number(meta.aliveCount || 0) >= Number(meta.maxHorses || Infinity);
  const poor = balance < price;
  el('btn-buy').disabled = full || poor || actionBusy;
  el('buy-label').textContent = full ? `คอกเต็ม · ${meta.aliveCount}/${meta.maxHorses}` : poor ? 'เงินไม่เพียงพอ' : el('buy-label').textContent;
  el('btn-buy').title = full ? 'คอกม้าเต็ม' : poor ? 'เงินไม่เพียงพอ' : '';
}
function openShopSlot(key, model) {
  shopSelKey = key;
  nui('loadHorse', { horseModel: model });
  renderShopList();
  renderShopPreview();
}
function showPurchaseConfirm() {
  if (!shopSelKey) { notify('เลือกม้าก่อน', 'warning'); return; }
  const info = findShopColor(shopSelKey);
  if (!info || !info.cfg) return;
  const meta = DATA.stableMeta || {};
  const price = Number(info.cfg.cashPrice || 0);
  const balance = Number(meta.money || 0);
  el('pc-horse').textContent = `${info.breed.breed || ''} · ${info.cfg.color || ''}`;
  el('pc-price').textContent = priceText(info.cfg.cashPrice);
  el('pc-balance').textContent = `$${balance} → $${balance - price}`;
  el('pc-slots').textContent = `${meta.aliveCount || 0}/${meta.maxHorses || '—'} → ${Number(meta.aliveCount || 0) + 1}/${meta.maxHorses || '—'}`;
  el('purchase-confirm').classList.remove('hidden');
}
async function executeBuy() {
  if (!shopSelKey) return;
  const info = findShopColor(shopSelKey);
  if (!info || !info.cfg) return;
  if (actionBusy || el('btn-buy').disabled) return;
  actionBusy = true; el('btn-buy').disabled = true;
  const result = await nui('BuyHorse', { ModelH: info.model, IsCash: true, gender: shopGender, captured: 0, cashPrice: info.cfg.cashPrice, goldPrice: info.cfg.goldPrice });
  actionBusy = false;
  if (!result || result.ok === false) { notify('ซื้อไม่สำเร็จ กรุณาตรวจเงินและช่องคอก', 'error'); renderShopPreview(); }
}

/* ===================== TACK mode ===================== */
function availableTackCats() { return TACK_CATS.filter((c) => Array.isArray(DATA.compData[c]) && DATA.compData[c].length); }
function tackHashKey(hash) { return hash == null || hash === '' || Number(hash) === 0 ? '0' : String(hash); }
function tackOptionLabel(cat, hash) {
  if (tackHashKey(hash) === '0') return 'ไม่มีอุปกรณ์';
  const index = (DATA.compData[cat] || []).findIndex((option) => tackHashKey(option.hash) === tackHashKey(hash));
  return index >= 0 ? `แบบที่ ${index + 1}` : 'อุปกรณ์เดิม';
}
function tackDiffEntries() {
  return Object.keys(tackPending).filter((cat) => tackHashKey(tackPending[cat]) !== tackHashKey(tackInstalled[cat])).map((cat) => {
    const nextHash = tackPending[cat];
    const previousHash = tackInstalled[cat];
    const option = (DATA.compData[cat] || []).find((item) => tackHashKey(item.hash) === tackHashKey(nextHash));
    return {
      cat,
      categoryLabel: t(cat, cat),
      previousLabel: tackOptionLabel(cat, previousHash),
      nextLabel: tackOptionLabel(cat, nextHash),
      cashPrice: option ? Number(option.cashPrice || 0) : 0,
      goldPrice: option ? Number(option.goldPrice || 0) : 0,
    };
  });
}
function computeTackTotal() {
  let cash = 0, gold = 0;
  tackDiffEntries().forEach((entry) => {
    cash += entry.cashPrice;
    gold += entry.goldPrice;
  });
  return { cash, gold };
}
/* ===== TACK drill-down: หน้า cats (เลือกหมวด) และหน้า items (เลือกแบบ+สี) ===== */
// hash ที่เลือกอยู่ของหมวด (pending ถ้ามี ไม่งั้น installed)
function selectedTackHash(cat) {
  return Object.prototype.hasOwnProperty.call(tackPending, cat) ? tackPending[cat] : tackInstalled[cat];
}
// หากลุ่มสี (variations รุ่นเดียวกัน) ที่มี hash นี้อยู่ — จาก Config.TackColorGroups
function findColorGroup(cat, hash) {
  const groups = (DATA.tackColorGroups || {})[cat];
  if (!groups || !hash) return null;
  const key = tackHashKey(hash);
  for (const g of groups) { if (g.some((h) => tackHashKey(h) === key)) return g; }
  return null;
}
// จัดกลุ่มอุปกรณ์เป็น "รุ่น" (dedup ด้วยกลุ่มสี) — คืน [{ variations:[hash,...] }] เรียงตาม compData
function tackModels(cat) {
  const opts = DATA.compData[cat] || [];
  const seen = new Set();
  const models = [];
  for (const o of opts) {
    const key = tackHashKey(o.hash);
    if (seen.has(key)) continue;
    const group = findColorGroup(cat, o.hash);
    const variations = group
      ? group.filter((h) => opts.some((x) => tackHashKey(x.hash) === tackHashKey(h)))
      : [o.hash];
    variations.forEach((h) => seen.add(tackHashKey(h)));
    models.push({ variations });
  }
  return models;
}
function tackModelIndexOfHash(models, hash) {
  const key = tackHashKey(hash);
  return models.findIndex((m) => m.variations.some((h) => tackHashKey(h) === key));
}
// dispatcher: เรนเดอร์หน้าตาม tackView
function renderTack() {
  if (tackView === 'items' && tackCat) renderTackItems();
  else renderTackCats();
  updateTackSummary();
  updateTackTotal();
}
// หน้า 1: รายการหมวด (↑↓ เลื่อน, Enter/→ เข้า)
function renderTackCats() {
  el('tack-cat-title').textContent = 'เลือกหมวดอุปกรณ์';
  const list = el('tack-cat-list');
  const cats = availableTackCats();
  if (!cats.length) { list.innerHTML = '<div class="card-empty">ไม่มีอุปกรณ์ให้เลือก</div>'; return; }
  tackCatIndex = Math.max(0, Math.min(tackCatIndex, cats.length - 1));
  list.innerHTML = cats.map((cat, i) => {
    const count = (DATA.compData[cat] || []).length;
    const hl = i === tackCatIndex;
    return `<button class="tack-cat-card${hl ? ' hl' : ''}" type="button" data-cat="${cat}">
      <i class="fa-solid fa-layer-group tk-ico"></i>
      <span class="tk-label"><strong>${esc(t(cat, cat))}</strong><small>${count} แบบ</small></span>
      <i class="fa-solid fa-chevron-right tack-go"></i>
    </button>`;
  }).join('');
  list.querySelectorAll('[data-cat]').forEach((b) => b.addEventListener('click', () => enterTackCat(b.dataset.cat)));
}
function enterTackCat(cat) {
  tackCat = cat;
  tackView = 'items';
  const models = tackModels(cat);
  const mi = tackModelIndexOfHash(models, selectedTackHash(cat));
  tackModelIndex = mi; // -1 = ถอดออก/ไม่พบ
  renderTack();
}
function exitToTackCats() {
  tackView = 'cats';
  renderTack();
}
// หน้า 2: back + รายการแบบ (↑↓) + แถว Variation สี (← →)
function renderTackItems() {
  const cat = tackCat;
  el('tack-cat-title').textContent = t(cat, cat);
  const list = el('tack-cat-list');
  const models = tackModels(cat);
  const sel = selectedTackHash(cat);
  const removed = tackHashKey(sel) === '0';
  const equippedModel = tackModelIndexOfHash(models, sel);
  tackModelIndex = Math.max(-1, Math.min(tackModelIndex, models.length - 1));

  const header = `<div class="tack-items-head">
    <button class="tack-back" id="tack-back" type="button"><i class="fa-solid fa-chevron-left"></i> กลับ</button>
    <strong>${esc(t(cat, cat))}</strong>
  </div>`;
  const removeRow = `<button class="tack-item${tackModelIndex === -1 ? ' hl' : ''}${removed ? ' equipped' : ''}" type="button" data-mi="-1">
    <span class="tk-label"><strong>ถอดออก</strong></span>${removed ? '<i class="fa-solid fa-check tk-check"></i>' : ''}
  </button>`;
  const rows = models.map((m, i) => {
    const isEq = i === equippedModel;
    const hl = i === tackModelIndex;
    const colorNote = m.variations.length > 1 ? `${m.variations.length} สี` : '';
    return `<button class="tack-item${hl ? ' hl' : ''}${isEq ? ' equipped' : ''}" type="button" data-mi="${i}">
      <span class="tk-label"><strong>แบบที่ ${i + 1}</strong>${colorNote ? `<small>${colorNote}</small>` : ''}</span>${isEq ? '<i class="fa-solid fa-check tk-check"></i>' : ''}
    </button>`;
  }).join('');

  let variationHTML = '';
  const hlModel = tackModelIndex >= 0 ? models[tackModelIndex] : null;
  if (hlModel && hlModel.variations.length > 1) {
    const selKey = tackHashKey(sel);
    const sw = hlModel.variations.map((h, i) => {
      const active = tackHashKey(h) === selKey;
      return `<button class="tack-color-swatch${active ? ' active' : ''}" type="button" data-hash="${esc(String(h))}" title="สีที่ ${i + 1}">${i + 1}</button>`;
    }).join('');
    variationHTML = `<div class="tack-variation-row"><small>สี — Variation (← →)</small><div class="tack-color-swatches">${sw}</div></div>`;
  }

  list.innerHTML = header + `<div class="tack-item-scroll">${removeRow}${rows}</div>` + variationHTML;
  const back = el('tack-back'); if (back) back.addEventListener('click', exitToTackCats);
  list.querySelectorAll('[data-mi]').forEach((b) => b.addEventListener('click', () => selectTackModel(Number(b.dataset.mi))));
  list.querySelectorAll('.tack-color-swatch[data-hash]').forEach((b) => b.addEventListener('click', () => applyTackHash(b.dataset.hash)));
  const hlEl = list.querySelector('.tack-item.hl');
  if (hlEl) hlEl.scrollIntoView({ block: 'nearest' });
}
// ใส่อุปกรณ์ตาม hash (0/'' = ถอดออก) — ยิงไป client + อัปเดต pending + เรนเดอร์
function applyTackHash(hash) {
  if (!tackCat) return;
  const isRemove = !hash || tackHashKey(hash) === '0';
  nui(tackCat, { id: isRemove ? '-1' : '0', hash: isRemove ? '' : hash });
  const nextHash = isRemove ? 0 : hash;
  if (tackHashKey(nextHash) === tackHashKey(tackInstalled[tackCat])) delete tackPending[tackCat];
  else tackPending[tackCat] = nextHash;
  renderTack();
}
// เลือกแบบ (รุ่น) mi — คงสีเดิมถ้ารุ่นนั้นมีสีตรง ไม่งั้นใช้สีแรก. mi=-1 = ถอดออก
function selectTackModel(mi) {
  tackModelIndex = mi;
  if (mi < 0) { applyTackHash(''); return; }
  const models = tackModels(tackCat);
  const m = models[mi];
  if (!m) return;
  const curKey = tackHashKey(selectedTackHash(tackCat));
  const hash = m.variations.find((h) => tackHashKey(h) === curKey) || m.variations[0];
  applyTackHash(hash);
}
function moveTackCat(dir) {
  const cats = availableTackCats();
  if (!cats.length) return;
  tackCatIndex = (tackCatIndex + dir + cats.length) % cats.length;
  renderTack();
  const hlEl = el('tack-cat-list').querySelector('.tack-cat-card.hl');
  if (hlEl) hlEl.scrollIntoView({ block: 'nearest' });
}
function enterHighlightedCat() {
  const cats = availableTackCats();
  const cat = cats[tackCatIndex];
  if (cat) enterTackCat(cat);
}
function moveTackModel(dir) {
  if (!tackCat) return;
  const models = tackModels(tackCat);
  const total = models.length + 1; // +1 = ถอดออก
  let idx = tackModelIndex + 1;    // map -1..N-1 → 0..N
  idx = (idx + dir + total) % total;
  selectTackModel(idx - 1);
}
function moveTackVariation(dir) {
  if (!tackCat || tackModelIndex < 0) return;
  const models = tackModels(tackCat);
  const m = models[tackModelIndex];
  if (!m || m.variations.length < 2) return;
  const cur = m.variations.findIndex((h) => tackHashKey(h) === tackHashKey(selectedTackHash(tackCat)));
  const start = cur >= 0 ? cur : 0;
  applyTackHash(m.variations[(start + dir + m.variations.length) % m.variations.length]);
}
function updateTackSummary() {
  const diffs = tackDiffEntries();
  el('tack-diff-list').innerHTML = diffs.length ? diffs.map((entry) => `
    <div class="tack-diff-row">
      <strong>${esc(entry.categoryLabel)}</strong>
      <b>${entry.cashPrice ? priceText(entry.cashPrice) : 'ฟรี'}</b>
      <span>${esc(entry.previousLabel)} → ${esc(entry.nextLabel)}</span>
    </div>`).join('') : '<span class="tack-diff-empty">ยังไม่มีการเปลี่ยนแปลง</span>';
}
function updateTackTotal() {
  const hasDiff = tackDiffEntries().length > 0;
  const total = computeTackTotal();
  el('tack-total-price').textContent = priceText(total.cash);
  el('btn-tack-save').disabled = actionBusy || !hasDiff;
}

async function onTackSave() {
  const total = computeTackTotal();
  if (actionBusy) return;
  actionBusy = true; el('btn-tack-save').disabled = true;
  const result = await nui('CloseStable', { MenuAction: 'save', cashPrice: total.cash, goldPrice: total.gold, currencyType: 0 });
  actionBusy = false;
  if (result && result.ok) { root.classList.add('hidden'); return; }
  el('btn-tack-save').disabled = false;
  const reasons = {
    funds: 'เงินไม่พอสำหรับอุปกรณ์ที่เลือก',
    invalid_component: 'อุปกรณ์ไม่ถูกต้อง กรุณาลองใหม่',
    processing: 'กำลังประมวลผล รอสักครู่แล้วลองใหม่',
    unavailable: 'ม้าตัวนี้ไม่พร้อมทำรายการ',
    database: 'บันทึกไม่สำเร็จ (ฐานข้อมูล) กรุณาลองใหม่',
  };
  notify(reasons[result && result.reason] || 'บันทึกอุปกรณ์ไม่สำเร็จ', 'error');
}

/* ===================== mode switching ===================== */
function setMode(m) {
  mode = m;
  hideRelease();
  el('purchase-confirm').classList.add('hidden');
  root.dataset.mode = m;
  document.querySelectorAll('[data-mode-target]').forEach((b) => b.classList.toggle('active', b.dataset.modeTarget === m));

  if (m === 'main') {
    previewCurrent();
  } else if (m === 'shop') {
    const firstHorse = shopEntries()[0];
    shopSelKey = firstHorse ? `${firstHorse.bi}|${firstHorse.model}` : null;
    shopBreedIdx = firstHorse ? firstHorse.bi : null;
    shopStep = firstHorse ? 'colors' : 'breeds';
    if (firstHorse) nui('loadHorse', { horseModel: firstHorse.model });
    renderShopList();
    renderShopPreview();
  } else if (m === 'tack') {
    const horse = currentHorse();
    tackPending = {};
    try { tackInstalled = JSON.parse(horse && horse.components || '{}') || {}; } catch (_) { tackInstalled = {}; }
    tackView = 'cats';
    tackCatIndex = 0;
    tackCat = null;
    tackModelIndex = 0;
    renderTack();
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
function hideManage() { hideRelease(); }
async function doRelease() {
  const h = currentHorse();
  hideRelease();
  hideManage();
  if (!h) return;
  if (actionBusy) return;
  const nextSellable = myHorses.find((horse) => Number(horse.id) !== Number(h.id)
    && Number(horse.dead) !== 1 && Number(horse.writhe) !== 1
    && Number(DATA.activeHorseId) !== Number(horse.id));
  const nextRemaining = myHorses.find((horse) => Number(horse.id) !== Number(h.id));
  const nextHorseId = (nextSellable || nextRemaining || {}).id;
  actionBusy = true;
  el('rc-yes').disabled = true; el('rc-no').disabled = true;
  const result = await nui('sellHorse', { horseId: h.id, captured: h.captured });
  actionBusy = false;
  el('rc-yes').disabled = false; el('rc-no').disabled = false;
  if (!result || result.ok !== true) {
    const reason = result && result.reason;
    const messages = {
      cargo_not_empty: 'กรุณานำสิ่งของและอาวุธออกจากกระเป๋าม้าก่อนขาย',
      dead: 'ไม่สามารถขายม้าที่เสียชีวิตได้',
      injured: 'ต้องรักษาม้าที่บาดเจ็บก่อนขาย',
      active: 'ต้องเก็บม้าเข้าคอกก่อนขาย',
      stable_distance: 'คุณอยู่ไกลจากโรงม้าเกินไป',
      job: 'อาชีพของคุณไม่มีสิทธิ์ทำรายการที่โรงม้านี้',
      ownership: 'ไม่พบม้าตัวนี้ในคอกของคุณ กรุณารอข้อมูลอัปเดต',
      model_config: 'ม้าตัวนี้ไม่มีข้อมูลราคาในร้าน กรุณาแจ้งผู้ดูแลระบบ',
      processing: 'ระบบกำลังประมวลผลรายการก่อนหน้า กรุณารอสักครู่',
      delete_failed: 'เซิร์ฟเวอร์ไม่สามารถลบข้อมูลม้าได้ กรุณาลองใหม่',
      invalid_horse: 'ข้อมูลม้าที่เลือกไม่ถูกต้อง',
      callback_failed: 'เซิร์ฟเวอร์ไม่ตอบกลับ กรุณาลองใหม่',
    };
    notify(messages[reason] || 'ขายม้าไม่สำเร็จ กรุณาลองใหม่', 'error');
    if (reason === 'ownership' || reason === 'dead') await refreshOwnedData(h.id, true, true);
    return;
  }
  replaceOwnedHorses(myHorses.filter((horse) => Number(horse.id) !== Number(h.id)), nextHorseId);
  renderOwnedCount();
  renderOwnedList();
  renderMainPreview();
  await refreshOwnedData(nextHorseId == null ? null : nextHorseId, true, true);
  notify('ปล่อยม้าแล้ว', 'success');
}

/* ===================== open / close ===================== */
function openUI(p) {
  el('stable-state').classList.add('hidden');
  DATA.shopData = Array.isArray(p.shopData) ? p.shopData : [];
  DATA.compData = p.compData || {};
  DATA.translations = p.translations || {};
  DATA.currencyType = (typeof p.currencyType === 'number') ? p.currencyType : 0;
  DATA.location = p.location || '';
  if (typeof p.healPrice === 'number') DATA.healPrice = p.healPrice;
  if (p.healCurrencyLabel) DATA.healCurrencyLabel = p.healCurrencyLabel;
  DATA.stableMeta = p.stableMeta || {};
  DATA.activeHorseId = p.activeHorseId == null ? null : Number(p.activeHorseId);
  DATA.tackColorGroups = (p.tackColorGroups && typeof p.tackColorGroups === 'object') ? p.tackColorGroups : {};
  ownedStatusFilter = 'all';
  replaceOwnedHorses(p.myHorsesData, null);
  tackPending = {};
  tackInstalled = {};
  shopGender = 'male';
  el('stable-location').textContent = DATA.location || '';
  renderOwnedCount();
  el('tab-count-shop').textContent = String(shopEntries().length);
  setMode('main');
  root.classList.remove('hidden');
  startOwnedRefreshTimer();
}

function stopOwnedRefreshTimer() {
  clearInterval(ownedRefreshTimer);
  ownedRefreshTimer = null;
}
function startOwnedRefreshTimer() {
  stopOwnedRefreshTimer();
  ownedRefreshTimer = setInterval(() => {
    if (root.classList.contains('hidden') || mode !== 'main' || actionBusy) return;
    const selected = currentHorse();
    refreshOwnedData(selected && selected.id, false, false);
  }, 5000);
}
function showStableState(kind, detail) {
  root.classList.remove('hidden');
  const failed = kind === 'error';
  el('stable-state').classList.remove('hidden');
  el('stable-state-icon').className = failed ? 'fa-solid fa-triangle-exclamation' : 'fa-solid fa-spinner fa-spin';
  el('stable-state-title').textContent = failed ? 'โหลดข้อมูลไม่สำเร็จ' : 'กำลังโหลดข้อมูลคอกม้า';
  el('stable-state-detail').textContent = detail || (failed ? 'การเชื่อมต่อกับเซิร์ฟเวอร์ล้มเหลว' : 'กรุณารอสักครู่');
  el('btn-retry').classList.toggle('hidden', !failed);
}
function closeUI() {
  stopOwnedRefreshTimer();
  stopRotate();
  root.classList.add('hidden');
  hideTip();
  nui('CloseStable', { MenuAction: 'cancel' });
}

/* ===================== events ===================== */
el('btn-close').addEventListener('click', backOrClose);
el('btn-retry').addEventListener('click', async () => { showStableState('loading'); await nui('retryStable', {}); });
el('btn-state-close').addEventListener('click', closeUI);
document.querySelectorAll('[data-mode-target]').forEach((b) => b.addEventListener('click', () => setMode(b.dataset.modeTarget)));
document.querySelectorAll('[data-owned-status]').forEach((button) => button.addEventListener('click', () => {
  ownedStatusFilter = button.dataset.ownedStatus;
  const currentMatches = ownedStatusFilter === 'all' || ownedStatusKey(currentHorse()) === ownedStatusFilter;
  if (!currentMatches) {
    const firstMatch = myHorses.findIndex((horse) => ownedStatusKey(horse) === ownedStatusFilter);
    if (firstMatch >= 0) { selIdx = firstMatch; previewCurrent(); return; }
  }
  renderOwnedList();
}));
el('shop-step-back').addEventListener('click', () => { shopStep = 'breeds'; shopSelKey = null; renderShopList(); renderShopPreview(); });

el('btn-summon').addEventListener('click', async () => {
  const h = currentHorse(); if (!h || actionBusy) return;
  actionBusy = true; el('btn-summon').disabled = true;
  const returning = horseState(h).key === 'active';
  const result = await nui(returning ? 'returnHorse' : 'summonHorse', { horseId: h.id });
  actionBusy = false;
  if (result && result.ok) {
    if (!returning) notify('เรียกม้าแล้ว', 'success');
    if (returning) await refreshOwnedData(h.id, true, true);
  }
  else {
    notify(result && result.reason === 'unsafe_spawn' ? 'จุดเรียกม้าไม่ปลอดภัย กรุณาขยับแล้วลองใหม่' : 'ทำรายการไม่สำเร็จ สถานะม้าอาจเปลี่ยนไปแล้ว', 'error');
    await refreshOwnedData(h.id);
  }
});
el('btn-cargo').addEventListener('click', async () => {
  const h = currentHorse();
  if (!h || actionBusy) return;
  actionBusy = true;
  el('btn-cargo').disabled = true;
  const result = await nui('openCargo', { horseId: h.id });
  actionBusy = false;
  applyHorseActions(h);
  if (!result || result.ok !== true) {
    const messages = {
      saddlebags: 'ม้าตัวนี้ยังไม่ได้ติดตั้งกระเป๋าอาน',
      unavailable: 'ไม่สามารถใช้กระเป๋าของม้าที่เสียชีวิตได้',
      stable_distance: 'คุณอยู่ไกลจากโรงม้าเกินไป',
      ownership: 'คุณไม่ใช่เจ้าของม้าตัวนี้',
      processing: 'ระบบกำลังประมวลผล กรุณารอสักครู่',
      inventory: 'ไม่สามารถโหลดข้อมูลกระเป๋าม้าได้',
    };
    notify(messages[result && result.reason] || 'ไม่สามารถเปิดกระเป๋าม้าได้', 'error');
  }
});
el('btn-tack').addEventListener('click', () => setMode('tack'));
el('btn-rename').addEventListener('click', async () => {
  const h = currentHorse(); if (!h || actionBusy) return;
  actionBusy = true; await nui('RenameHorse', { horseId: h.id }); actionBusy = false;
});
el('btn-heal').addEventListener('click', async () => { const h = currentHorse(); if (!h || actionBusy) return; actionBusy = true; const result = await nui('healHorse', { horseId: h.id }); actionBusy = false; if (!result || !result.ok) notify('รักษาไม่สำเร็จ กรุณาตรวจเงินหรือสถานะม้า', 'error'); else await refreshOwnedData(h.id); });
el('btn-setmain').addEventListener('click', async () => {
  const h = currentHorse(); if (!h) return;
  if (actionBusy) return; actionBusy = true;
  const result = await nui('selectHorse', { horseId: h.id }); actionBusy = false;
  if (!result || !result.ok) { notify('ตั้งม้าหลักไม่สำเร็จ', 'error'); return; }
  await refreshOwnedData(h.id);
  notify('ตั้งเป็นม้าตัวหลักแล้ว', 'success');
});
el('btn-release').addEventListener('click', askRelease);
el('rc-yes').addEventListener('click', doRelease);
el('rc-no').addEventListener('click', hideRelease);

el('btn-buy').addEventListener('click', showPurchaseConfirm);
el('pc-yes').addEventListener('click', () => { el('purchase-confirm').classList.add('hidden'); executeBuy(); });
el('pc-no').addEventListener('click', () => el('purchase-confirm').classList.add('hidden'));
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

// คีย์ลัด: Q/E กดค้างหมุนม้า, ESC ย้อนกลับ/ปิด — ปิดขณะพิมพ์ในช่องค้นหา
let qDown = false, eDown = false;
document.addEventListener('keydown', (e) => {
  const tag = (document.activeElement && document.activeElement.tagName) || '';
  const typing = tag === 'INPUT' || tag === 'TEXTAREA';
  const k = e.key.toLowerCase();
  // Escape หรือ Backspace = ย้อนกลับ/ปิด (Backspace ขณะพิมพ์ = ลบตัวอักษรตามปกติ)
  if (k === 'escape' || k === 'backspace') {
    if (typing) { if (k === 'escape') document.activeElement.blur(); return; }
    e.preventDefault();
    if (mode === 'tack' && tackView === 'items') { exitToTackCats(); return; } // หน้าแบบ → กลับหน้าหมวด
    backOrClose(); return;
  }
  if (typing) return;
  // เมนูแต่งอาน (drill-down): หน้าหมวด ↑↓ เลือก, Enter/→ เข้า | หน้าแบบ ↑↓ เลือกแบบ, ← → เปลี่ยนสี, Backspace กลับ
  if (mode === 'tack') {
    if (tackView === 'cats') {
      if (k === 'arrowdown') { e.preventDefault(); moveTackCat(1); return; }
      if (k === 'arrowup') { e.preventDefault(); moveTackCat(-1); return; }
      if (k === 'enter' || k === 'arrowright') { e.preventDefault(); enterHighlightedCat(); return; }
    } else if (tackView === 'items') {
      if (k === 'arrowdown') { e.preventDefault(); moveTackModel(1); return; }
      if (k === 'arrowup') { e.preventDefault(); moveTackModel(-1); return; }
      if (k === 'arrowleft') { e.preventDefault(); moveTackVariation(-1); return; }
      if (k === 'arrowright') { e.preventDefault(); moveTackVariation(1); return; }
    }
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
el('owned-search').addEventListener('input', renderOwnedList);
el('shop-search').addEventListener('input', () => {
  renderShopList();
});

window.addEventListener('message', (ev) => {
  const d = ev.data || {};
  if (d.action === 'show') openUI(d);
  else if (d.action === 'pause') { stopOwnedRefreshTimer(); stopRotate(); root.classList.add('hidden'); hideTip(); }
  else if (d.action === 'resume') {
    root.classList.remove('hidden');
    startOwnedRefreshTimer();
    refreshOwnedData(currentHorse() && currentHorse().id, false);
  }
  else if (d.action === 'hide') { stopOwnedRefreshTimer(); stopRotate(); root.classList.add('hidden'); hideTip(); }
  else if (d.action === 'loading') showStableState('loading');
  else if (d.action === 'error') showStableState('error', d.message);
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
    location: 'Valentine Stable', currencyType: 0, healPrice: 500,
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
