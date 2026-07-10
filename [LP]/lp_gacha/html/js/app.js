/* =========================================================================
   lp_gacha — NUI front-end
   *** ไม่ตัดสินรางวัลเอง *** server เป็นคนสุ่ม/แจกทั้งหมด หน้านี้แค่:
     - รับรายการไอเทม + จำนวนตั๋ว จาก server ตอน 'open' มาแสดง
     - ส่ง "คำขอสปิน" {pool, qty} กลับไป server
     - รับ "รายชื่อผู้ชนะ" จาก server มาเล่นแอนิเมชันโชว์
   ========================================================================= */

// สี rarity (คงจาก prototype — ใช้ลงสีการ์ดอย่างเดียว)
const RARITIES = {
  basic:     { border: '#685540', borderOpacity: 1,   borderWidth: '1px',  glow: '#be893b', glowAlpha: 0.4, listDot: ['#be893b', 'rgba(190,137,59,0.3)'] },
  common:    { border: '#cecece', borderOpacity: 0.5, borderWidth: '.5px', glow: '#858585', glowAlpha: 0.4, listDot: ['#858585', 'rgba(126,126,126,0.3)'] },
  uncommon:  { border: '#60cd8e', borderOpacity: 0.5, borderWidth: '.5px', glow: '#23c941', glowAlpha: 0.4, listDot: ['#23c941', 'rgba(126,126,126,0.3)'] },
  rare:      { border: '#219af9', borderOpacity: 0.5, borderWidth: '.5px', glow: '#219af9', glowAlpha: 0.4, listDot: ['#219af9', 'rgba(33,154,249,0.3)'] },
  epic:      { border: '#f921ca', borderOpacity: 0.5, borderWidth: '.5px', glow: '#8221f9', glowAlpha: 0.4, listDot: ['#8221f9', 'rgba(220,33,249,0.3)'] },
  legendary: { border: '#FFD700', borderOpacity: 0.5, borderWidth: '.5px', glow: '#ffe066', glowAlpha: 0.4, listDot: ['#FFD700', 'rgba(255,215,0,0.3)'] },
};

const RARITY_ORDER = ['basic', 'common', 'uncommon', 'rare', 'epic', 'legendary'];
function rarestOf(items) {
  return items.reduce((best, it) =>
    RARITY_ORDER.indexOf(it.rarity) > RARITY_ORDER.indexOf(best.rarity) ? it : best
  );
}

const PLACEHOLDER_IMG = 'assets/item_placeholder.png';
// รูปไอเทม: server ส่ง image = item id, หน้าเว็บชี้ไป assets/<id>.png (ถ้าไม่มีรูป -> placeholder)
function imgSrc(image) {
  return image ? `assets/${image}.png` : PLACEHOLDER_IMG;
}

function cardBackground(rarity) {
  const r = RARITIES[rarity] || RARITIES.common;
  const glow = hexToRgba(r.glow, r.glowAlpha);
  const fade = hexToRgba(r.glow, 0);
  return `radial-gradient(100px 170px at 50% 100%, ${glow} 0%, ${fade} 100%), linear-gradient(#131313, #131313)`;
}

function hexToRgba(hex, alpha) {
  const n = parseInt(hex.slice(1), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  return `rgba(${r},${g},${b},${alpha})`;
}

const SPIN_MS = 5200;
const SKIP_MS = 400;
const CARD_PITCH = 174;
const CARD_CENTER = 78.5;
const VIEW_CENTER = 960;
const AUTO_SPIN_THRESHOLD = 10; // เกินนี้ = ข้ามรีลทีละใบ ไป spotlight ของหายากสุดแทน

/* ===================== state (มาจาก server) ===================== */
let POOL = null;            // id ของ pool ที่เปิดอยู่
let ITEMS = [];             // รายการไอเทมในตู้ (แสดงผลอย่างเดียว) [{key,name,image,rarity,amount,chancePct}]
let boxCount = 0;           // จำนวนตั๋วที่ถืออยู่ (เพดานการสปิน)
let QTY_MAX = 100;          // เพดานจาก config (ยังถูกจำกัดด้วย boxCount อีกชั้น)

/* ===================== elements ===================== */
const root = document.getElementById('root');
const strip = document.getElementById('belt-strip');
const spinMain = document.getElementById('spin-main');
const spinMainQty = document.getElementById('spin-main-qty');
const spinQtyToggle = document.getElementById('spin-qty-toggle');
const qtyModal = document.getElementById('qty-modal');
const qtyModalMin = document.getElementById('qty-modal-min');
const qtyModalMax = document.getElementById('qty-modal-max');
const qtyModalInput = document.getElementById('qty-modal-input');
const qtyModalHint = document.getElementById('qty-modal-hint');
const qtyModalConfirm = document.getElementById('qty-modal-confirm');
const qtyModalCancel = document.getElementById('qty-modal-cancel');
const autoSkipCheckbox = document.getElementById('auto-skip-checkbox');
const chanceBtn = document.getElementById('chance-btn');
const itemsList = document.getElementById('items-list');
const result = document.getElementById('result');
const resultGrid = document.getElementById('result-grid');
const currencyValueEl = document.getElementById('currency-value');
const insufficientMsg = document.getElementById('insufficient-msg');
const currencyLabelEl = document.getElementById('currency-label');

let spinning = false;
let activeSpin = null;
let autoSkip = false;

/* ===================== box count / limits ===================== */
function updateBoxCount() {
  currencyValueEl.textContent = boxCount + ' ใบ';
}
function maxQty() {
  return Math.max(1, Math.min(QTY_MAX, boxCount || 0));
}

function flashInsufficient(msg) {
  insufficientMsg.textContent = msg || 'ตั๋วไม่พอ';
  currencyValueEl.classList.add('shake-error');
  setTimeout(() => currencyValueEl.classList.remove('shake-error'), 400);
  insufficientMsg.classList.remove('hidden');
  insufficientMsg.classList.remove('show');
  void insufficientMsg.offsetWidth;
  insufficientMsg.classList.add('show');
  clearTimeout(flashInsufficient._t);
  flashInsufficient._t = setTimeout(() => insufficientMsg.classList.add('hidden'), 1500);
}

/* ===================== helpers ===================== */
// การ์ดใส้ไส้ระหว่างหมุน = สุ่มจาก ITEMS แบบ uniform เพื่อความสวยงามเท่านั้น (ไม่ใช่ผลจริง)
function randomFiller() {
  if (!ITEMS.length) return { name: '', image: null, rarity: 'common', amount: 1 };
  return ITEMS[Math.floor(Math.random() * ITEMS.length)];
}

function cardHTML(item, cls, opts = {}) {
  const r = RARITIES[item.rarity] || RARITIES.common;
  const borderColor = hexToRgba(r.border, r.borderOpacity);
  const glowColor = hexToRgba(r.glow, 0.85);
  const winnerCls = opts.winner ? ' is-winner' : '';
  const stackCls = opts.count > 1 ? ' is-stacked' : '';
  // badge = จำนวนที่ได้ (amount) x จำนวนครั้งที่ออกไอเทมนี้ในชุด
  const qty = (item.amount || 1) * (opts.count || 1);
  const style = `border-color:${borderColor};border-width:${r.borderWidth};background-image:${cardBackground(item.rarity)};--glow-color:${glowColor}`;
  return `<div class="${cls}${winnerCls}${stackCls}" style="${style}">
      <div class="price">${qty}</div>
      <div class="img"><img src="${imgSrc(item.image)}" alt="${item.name}" onerror="this.onerror=null;this.src='${PLACEHOLDER_IMG}'"></div>
      <div class="label">${item.name}</div>
    </div>`;
}

/* ===================== drop-rate list ===================== */
function renderItemsList() {
  const body = document.getElementById('items-list-body');
  body.innerHTML = ITEMS.map(it => {
    const r = RARITIES[it.rarity] || RARITIES.common;
    const pct = typeof it.chancePct === 'number' ? it.chancePct : 0;
    const pctLabel = pct >= 10 ? Math.round(pct) : pct.toFixed(1);
    return `<div class="items-list-row">
        <span class="diamond" style="background:linear-gradient(180deg,${r.listDot[0]},${r.listDot[1]})"></span>
        <span class="name">${it.name}</span>
        <span class="chance">${pctLabel}%</span>
      </div>`;
  }).join('');
}

/* ===================== belt ===================== */
function fillIdleBelt() {
  const cards = [];
  for (let i = 0; i < 14; i++) cards.push(cardHTML(randomFiller(), 'belt-card'));
  strip.style.transition = 'none';
  strip.style.transform = 'translateX(0)';
  strip.innerHTML = cards.join('');
}

// หมุนรีลไปหยุดที่ winner (winner กำหนดโดย server ส่งเข้ามา ไม่สุ่มเองแล้ว)
function runSpin(winner, onLand) {
  const WIN_INDEX = 48;
  const cards = [];
  for (let i = 0; i < 60; i++) {
    cards.push(i === WIN_INDEX ? cardHTML(winner, 'belt-card') : cardHTML(randomFiller(), 'belt-card'));
  }
  strip.style.transition = 'none';
  strip.style.transform = 'translateX(0)';
  strip.innerHTML = cards.join('');

  const jitter = (Math.random() * 100) - 50;
  const winnerCenter = WIN_INDEX * CARD_PITCH + CARD_CENTER;
  const targetX = VIEW_CENTER - winnerCenter + jitter;
  const targetTransform = `translateX(${targetX}px)`;

  let litIndex = -1;
  let rafId = null;
  function currentTranslateX() {
    const m = getComputedStyle(strip).transform;
    if (m === 'none') return 0;
    const match = m.match(/matrix\(([^)]+)\)/);
    return match ? parseFloat(match[1].split(',')[4]) : 0;
  }
  function trackCenterCard() {
    const tx = currentTranslateX();
    const idx = Math.round((VIEW_CENTER - CARD_CENTER - tx) / CARD_PITCH);
    if (idx !== litIndex) {
      if (litIndex >= 0 && strip.children[litIndex]) strip.children[litIndex].classList.remove('is-winner');
      if (strip.children[idx]) strip.children[idx].classList.add('is-winner');
      litIndex = idx;
    }
    rafId = requestAnimationFrame(trackCenterCard);
  }
  rafId = requestAnimationFrame(trackCenterCard);

  let done = false;
  const finish = () => {
    if (done) return;
    done = true;
    cancelAnimationFrame(rafId);
    clearTimeout(activeSpin.timeoutId);
    activeSpin = null;
    onLand(winner);
  };

  const startTransition = (durationMs, easing) => {
    strip.style.transition = `transform ${durationMs}ms ${easing}`;
    strip.style.transform = targetTransform;
    strip.addEventListener('transitionend', finish, { once: true });
  };

  void strip.offsetWidth;
  startTransition(SPIN_MS, 'cubic-bezier(0.12, 0.8, 0.15, 1)');

  activeSpin = {
    winner,
    timeoutId: setTimeout(finish, SPIN_MS + 400),
    skip() {
      clearTimeout(this.timeoutId);
      const currentTransform = getComputedStyle(strip).transform;
      strip.style.transition = 'none';
      strip.style.transform = currentTransform;
      void strip.offsetWidth;
      startTransition(SKIP_MS, 'ease-out');
      this.timeoutId = setTimeout(finish, SKIP_MS + 200);
    },
  };
}

/* ===================== result ===================== */
function summarizeItems(items) {
  const order = [];
  const counts = new Map();
  for (const it of items) {
    if (!counts.has(it.name)) { counts.set(it.name, { item: it, count: 0 }); order.push(it.name); }
    counts.get(it.name).count++;
  }
  return order
    .map((name) => counts.get(name))
    .sort((a, b) => RARITY_ORDER.indexOf(b.item.rarity) - RARITY_ORDER.indexOf(a.item.rarity));
}

function showResult(items) {
  resultGrid.classList.remove('spotlight');
  const grouped = summarizeItems(items);
  resultGrid.classList.toggle('single', grouped.length === 1);
  resultGrid.innerHTML = grouped
    .map((entry) => cardHTML(entry.item, 'result-card', { count: entry.count }))
    .join('');
  result.classList.remove('hidden');
}

function showSpotlight(item, onDone) {
  resultGrid.classList.add('spotlight');
  resultGrid.innerHTML = cardHTML(item, 'result-card spotlight-card', { winner: true });
  result.classList.remove('hidden');
  setTimeout(onDone, 900);
}

/* ===================== flow ===================== */
function setQtyBarDisabled(disabled) {
  spinMain.disabled = disabled;
  spinQtyToggle.disabled = disabled;
  if (disabled) {
    closeQtyModal();
    spinMainQty.textContent = 'กำลังหมุน...';
  } else {
    setPendingQty(pendingQty);
  }
}

// เล่นรีลทีละใบตามรายชื่อผู้ชนะที่ server ส่งมา (ไม่สุ่มเอง)
function runBatchAnimated(winners, idx) {
  runSpin(winners[idx], () => {
    if (idx < winners.length - 1) {
      runBatchAnimated(winners, idx + 1);
    } else {
      spinning = false;
      setQtyBarDisabled(false);
      showResult(winners);
    }
  });
  if (autoSkip && activeSpin) activeSpin.skip();
}

// ชุดใหญ่: ข้ามรีลทีละใบ ไป spotlight ของหายากสุดก่อน แล้วเปิดกริดเต็ม
function runBulkSpin(winners) {
  const best = rarestOf(winners);
  showSpotlight(best, () => {
    spinning = false;
    setQtyBarDisabled(false);
    showResult(winners);
  });
}

// รับผลจาก server มาเล่นแอนิเมชัน
function handleResult(winners, remaining) {
  if (typeof remaining === 'number') { boxCount = remaining; updateBoxCount(); }
  if (!Array.isArray(winners) || winners.length === 0) {
    spinning = false;
    setQtyBarDisabled(false);
    return;
  }
  // server ส่ง field ชื่อว่า label — normalize ให้มี name เพื่อให้ cardHTML/summarizeItems ใช้ร่วมกับ ITEMS ได้
  winners = winners.map(w => ({ ...w, name: w.name || w.label }));
  if (winners.length > AUTO_SPIN_THRESHOLD) {
    runBulkSpin(winners);
  } else {
    runBatchAnimated(winners, 0);
  }
}

// ส่งคำขอสปินไป server (ไม่ตัดสิน/ไม่หักอะไรเองที่ client)
function startSpin(count) {
  if (spinning) return;
  if (!POOL) return;
  if ((boxCount || 0) < count) {
    flashInsufficient('ตั๋วไม่พอ');
    return;
  }
  spinning = true;
  setQtyBarDisabled(true);
  nui('spin', { pool: POOL, qty: count });
}

/* ===================== spin quantity ===================== */
let pendingQty = 1;

function setPendingQty(n) {
  const clamped = Math.max(1, Math.min(n, maxQty()));
  pendingQty = clamped;
  spinMainQty.textContent = `เริ่มลุ้นไอเทม (${clamped})`;
}

function openQtyModal() {
  qtyModal.classList.remove('hidden');
  qtyModalInput.max = maxQty();
  qtyModalInput.value = pendingQty;
  qtyModalInput.classList.remove('invalid');
  qtyModalHint.classList.add('hidden');
  qtyModalInput.focus();
  qtyModalInput.select();
}
function closeQtyModal() {
  qtyModal.classList.add('hidden');
}

qtyModalMin.addEventListener('click', () => { qtyModalInput.value = 1; });
qtyModalMax.addEventListener('click', () => { qtyModalInput.value = maxQty(); });

function submitQtyModal() {
  const n = Number(qtyModalInput.value);
  const hi = maxQty();
  if (!Number.isInteger(n) || n < 1 || n > hi) {
    qtyModalHint.textContent = `1-${hi} เท่านั้น`;
    qtyModalInput.classList.add('invalid');
    qtyModalHint.classList.remove('hidden');
    qtyModalInput.focus();
    qtyModalInput.select();
    return;
  }
  setPendingQty(n);
  closeQtyModal();
}

/* ===================== events ===================== */
spinMain.addEventListener('click', () => startSpin(pendingQty));
spinQtyToggle.addEventListener('click', openQtyModal);

qtyModalInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') submitQtyModal();
  if (e.key === 'ArrowUp' || e.key === 'ArrowDown') e.preventDefault();
});
qtyModalInput.addEventListener('wheel', (e) => e.preventDefault(), { passive: false });
qtyModalConfirm.addEventListener('click', submitQtyModal);
qtyModalCancel.addEventListener('click', closeQtyModal);
qtyModal.addEventListener('click', (e) => { if (e.target === qtyModal || e.target.id === 'qty-modal-bg') closeQtyModal(); });

autoSkipCheckbox.addEventListener('change', () => { autoSkip = autoSkipCheckbox.checked; });

let hideItemsTimeout = null;
function openChance() {
  clearTimeout(hideItemsTimeout);
  itemsList.classList.remove('hidden');
  chanceBtn.classList.add('open');
  chanceBtn.setAttribute('aria-expanded', 'true');
}
function closeChance() {
  hideItemsTimeout = setTimeout(() => {
    itemsList.classList.add('hidden');
    chanceBtn.classList.remove('open');
    chanceBtn.setAttribute('aria-expanded', 'false');
  }, 100);
}
chanceBtn.addEventListener('mouseenter', openChance);
chanceBtn.addEventListener('mouseleave', closeChance);
itemsList.addEventListener('mouseenter', openChance);
itemsList.addEventListener('mouseleave', closeChance);

function closeResult() {
  result.classList.add('hidden');
  fillIdleBelt();
}
document.getElementById('result-close').addEventListener('click', closeResult);
result.addEventListener('click', (e) => { if (e.target === result) closeResult(); });

document.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if (!result.classList.contains('hidden')) { closeResult(); return; }
  if (!qtyModal.classList.contains('hidden')) { closeQtyModal(); return; }
  if (!itemsList.classList.contains('hidden')) {
    itemsList.classList.add('hidden');
    chanceBtn.classList.remove('open');
    chanceBtn.setAttribute('aria-expanded', 'false');
    return;
  }
  closeUI(); // ไม่มี overlay เปิดอยู่ -> ปิด NUI
});

/* ===================== NUI bridge ===================== */
function nui(name, payload) {
  const resName = (window.GetParentResourceName && GetParentResourceName()) || 'lp_gacha';
  fetch(`https://${resName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload || {}),
  }).catch(() => {});
}

function openUI(data) {
  POOL = data.pool;
  ITEMS = Array.isArray(data.items) ? data.items : [];
  boxCount = data.boxCount || 0;
  QTY_MAX = data.qtyMax || 100;
  if (data.label && currencyLabelEl) {
    // เก็บ label เดิม "จำนวนที่มี" ไว้ แต่โชว์ชื่อ pool บนหัวเรื่องถ้ามี element
    const titleText = document.getElementById('title-text');
    if (titleText) titleText.textContent = data.label;
  }
  renderItemsList();
  fillIdleBelt();
  updateBoxCount();
  setPendingQty(1);
  spinning = false;
  setQtyBarDisabled(false);
  result.classList.add('hidden');
  root.classList.remove('hidden');
}

function closeUI() {
  root.classList.add('hidden');
  nui('close', {});
}

window.addEventListener('message', (ev) => {
  const data = ev.data || {};
  switch (data.action) {
    case 'open':
      openUI(data.data || {});
      break;
    case 'result':
      handleResult(data.winners, data.remaining);
      break;
    case 'rejected':
      // server ปฏิเสธคำขอ (cooldown / ตั๋วไม่พอ / หักไม่สำเร็จ) — คืนสถานะปุ่ม
      spinning = false;
      setQtyBarDisabled(false);
      flashInsufficient(data.reason === 'cooldown' ? 'รอสักครู่' : 'ตั๋วไม่พอ');
      break;
    case 'close':
      root.classList.add('hidden');
      break;
  }
});

/* DEV ONLY — โชว์ mock เมื่อเปิดตรงในเบราว์เซอร์ (ไม่ทำงานใน CEF ที่ใช้ nui://) */
if (window.location.protocol !== 'nui:' && window.location.protocol !== 'https:') {
  openUI({
    pool: 'promo', label: 'กาชาโปรโมทเซิร์ฟ', boxCount: 10, qtyMax: 100,
    items: [
      { key: 'food_bread', name: 'ขนมปัง', image: 'food_bread', rarity: 'basic', amount: 5, chancePct: 17.6 },
      { key: 'mat_diamond', name: 'เพชร', image: 'mat_diamond', rarity: 'rare', amount: 2, chancePct: 8.6 },
      { key: 'a_c_horse_suffolkpunch_sorrel', name: 'ม้า Suffolk Punch', image: 'a_c_horse_suffolkpunch_sorrel', rarity: 'legendary', amount: 1, chancePct: 20 },
    ],
  });
}
